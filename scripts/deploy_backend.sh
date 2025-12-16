#!/bin/bash

# =====================================================
# SITEVOICE AI - SCRIPT DE DÉPLOIEMENT BACKEND
# =====================================================

set -e

echo "🚀 Déploiement Backend SiteVoice AI V2.0"
echo "========================================"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =====================================================
# 1. VÉRIFICATIONS
# =====================================================

echo ""
echo "${BLUE}📋 Vérification des prérequis...${NC}"

# Vérifier Supabase CLI
if ! command -v supabase &> /dev/null
then
    echo "${RED}❌ Supabase CLI non installé${NC}"
    echo "Installez avec: npm install -g supabase"
    exit 1
fi

echo "${GREEN}✅ Supabase CLI installé${NC}"

# Vérifier si le projet est lié
if [ ! -f ".supabase/config.toml" ]; then
    echo "${RED}❌ Projet Supabase non lié${NC}"
    echo "Exécutez: supabase link --project-ref YOUR_PROJECT_REF"
    exit 1
fi

echo "${GREEN}✅ Projet Supabase lié${NC}"

# =====================================================
# 2. DÉPLOIEMENT SCHÉMA SQL
# =====================================================

echo ""
echo "${BLUE}📊 Déploiement du schéma SQL...${NC}"

# Schéma principal
echo "- Schéma principal (V1.5)"
supabase db push

# Schéma V2 (Webhooks)
echo "- Schéma V2.0 (Webhooks & Intégrations)"
supabase db execute --file supabase/schema_v2_webhooks.sql

echo "${GREEN}✅ Schémas SQL déployés${NC}"

# =====================================================
# 3. DÉPLOIEMENT EDGE FUNCTIONS
# =====================================================

echo ""
echo "${BLUE}⚡ Déploiement des Edge Functions...${NC}"

# Process Audio (V1.5 + multimodal)
echo "- process-audio"
supabase functions deploy process-audio --no-verify-jwt

# Webhook Dispatcher (V2.0)
echo "- webhook-dispatcher"
supabase functions deploy webhook-dispatcher --no-verify-jwt

# Stripe Functions
echo "- create-subscription"
supabase functions deploy create-subscription --no-verify-jwt

echo "- stripe-webhook"
supabase functions deploy stripe-webhook --no-verify-jwt

echo "${GREEN}✅ Edge Functions déployées${NC}"

# =====================================================
# 4. CONFIGURATION SECRETS
# =====================================================

echo ""
echo "${BLUE}🔐 Vérification des secrets...${NC}"

# Vérifier les secrets (sans les afficher)
secrets=(
  "OPENAI_API_KEY"
  "STRIPE_SECRET_KEY"
  "STRIPE_WEBHOOK_SECRET"
)

for secret in "${secrets[@]}"; do
  if supabase secrets list | grep -q "$secret"; then
    echo "${GREEN}✅ $secret configuré${NC}"
  else
    echo "${RED}⚠️  $secret manquant${NC}"
    echo "   Configurez avec: supabase secrets set $secret=your_value"
  fi
done

# =====================================================
# 5. CONFIGURATION CRON JOB (Webhook Dispatcher)
# =====================================================

echo ""
echo "${BLUE}⏰ Configuration Cron Job...${NC}"
echo "Pour le webhook dispatcher, configurez un cron job dans Supabase Dashboard:"
echo "  - Aller dans: Database → Cron Jobs"
echo "  - Créer: webhook-dispatcher (toutes les 1 minute)"
echo "  - Command: SELECT net.http_post('https://YOUR_PROJECT.supabase.co/functions/v1/webhook-dispatcher', '{}'::jsonb)"

# =====================================================
# 6. CONFIGURATION STORAGE
# =====================================================

echo ""
echo "${BLUE}💾 Vérification Storage Buckets...${NC}"

buckets=(
  "audio-recordings"
  "photos"
  "signatures"
)

for bucket in "${buckets[@]}"; do
  echo "- $bucket"
done

echo ""
echo "${BLUE}📝 Créez ces buckets dans Supabase Dashboard → Storage si nécessaire${NC}"

# =====================================================
# 7. RÉSUMÉ
# =====================================================

echo ""
echo "${GREEN}========================================${NC}"
echo "${GREEN}✅ Déploiement Backend Terminé !${NC}"
echo "${GREEN}========================================${NC}"
echo ""
echo "Prochaines étapes:"
echo "  1. Vérifier les Edge Functions dans le Dashboard"
echo "  2. Configurer le Cron Job webhook-dispatcher"
echo "  3. Créer les Storage Buckets manquants"
echo "  4. Tester avec l'app Flutter"
echo ""


