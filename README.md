# Projet Cloud Computing - Terraform Azure

Déploiement automatisé d'une infrastructure cloud sur Azure avec Terraform.

## Description

Ce projet déploie automatiquement sur Azure :
- Une machine virtuelle Ubuntu 22.04 avec Flask
- Un compte de stockage Azure Blob (3 containers)
- Une base de données PostgreSQL
- Un réseau virtuel avec sécurité (NSG)

## Prérequis

- Terraform >= 1.0
- Azure CLI
- Compte Azure avec droits de création de ressources
- Clé SSH pour accès à la VM

---

## Installation

### 1. Cloner le projet

```bash
git clone https://github.com/len233/terraform.git
cd terraform/terraform
```

### 2. Se connecter à Azure

```bash
az login
```

### 3. Configurer les variables

Éditez `terraform.tfvars` et modifiez :

```hcl
storage_account_name = "votrestorageunique2026"  # Doit être unique !
db_admin_password = "VotreMotDePasseSecure123!"
```

### 4. Déployer l'infrastructure

```bash
# Initialiser Terraform
terraform init

# Vérifier le plan
terraform plan

# Déployer (durée : 10-15 minutes)
terraform apply -auto-approve
```

À la fin, Terraform affichera l'IP publique de votre VM.

---

## Utilisation

### Récupérer l'IP de la VM

```bash
VM_IP=$(terraform output -raw vm_public_ip)
echo $VM_IP
```

### Accéder à l'API

```bash
# Page d'accueil
curl http://$VM_IP:5000

# Vérifier la santé (database + storage)
curl http://$VM_IP:5000/health
```

### Tests CRUD Utilisateurs

```bash
# Créer un utilisateur
curl -X POST http://$VM_IP:5000/users \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","email":"alice@example.com"}'

# Lire tous les utilisateurs
curl http://$VM_IP:5000/users

# Lire un utilisateur spécifique
curl http://$VM_IP:5000/users/1

# Supprimer un utilisateur
curl -X DELETE http://$VM_IP:5000/users/1
```

### Upload de fichiers

```bash
# Upload un fichier
echo "Test fichier" > test.txt
curl -X POST -F "file=@test.txt" http://$VM_IP:5000/upload

# Lister les fichiers
curl http://$VM_IP:5000/files

# Télécharger un fichier
curl http://$VM_IP:5000/download/1 -o fichier.txt
```

---

## Endpoints API

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/` | Page d'accueil |
| GET | `/health` | Status santé |
| GET | `/users` | Liste utilisateurs |
| POST | `/users` | Créer utilisateur |
| GET | `/users/<id>` | Lire utilisateur |
| DELETE | `/users/<id>` | Supprimer utilisateur |
| POST | `/upload` | Upload fichier |
| GET | `/files` | Liste fichiers |
| GET | `/files/<id>` | Info fichier |
| GET | `/download/<id>` | Télécharger fichier |
| DELETE | `/files/<id>` | Supprimer fichier |

---

## Nettoyage

Pour supprimer toute l'infrastructure :

```bash
terraform destroy -auto-approve
```

---

## Structure du Projet

```
terraform/
├── README.md                   # Documentation
├── terraform/
│   ├── main.tf                # Infrastructure principale
│   ├── variables.tf           # Variables
│   ├── outputs.tf             # Outputs
│   ├── provider.tf            # Configuration Azure
│   ├── terraform.tfvars       # Valeurs des variables
│   └── cloud-init.yaml        # Script provisioning VM
├── backend/
│   ├── app.py                 # API Flask
│   └── requirements.txt       # Dépendances Python
└── scripts/
    └── import-resources.sh    # Script import ressources
```

---

## Ressources Déployées

- 1 Resource Group
- 1 Virtual Machine Ubuntu 22.04 (2 vCPUs, 4GB RAM)
- 1 Virtual Network + Subnet
- 1 IP Publique
- 1 Network Security Group (ports 22, 80, 5000)
- 1 Storage Account + 3 Containers (images, logs, static)
- 1 PostgreSQL Flexible Server + Database
- 2 Firewall Rules PostgreSQL

**Total : 16 ressources Azure**

---

## Dépannage

### VM inaccessible

```bash
# Attendre 2-3 minutes pour cloud-init
# Vérifier le statut
az vm get-instance-view \
  --resource-group rg-terraform-cloud \
  --name tfcloud-vm
```

### Base de données non connectée

```bash
# Vérifier les logs
ssh azureuser@$VM_IP
sudo journalctl -u flask-app.service -n 50
```

### Storage account déjà pris

Changez le nom dans `terraform.tfvars` (doit être unique globalement).

---

## Auteur

Fait par Hélène
Projet Cloud Computing - Mars 2026  
Repository : https://github.com/len233/terraform
