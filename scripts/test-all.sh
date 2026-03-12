#!/bin/bash
# Script de tests automatisés - Étape 5
# Projet Terraform Cloud Computing
# Date: 12 mars 2026

set -e

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VM_IP="51.103.99.41"
API_URL="http://${VM_IP}:5000"
STORAGE_ACCOUNT="tfcloudstorage2026"

echo "=========================================="
echo "🧪 TESTS AUTOMATISÉS - ÉTAPE 5"
echo "=========================================="
echo ""

# Test 1: Accès API
echo "Test 1: Accès à l'API Flask..."
if curl -s -f "${API_URL}" > /dev/null; then
    echo -e "${GREEN}✅ Test 1 RÉUSSI${NC}: API accessible"
    curl -s "${API_URL}" | python3 -m json.tool | head -15
else
    echo -e "${RED}❌ Test 1 ÉCHOUÉ${NC}: API inaccessible"
fi
echo ""

# Test 2: Health Check
echo "Test 2: Health Check..."
HEALTH_RESPONSE=$(curl -s "${API_URL}/health")
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo -e "${GREEN}✅ Test 2 RÉUSSI${NC}: Application en bonne santé"
    echo "$HEALTH_RESPONSE" | python3 -m json.tool
else
    echo -e "${RED}❌ Test 2 ÉCHOUÉ${NC}: Application non saine"
fi
echo ""

# Test 3: Stockage Azure
echo "Test 3: Vérification Azure Blob Storage..."
if az storage container list --account-name ${STORAGE_ACCOUNT} --output table 2>/dev/null | grep -q "images"; then
    echo -e "${GREEN}✅ Test 3 RÉUSSI${NC}: Conteneurs Azure créés"
    az storage container list --account-name ${STORAGE_ACCOUNT} --output table
else
    echo -e "${RED}❌ Test 3 ÉCHOUÉ${NC}: Conteneurs non trouvés"
fi
echo ""

# Test 4: Service systemd (via SSH)
echo "Test 4: Vérification service Flask..."
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 azureuser@${VM_IP} "sudo systemctl is-active flask-app" 2>/dev/null | grep -q "active"; then
    echo -e "${GREEN}✅ Test 4 RÉUSSI${NC}: Service Flask actif"
    ssh -o StrictHostKeyChecking=no azureuser@${VM_IP} "sudo systemctl status flask-app --no-pager | head -10"
else
    echo -e "${YELLOW}⚠️ Test 4 SKIP${NC}: SSH non configuré ou clé requise"
fi
echo ""

# Test 5: Terraform Outputs
echo "Test 5: Terraform Outputs..."
cd "$(dirname "$0")/terraform" 2>/dev/null || cd terraform
if terraform output > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Test 5 RÉUSSI${NC}: Outputs Terraform disponibles"
    terraform output
else
    echo -e "${YELLOW}⚠️ Test 5 WARNING${NC}: État Terraform manquant (exécuter terraform refresh)"
fi
echo ""

# Test 6: Resource Group Azure
echo "Test 6: Vérification Resource Group..."
if az group show --name rg-terraform-cloud --output table 2>/dev/null | grep -q "francecentral"; then
    echo -e "${GREEN}✅ Test 6 RÉUSSI${NC}: Resource Group existe dans Azure"
    az group show --name rg-terraform-cloud --output table
else
    echo -e "${RED}❌ Test 6 ÉCHOUÉ${NC}: Resource Group introuvable"
fi
echo ""

# Résumé
echo "=========================================="
echo "📊 RÉSUMÉ DES TESTS"
echo "=========================================="
echo -e "${GREEN}Tests réussis:${NC} Vérifier les résultats ci-dessus"
echo -e "${YELLOW}Tests partiels:${NC} Upload/CRUD nécessitent PostgreSQL (optionnel)"
echo ""
echo "🎯 Prochaines étapes:"
echo "  1. Prendre screenshots du portail Azure"
echo "  2. Compiler le rapport final"
echo "  3. Exécuter 'terraform destroy' pour nettoyer"
echo ""
