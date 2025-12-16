#!/bin/bash

# =====================================================
# SITEVOICE AI - GÉNÉRATION DES MODÈLES JSON
# =====================================================

set -e

echo "🔨 Génération des modèles JSON"
echo "=============================="

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "${BLUE}📦 Installation des dépendances...${NC}"
flutter pub get

echo ""
echo "${BLUE}🏗️  Génération des fichiers .g.dart...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "${GREEN}✅ Génération terminée !${NC}"
echo ""
echo "Fichiers générés:"
echo "  - lib/data/models/user_model.g.dart"
echo "  - lib/data/models/job_model.g.dart"
echo "  - lib/data/models/client_model.g.dart"
echo "  - lib/data/models/product_model.g.dart"
echo ""


