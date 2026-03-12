# Déploiement Automatisé d'Infrastructure Cloud avec Terraform

## Description

Déploiement automatisé d'une application Flask sur Azure avec Terraform.

**Infrastructure déployée** :
- Machine Virtuelle Ubuntu
- Azure Blob Storage (images, logs, fichiers)
- Base de données PostgreSQL
- Application Flask avec API CRUD

## Prérequis

- Terraform >= 1.0
- Azure CLI
- Clé SSH

## Installation

### 1. Se connecter à Azure
```bash
az login
```

### 2. Configurer les variables
Éditez `terraform/terraform.tfvars` et modifiez :
- `storage_account_name` (doit être unique!)
- `db_admin_password`

### 3. Déployer
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Accéder à l'application
```bash
terraform output vm_public_ip
curl http://\<IP\>:5000
```

## Tests

```bash
# Récupérer l'IP
VM_IP=$(terraform output -raw vm_public_ip)

# Tester l'API
curl http://$VM_IP:5000
curl http://$VM_IP:5000/health

# Upload fichier
curl -X POST -F "file=@test.txt" http://$VM_IP:5000/upload

# Liste fichiers
curl http://$VM_IP:5000/files
```

## API Endpoints

- `GET /` - Infos API
- `GET /health` - Status
- `POST /upload` - Upload fichier
- `GET /files` - Liste fichiers
- `GET /files/:id` - Détails fichier
- `DELETE /files/:id` - Supprimer fichier
- `POST /users` - Créer utilisateur
- `GET /users` - Liste utilisateurs

## Suppression

```bash
terraform destroy
```
