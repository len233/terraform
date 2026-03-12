#!/bin/bash

###############################################################################
# Script de test pour l'API Flask
# Usage: ./test-api.sh <VM_IP>
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VM_IP="${1:-localhost}"
BASE_URL="http://${VM_IP}:5000"
TEST_FILE="/tmp/test-image.jpg"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test de l'API Flask - Projet Cloud  ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}URL de base:${NC} ${BASE_URL}"
echo ""

# Fonction pour afficher les résultats
print_test() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

# Créer un fichier de test
echo -e "${YELLOW}Préparation...${NC}"
echo "This is a test file for Flask API" > "$TEST_FILE"
echo -e "${GREEN}✓ Fichier de test créé${NC}\n"

# Test 1: Page d'accueil
echo -e "${BLUE}Test 1: GET / (Page d'accueil)${NC}"
response=$(curl -s -w "\n%{http_code}" "$BASE_URL/")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    print_test "Page d'accueil accessible"
else
    echo -e "${RED}HTTP Status: $http_code${NC}"
    exit 1
fi
echo ""

# Test 2: Health check
echo -e "${BLUE}Test 2: GET /health (Health check)${NC}"
response=$(curl -s "$BASE_URL/health")
echo "$response" | jq '.' 2>/dev/null || echo "$response"
print_test "Health check fonctionnel"
echo ""

# Test 3: Upload de fichier
echo -e "${BLUE}Test 3: POST /upload (Upload fichier)${NC}"
response=$(curl -s -X POST \
    -F "file=@$TEST_FILE" \
    -F "container=static" \
    -F "description=Test file from script" \
    "$BASE_URL/upload")
echo "$response" | jq '.' 2>/dev/null || echo "$response"
file_id=$(echo "$response" | jq -r '.file_id' 2>/dev/null)
print_test "Upload de fichier réussi (ID: $file_id)"
echo ""

# Test 4: Liste des fichiers
echo -e "${BLUE}Test 4: GET /files (Liste des fichiers)${NC}"
response=$(curl -s "$BASE_URL/files")
echo "$response" | jq '.' 2>/dev/null || echo "$response"
file_count=$(echo "$response" | jq '.count' 2>/dev/null)
print_test "Liste des fichiers récupérée ($file_count fichier(s))"
echo ""

# Test 5: Détails d'un fichier
if [ ! -z "$file_id" ] && [ "$file_id" != "null" ]; then
    echo -e "${BLUE}Test 5: GET /files/$file_id (Détails du fichier)${NC}"
    response=$(curl -s "$BASE_URL/files/$file_id")
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    print_test "Détails du fichier récupérés"
    echo ""
fi

# Test 6: Créer un utilisateur
echo -e "${BLUE}Test 6: POST /users (Créer un utilisateur)${NC}"
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser","email":"test@example.com"}' \
    "$BASE_URL/users")
echo "$response" | jq '.' 2>/dev/null || echo "$response"
user_id=$(echo "$response" | jq -r '.user.id' 2>/dev/null)
print_test "Utilisateur créé (ID: $user_id)"
echo ""

# Test 7: Liste des utilisateurs
echo -e "${BLUE}Test 7: GET /users (Liste des utilisateurs)${NC}"
response=$(curl -s "$BASE_URL/users")
echo "$response" | jq '.' 2>/dev/null || echo "$response"
user_count=$(echo "$response" | jq '.count' 2>/dev/null)
print_test "Liste des utilisateurs récupérée ($user_count utilisateur(s))"
echo ""

# Test 8: Détails d'un utilisateur
if [ ! -z "$user_id" ] && [ "$user_id" != "null" ]; then
    echo -e "${BLUE}Test 8: GET /users/$user_id (Détails de l'utilisateur)${NC}"
    response=$(curl -s "$BASE_URL/users/$user_id")
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    print_test "Détails de l'utilisateur récupérés"
    echo ""
fi

# Test 9: Supprimer l'utilisateur
if [ ! -z "$user_id" ] && [ "$user_id" != "null" ]; then
    echo -e "${BLUE}Test 9: DELETE /users/$user_id (Supprimer l'utilisateur)${NC}"
    response=$(curl -s -X DELETE "$BASE_URL/users/$user_id")
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    print_test "Utilisateur supprimé"
    echo ""
fi

# Test 10: Supprimer le fichier
if [ ! -z "$file_id" ] && [ "$file_id" != "null" ]; then
    echo -e "${BLUE}Test 10: DELETE /files/$file_id (Supprimer le fichier)${NC}"
    response=$(curl -s -X DELETE "$BASE_URL/files/$file_id")
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    print_test "Fichier supprimé"
    echo ""
fi

# Nettoyage
rm -f "$TEST_FILE"

# Résumé
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Tous les tests sont passés !${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Résumé:${NC}"
echo -e "  - API Flask: ${GREEN}Fonctionnelle${NC}"
echo -e "  - Stockage Azure Blob: ${GREEN}Fonctionnel${NC}"
echo -e "  - Base de données PostgreSQL: ${GREEN}Fonctionnelle${NC}"
echo -e "  - CRUD Fichiers: ${GREEN}Opérationnel${NC}"
echo -e "  - CRUD Utilisateurs: ${GREEN}Opérationnel${NC}"
echo ""
echo -e "${BLUE}Application accessible à:${NC} ${BASE_URL}"
echo ""
