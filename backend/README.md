# 🚀 Terraform Cloud Project - Déploiement Automatisé d'Infrastructure

## 📋 Description du Projet

Ce projet démontre le **déploiement automatisé d'une infrastructure cloud complète** sur Azure en utilisant Terraform. Il comprend :

- ✅ **Machine Virtuelle** (VM) Ubuntu avec IP publique
- ✅ **Azure Blob Storage** pour les fichiers statiques (images, logs)
- ✅ **Base de données PostgreSQL** managée
- ✅ **Application Flask** avec API REST complète (CRUD)
- ✅ **Automatisation complète** du déploiement

## 🎯 Objectifs du Projet

Automatiser le déploiement d'une application web Flask sur une infrastructure cloud avec :
- Création automatique de VM
- Configuration du stockage cloud (Azure Blob Storage)
- Déploiement d'une base de données PostgreSQL
- API REST avec opérations CRUD
- Connexion entre le backend, le stockage et la base de données

## 📁 Structure du Projet

```
terraform-cloud-project/
│
├── terraform/                  # Configuration Terraform
│   ├── provider.tf            # Provider Azure
│   ├── main.tf                # Infrastructure complète
│   ├── variables.tf           # Variables paramétrables
│   ├── outputs.tf             # Outputs (IPs, URLs, connexions)
│   ├── terraform.tfvars       # Valeurs des variables
│   ├── cloud-init.yaml        # Configuration automatique VM
│   └── inventory.tpl          # Template Ansible
│
├── backend/                    # Application Backend Flask
│   ├── app.py                 # API REST complète avec CRUD
│   └── requirements.txt       # Dépendances Python
│
├── ansible/                    # Ansible playbooks (optionnel)
│   ├── playbook.yml           # Configuration automatique
│   ├── flask-app.service.j2   # Service systemd
│   └── nginx-flask.conf.j2    # Configuration Nginx
│
├── scripts/                    # Scripts utilitaires
│   ├── install.sh             # Installation locale
│   ├── deploy.sh              # Déploiement sur VM
│   └── test-api.sh            # Tests API
│
└── README.md                   # Ce fichier
```

## ✅ Prérequis

