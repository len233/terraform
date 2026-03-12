"""
Flask Backend Application with Azure Blob Storage and PostgreSQL
CRUD API pour gérer des fichiers et des données
"""
import os
import uuid
from datetime import datetime
from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
from azure.storage.blob import BlobServiceClient, ContentSettings
import psycopg2
from psycopg2.extras import RealDictCursor
from werkzeug.utils import secure_filename
import logging

# Configuration
app = Flask(__name__)
CORS(app)

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration Azure Storage
AZURE_STORAGE_ACCOUNT = os.getenv('AZURE_STORAGE_ACCOUNT')
AZURE_STORAGE_KEY = os.getenv('AZURE_STORAGE_KEY')

# Configuration Database
DB_HOST = os.getenv('DB_HOST')
DB_NAME = os.getenv('DB_NAME')
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')

# Azure Blob Service Client
blob_service_client = None
if AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY:
    connection_string = f"DefaultEndpointsProtocol=https;AccountName={AZURE_STORAGE_ACCOUNT};AccountKey={AZURE_STORAGE_KEY};EndpointSuffix=core.windows.net"
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)

# Database connection
def get_db_connection():
    """Établit une connexion à la base de données PostgreSQL"""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            sslmode='require'
        )
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        return None

# Initialize database tables
def init_db():
    """Initialise les tables de la base de données"""
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            
            # Table pour les fichiers
            cur.execute("""
                CREATE TABLE IF NOT EXISTS files (
                    id SERIAL PRIMARY KEY,
                    filename VARCHAR(255) NOT NULL,
                    blob_name VARCHAR(255) NOT NULL,
                    container_name VARCHAR(100) NOT NULL,
                    file_type VARCHAR(50),
                    file_size INTEGER,
                    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    description TEXT
                )
            """)
            
            # Table pour les utilisateurs (exemple)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    username VARCHAR(100) UNIQUE NOT NULL,
                    email VARCHAR(255) UNIQUE NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            conn.commit()
            cur.close()
            logger.info("Database initialized successfully")
        except Exception as e:
            logger.error(f"Database initialization error: {e}")
        finally:
            conn.close()

# Routes principales

@app.route('/')
def home():
    """Page d'accueil de l'API"""
    return jsonify({
        'message': 'Terraform Cloud Project - Flask API',
        'version': '1.0.0',
        'status': 'running',
        'endpoints': {
            'health': '/api/health',
            'files': '/api/files',
            'users': '/api/users',
            'upload': '/api/upload',
            'storage': '/api/storage'
        }
    })

@app.route('/api/health')
def health():
    """Vérification de santé du service"""
    db_status = 'connected' if get_db_connection() else 'disconnected'
    storage_status = 'connected' if blob_service_client else 'disconnected'
    
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'database': db_status,
        'storage': storage_status
    })

# ============ CRUD pour les fichiers ============

@app.route('/api/files', methods=['GET'])
def get_files():
    """Récupère la liste de tous les fichiers"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM files ORDER BY uploaded_at DESC")
        files = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({'files': files, 'count': len(files)})
    except Exception as e:
        logger.error(f"Error fetching files: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/files/<int:file_id>', methods=['GET'])
def get_file(file_id):
    """Récupère un fichier spécifique par son ID"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM files WHERE id = %s", (file_id,))
        file = cur.fetchone()
        cur.close()
        conn.close()
        
        if file:
            return jsonify(file)
        return jsonify({'error': 'File not found'}), 404
    except Exception as e:
        logger.error(f"Error fetching file: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/files/<int:file_id>', methods=['DELETE'])
def delete_file(file_id):
    """Supprime un fichier de la base de données et du stockage"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM files WHERE id = %s", (file_id,))
        file = cur.fetchone()
        
        if not file:
            return jsonify({'error': 'File not found'}), 404
        
        # Supprimer du blob storage
        if blob_service_client:
            try:
                blob_client = blob_service_client.get_blob_client(
                    container=file['container_name'],
                    blob=file['blob_name']
                )
                blob_client.delete_blob()
            except Exception as e:
                logger.warning(f"Error deleting blob: {e}")
        
        # Supprimer de la base de données
        cur.execute("DELETE FROM files WHERE id = %s", (file_id,))
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'File deleted successfully', 'file_id': file_id})
    except Exception as e:
        logger.error(f"Error deleting file: {e}")
        return jsonify({'error': str(e)}), 500

# ============ Upload de fichiers ============

@app.route('/api/upload', methods=['POST'])
def upload_file():
    """Upload un fichier vers Azure Blob Storage"""
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    container_name = request.form.get('container', 'static')
    description = request.form.get('description', '')
    
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    if not blob_service_client:
        return jsonify({'error': 'Storage not configured'}), 500
    
    try:
        # Sécuriser le nom de fichier
        filename = secure_filename(file.filename)
        blob_name = f"{uuid.uuid4()}_{filename}"
        
        # Upload vers Azure Blob Storage
        blob_client = blob_service_client.get_blob_client(
            container=container_name,
            blob=blob_name
        )
        
        file_content = file.read()
        content_type = file.content_type or 'application/octet-stream'
        
        blob_client.upload_blob(
            file_content,
            overwrite=True,
            content_settings=ContentSettings(content_type=content_type)
        )
        
        # Enregistrer dans la base de données
        conn = get_db_connection()
        if conn:
            cur = conn.cursor()
            cur.execute(
                """
                INSERT INTO files (filename, blob_name, container_name, file_type, file_size, description)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (filename, blob_name, container_name, content_type, len(file_content), description)
            )
            file_id = cur.fetchone()[0]
            conn.commit()
            cur.close()
            conn.close()
        else:
            file_id = None
        
        return jsonify({
            'message': 'File uploaded successfully',
            'file_id': file_id,
            'filename': filename,
            'blob_name': blob_name,
            'container': container_name,
            'size': len(file_content)
        }), 201
        
    except Exception as e:
        logger.error(f"Error uploading file: {e}")
        return jsonify({'error': str(e)}), 500

