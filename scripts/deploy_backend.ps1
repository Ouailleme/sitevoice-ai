# =====================================================
# SITEVOICE AI - SCRIPT DE DÉPLOIEMENT BACKEND (PowerShell)
# =====================================================

Write-Host "🚀 Déploiement Backend SiteVoice AI V2.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# =====================================================
# 1. VÉRIFICATIONS
# =====================================================

Write-Host "📋 Vérification des prérequis..." -ForegroundColor Blue

# Vérifier Supabase CLI
try {
    $null = Get-Command supabase -ErrorAction Stop
    Write-Host "✅ Supabase CLI installé" -ForegroundColor Green
} catch {
    Write-Host "❌ Supabase CLI non installé" -ForegroundColor Red
    Write-Host "Installez avec: npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Vérifier si le projet est lié
if (-not (Test-Path ".supabase\config.toml")) {
    Write-Host "❌ Projet Supabase non lié" -ForegroundColor Red
    Write-Host "Exécutez: supabase link --project-ref YOUR_PROJECT_REF" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Projet Supabase lié" -ForegroundColor Green

# =====================================================
# 2. DÉPLOIEMENT SCHÉMA SQL
# =====================================================

Write-Host ""
Write-Host "📊 Déploiement du schéma SQL..." -ForegroundColor Blue

# Schéma principal
Write-Host "- Schéma principal (V1.5)"
supabase db push

# Schéma V2 (Webhooks)
Write-Host "- Schéma V2.0 (Webhooks & Intégrations)"
Get-Content "supabase\schema_v2_webhooks.sql" | supabase db execute

Write-Host "✅ Schémas SQL déployés" -ForegroundColor Green

# =====================================================
# 3. DÉPLOIEMENT EDGE FUNCTIONS
# =====================================================

Write-Host ""
Write-Host "⚡ Déploiement des Edge Functions..." -ForegroundColor Blue

# Process Audio (V1.5 + multimodal)
Write-Host "- process-audio"
supabase functions deploy process-audio --no-verify-jwt

# Webhook Dispatcher (V2.0)
Write-Host "- webhook-dispatcher"
supabase functions deploy webhook-dispatcher --no-verify-jwt

# Stripe Functions
Write-Host "- create-subscription"
supabase functions deploy create-subscription --no-verify-jwt

Write-Host "- stripe-webhook"
supabase functions deploy stripe-webhook --no-verify-jwt

Write-Host "✅ Edge Functions déployées" -ForegroundColor Green

# =====================================================
# 4. VÉRIFICATION SECRETS
# =====================================================

Write-Host ""
Write-Host "🔐 Vérification des secrets..." -ForegroundColor Blue

$secrets = @(
    "OPENAI_API_KEY",
    "STRIPE_SECRET_KEY",
    "STRIPE_WEBHOOK_SECRET"
)

foreach ($secret in $secrets) {
    $exists = supabase secrets list | Select-String $secret
    if ($exists) {
        Write-Host "✅ $secret configuré" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $secret manquant" -ForegroundColor Yellow
        Write-Host "   Configurez avec: supabase secrets set $secret=your_value" -ForegroundColor Gray
    }
}

# =====================================================
# 5. INSTRUCTIONS POST-DÉPLOIEMENT
# =====================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Déploiement Backend Terminé !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Prochaines étapes:" -ForegroundColor Yellow
Write-Host "  1. Créer les Storage Buckets dans Supabase Dashboard:"
Write-Host "     - audio-recordings (Public)"
Write-Host "     - photos (Public)"
Write-Host "     - signatures (Private)"
Write-Host ""
Write-Host "  2. Configurer le Cron Job webhook-dispatcher:"
Write-Host "     Dashboard → Database → Cron Jobs → Create"
Write-Host "     Nom: webhook-dispatcher"
Write-Host "     Fréquence: */1 * * * * (toutes les minutes)"
Write-Host ""
Write-Host "  3. Vérifier les Edge Functions dans le Dashboard"
Write-Host ""
Write-Host "  4. Tester avec: flutter run"
Write-Host ""