### Logiciels requis
- **Terraform** >= 1.0 ([Installation](https://www.terraform.io/downloads))
- **Azure CLI** ([Installation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Python** >= 3.8
- **SSH Key** (générer avec `ssh-keygen -t rsa -b 4096`)
- **Git**
- **jq** (pour les tests API - optionnel)

### Compte Azure
- Un abonnement Azure actif
- Permissions pour créer des ressources (VM, Storage, Database)

## 🔧 Installation et Configuration

### Étape 1 : Préparer l'Environnement

#### 1.1. Cloner le projet
```bash
git clone <votre-repo>
cd terraform-cloud-project
```

#### 1.2. Configurer Azure CLI
```bash
# Se connecter à Azure
az login

# Vérifier l'abonnement actif
az account show

# (Optionnel) Changer d'abonnement
az account set --subscription "VOTRE_SUBSCRIPTION_ID"
```

#### 1.3. Générer une clé SSH (si nécessaire)
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### Étape 2 : Configurer Terraform

#### 2.1. Modifier les variables
Éditez `terraform/terraform.tfvars` :

```hcl
resource_group_name  = "rg-terraform-cloud"
location             = "East US"
environment          = "dev"
prefix               = "tfcloud"
storage_account_name = "tfcloudstorage2026unique"  # DOIT être unique globalement
admin_username       = "azureuser"
ssh_public_key_path  = "~/.ssh/id_rsa.pub"
vm_size              = "Standard_B2s"
db_admin_username    = "dbadmin"
db_admin_password    = "VotreMotDePasseSecurise123!"  # Changez-le!
db_name              = "appdb"
```

⚠️ **Important** :
- Le `storage_account_name` doit être **unique globalement** (3-24 caractères, minuscules et chiffres uniquement)
- Changez le `db_admin_password` par un mot de passe sécurisé

#### 2.2. Initialiser Terraform
```bash
cd terraform
terraform init
```

### Étape 3 : Déployer l'Infrastructure

#### 3.1. Prévisualiser les changements
```bash
terraform plan
```

#### 3.2. Déployer l'infrastructure
```bash
terraform apply
```

Terraform va créer :
- ✅ Resource Group
- ✅ Virtual Network + Subnet
- ✅ Network Security Group (règles SSH, HTTP, Flask)
- ✅ Public IP
- ✅ Machine Virtuelle Ubuntu
- ✅ Storage Account avec 3 containers (images, logs, static)
- ✅ PostgreSQL Flexible Server avec base de données

#### 3.3. Récupérer les informations de connexion
```bash
# Afficher toutes les outputs
terraform output

# IP publique de la VM
terraform output vm_public_ip

# Commande SSH
terraform output vm_ssh_command

# URL de l'application Flask
terraform output flask_app_url

# Connection string de la base de données
terraform output database_connection_string
```

### Étape 4 : Déployer l'Application Backend

#### Option A : Déploiement manuel

```bash
# 1. Se connecter à la VM
ssh azureuser@<VM_PUBLIC_IP>

# 2. Sur la VM, créer le répertoire et copier les fichiers
mkdir -p /home/azureuser/app
```

Depuis votre machine locale :
```bash
# 3. Copier les fichiers backend
cd ../backend
scp -r * azureuser@<VM_PUBLIC_IP>:/home/azureuser/app/

# 4. Se reconnecter à la VM
ssh azureuser@<VM_PUBLIC_IP>

# 5. Installer les dépendances
cd /home/azureuser/app
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt

# 6. Lancer l'application
python3 app.py
```

#### Option B : Déploiement automatique avec script

```bash
cd scripts
chmod +x deploy.sh

# Obtenir l'IP de la VM
VM_IP=$(cd ../terraform && terraform output -raw vm_public_ip)

# Déployer
./deploy.sh $VM_IP azureuser
```

Le script va :
1. Copier les fichiers backend sur la VM
2. Installer les dépendances Python
3. Créer un service systemd pour Flask
4. Démarrer l'application automatiquement

#### Option C : Avec Ansible (recommandé pour production)

```bash
cd ansible

# Vérifier l'inventaire
cat ../terraform/inventory.ini

# Exécuter le playbook
ansible-playbook -i ../terraform/inventory.ini playbook.yml
```

### Étape 5 : Tester l'Application

#### 5.1. Tester l'accès à l'API

```bash
# Obtenir l'URL
VM_IP=$(cd terraform && terraform output -raw vm_public_ip)
API_URL="http://${VM_IP}:5000"

# Test manuel
curl http://${VM_IP}:5000/api/health

# Ou utiliser le script de test
cd scripts
chmod +x test-api.sh
./test-api.sh $API_URL
```

#### 5.2. Endpoints disponibles

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/` | Page d'accueil de l'API |
| GET | `/api/health` | Health check |
| GET | `/api/files` | Liste des fichiers |
| GET | `/api/files/<id>` | Détails d'un fichier |
| DELETE | `/api/files/<id>` | Supprimer un fichier |
| POST | `/api/upload` | Upload un fichier |
| GET | `/api/users` | Liste des utilisateurs |
| POST | `/api/users` | Créer un utilisateur |
| GET | `/api/users/<id>` | Détails d'un utilisateur |
| PUT | `/api/users/<id>` | Modifier un utilisateur |
| DELETE | `/api/users/<id>` | Supprimer un utilisateur |
| GET | `/api/storage/info` | Infos sur le stockage |

#### 5.3. Exemples de requêtes

**Créer un utilisateur :**
```bash
curl -X POST http://${VM_IP}:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"john","email":"john@example.com"}'
```

**Lister les utilisateurs :**
```bash
curl http://${VM_IP}:5000/api/users
```

**Upload un fichier :**
```bash
curl -X POST http://${VM_IP}:5000/api/upload \
  -F "file=@image.jpg" \
  -F "container=images" \
  -F "description=Test image"
```

**Lister les fichiers :**
```bash
curl http://${VM_IP}:5000/api/files
```

### Étape 6 : Vérifier le Stockage et la Base de Données

#### 6.1. Vérifier Azure Blob Storage
```bash
# Lister les containers
az storage container list \
  --account-name $(cd terraform && terraform output -raw storage_account_name) \
  --auth-mode login

# Lister les blobs dans un container
az storage blob list \
  --account-name $(cd terraform && terraform output -raw storage_account_name) \
  --container-name images \
  --auth-mode login
```

#### 6.2. Se connecter à PostgreSQL
```bash
# Depuis votre machine locale
DB_HOST=$(cd terraform && terraform output -raw database_host)
psql "postgresql://dbadmin:VotreMotDePasse@${DB_HOST}:5432/appdb?sslmode=require"

# Lister les tables
\dt

# Voir les utilisateurs
SELECT * FROM users;

# Voir les fichiers
SELECT * FROM files;
```

## 🧪 Tests Complets

### Test du workflow complet

```bash
# 1. Créer un utilisateur
curl -X POST http://${VM_IP}:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com"}'

# 2. Vérifier dans la base de données
ssh azureuser@${VM_IP} \
  "psql postgresql://dbadmin:VotreMotDePasse@localhost:5432/appdb -c 'SELECT * FROM users;'"

# 3. Upload un fichier
echo "Test file" > test.txt
curl -X POST http://${VM_IP}:5000/api/upload \
  -F "file=@test.txt" \
  -F "container=static"

# 4. Vérifier le fichier dans Blob Storage
az storage blob list \
  --account-name tfcloudstorage2026 \
  --container-name static \
  --auth-mode login

# 5. Lister les fichiers via l'API
curl http://${VM_IP}:5000/api/files
```

## 🗑️ Destruction de l'Infrastructure

### Supprimer toutes les ressources

```bash
cd terraform
terraform destroy
```

⚠️ **Attention** : Cette commande supprimera **toutes** les ressources créées, y compris :
- La VM
- Le stockage (et tous les fichiers)
- La base de données (et toutes les données)

## 📊 Architecture du Projet

```
┌─────────────────────────────────────────────────────────┐
│                      Azure Cloud                         │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │           Resource Group                         │    │
│  │                                                   │    │
│  │  ┌──────────────┐      ┌──────────────────┐    │    │
│  │  │  Virtual     │      │  Blob Storage    │    │    │
│  │  │  Machine     │◄────►│  - images/       │    │    │
│  │  │  (Ubuntu)    │      │  - logs/         │    │    │
│  │  │              │      │  - static/       │    │    │
│  │  │  Flask App   │      └──────────────────┘    │    │
│  │  └──────────────┘                               │    │
│  │         │                                        │    │
│  │         │                                        │    │
│  │         ▼                                        │    │
│  │  ┌──────────────────┐                           │    │
│  │  │   PostgreSQL     │                           │    │
│  │  │   Database       │                           │    │
│  │  │   - users table  │                           │    │
│  │  │   - files table  │                           │    │
│  │  └──────────────────┘                           │    │
│  │                                                   │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │   Internet      │
                  │   HTTP:5000     │
                  │   SSH:22        │
                  └─────────────────┘
```

## 🔒 Sécurité

### Recommandations de sécurité

1. **Mots de passe** : Ne commitez jamais `terraform.tfvars` avec des mots de passe
2. **Clés SSH** : Utilisez des clés SSH fortes (4096 bits)
3. **Network Security Group** : Limitez les accès SSH à votre IP uniquement
4. **Firewall PostgreSQL** : En production, restreignez l'accès à la base de données
5. **HTTPS** : Configurez un certificat SSL pour la production
6. **Variables sensibles** : Utilisez Azure Key Vault pour les secrets

### Améliorer la sécurité

```hcl
# Dans main.tf, remplacer la règle SSH par :
security_rule {
  name                       = "SSH"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "VOTRE_IP/32"  # Votre IP uniquement
  destination_address_prefix = "*"
}
```

## 📝 Fichiers Importants

### `.gitignore` recommandé
```
# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfvars
crash.log

# Python
__pycache__/
*.py[cod]
*$py.class
.env
*.log

# SSH
*.pem
id_rsa*

# IDE
.vscode/
.idea/
```

## 🐛 Troubleshooting

### Problème : Le nom du Storage Account est déjà pris
**Solution** : Changez `storage_account_name` dans `terraform.tfvars` avec un nom unique

### Problème : Erreur de connexion SSH
**Solution** : 
```bash
# Vérifier que la clé SSH existe
ls -la ~/.ssh/id_rsa.pub

# Tester la connexion
ssh -v azureuser@<VM_IP>
```

### Problème : L'application Flask ne démarre pas
**Solution** :
```bash
# Se connecter à la VM
ssh azureuser@<VM_IP>

# Vérifier les logs
sudo journalctl -u flask-app.service -f

# Redémarrer le service
sudo systemctl restart flask-app.service
```

### Problème : Impossible de se connecter à PostgreSQL
**Solution** :
```bash
# Vérifier les règles firewall dans Azure Portal
# Ou via CLI
az postgres flexible-server firewall-rule list \
  --resource-group rg-terraform-cloud \
  --name tfcloud-postgresql
```

## 📚 Ressources Supplémentaires

- [Documentation Terraform](https://www.terraform.io/docs)
- [Azure Provider Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Documentation Flask](https://flask.palletsprojects.com/)
- [Azure Blob Storage SDK Python](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-python)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 👨‍💻 Auteur

Projet créé le 12 mars 2026 pour démontrer le déploiement automatisé d'infrastructure cloud avec Terraform.

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

**Note** : Ce projet est destiné à des fins éducatives et de démonstration. Pour un environnement de production, des configurations de sécurité supplémentaires sont recommandées.

Modifiez `terraform/terraform.tfvars` avec vos valeurs :

```hcl
resource_group_name = "rg-mon-projet"
location            = "East US"
environment         = "dev"
```

## Utilisation

### Déployer l'infrastructure

```bash
cd terraform

# Prévisualiser les changements
terraform plan

# Appliquer les changements
terraform apply

# Détruire l'infrastructure
terraform destroy
```

### Lancer le backend

```bash
cd backend
python3 app.py
```

L'API sera accessible sur `http://localhost:5000`

### Endpoints API

- `GET /` - Page d'accueil
- `GET /api/health` - Vérification de santé
- `GET /api/data` - Récupérer des données
- `POST /api/data` - Envoyer des données

## Développement

### Ajouter des ressources Terraform

Modifiez `terraform/main.tf` pour ajouter de nouvelles ressources Azure.

### Ajouter des endpoints API

Modifiez `backend/app.py` pour ajouter de nouveaux endpoints.

## Sécurité

⚠️ **Important** :
- Ne committez jamais `terraform.tfvars` avec des secrets
- Utilisez des variables d'environnement pour les données sensibles
- Activez l'authentification pour l'API en production

## Licence

Ce projet est sous licence MIT.

## Auteur

Projet créé le 12 mars 2026
