#!/bin/bash

# =====================================================
# SITEVOICE AI - SETUP COMPLET (1, 2, 3)
# =====================================================

set -e

echo "🚀 Setup Complet SiteVoice AI V2.0"
echo "===================================="

# Exécuter les 3 étapes
./scripts/generate_models.sh
./scripts/deploy_backend.sh

echo ""
echo "✅ Setup complet terminé !"
echo ""