# ============ CRUD pour les utilisateurs ============

@app.route('/api/users', methods=['GET'])
def get_users():
    """Récupère la liste de tous les utilisateurs"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT id, username, email, created_at FROM users ORDER BY created_at DESC")
        users = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({'users': users, 'count': len(users)})
    except Exception as e:
        logger.error(f"Error fetching users: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/users', methods=['POST'])
def create_user():
    """Crée un nouvel utilisateur"""
    data = request.get_json()
    
    if not data or 'username' not in data or 'email' not in data:
        return jsonify({'error': 'Username and email are required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            "INSERT INTO users (username, email) VALUES (%s, %s) RETURNING id, username, email, created_at",
            (data['username'], data['email'])
        )
        user = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'message': 'User created successfully', 'user': user}), 201
    except psycopg2.IntegrityError:
        return jsonify({'error': 'Username or email already exists'}), 409
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Récupère un utilisateur spécifique"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT id, username, email, created_at FROM users WHERE id = %s", (user_id,))
        user = cur.fetchone()
        cur.close()
        conn.close()
        
        if user:
            return jsonify(user)
        return jsonify({'error': 'User not found'}), 404
    except Exception as e:
        logger.error(f"Error fetching user: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    """Met à jour un utilisateur"""
    data = request.get_json()
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        updates = []
        values = []
        
        if 'username' in data:
            updates.append("username = %s")
            values.append(data['username'])
        if 'email' in data:
            updates.append("email = %s")
            values.append(data['email'])
        
        if not updates:
            return jsonify({'error': 'No fields to update'}), 400
        
        values.append(user_id)
        query = f"UPDATE users SET {', '.join(updates)} WHERE id = %s RETURNING id, username, email, created_at"
        
        cur.execute(query, values)
        user = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        if user:
            return jsonify({'message': 'User updated successfully', 'user': user})
        return jsonify({'error': 'User not found'}), 404
        
    except psycopg2.IntegrityError:
        return jsonify({'error': 'Username or email already exists'}), 409
    except Exception as e:
        logger.error(f"Error updating user: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Supprime un utilisateur"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM users WHERE id = %s RETURNING id", (user_id,))
        deleted = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        if deleted:
            return jsonify({'message': 'User deleted successfully', 'user_id': user_id})
        return jsonify({'error': 'User not found'}), 404
    except Exception as e:
        logger.error(f"Error deleting user: {e}")
        return jsonify({'error': str(e)}), 500

# ============ Informations sur le stockage ============

@app.route('/api/storage/info', methods=['GET'])
def storage_info():
    """Informations sur le stockage Azure"""
    if not blob_service_client:
        return jsonify({'error': 'Storage not configured'}), 500
    
    try:
        containers = []
        for container in blob_service_client.list_containers():
            blob_count = sum(1 for _ in blob_service_client.get_container_client(container.name).list_blobs())
            containers.append({
                'name': container.name,
                'blob_count': blob_count
            })
        
        return jsonify({
            'storage_account': AZURE_STORAGE_ACCOUNT,
            'containers': containers
        })
    except Exception as e:
        logger.error(f"Error getting storage info: {e}")
        return jsonify({'error': str(e)}), 500

# Initialize database on startup
with app.app_context():
    init_db()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
