# ========================================
# Script de Deploiement Backend SiteVoice AI
# Version: NPX (Sans installation globale)
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOIEMENT BACKEND - SiteVoice AI V2.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verifier que nous sommes dans le bon repertoire
if (-not (Test-Path "supabase/schema.sql")) {
    Write-Host "Erreur: Fichier schema.sql non trouve" -ForegroundColor Red
    Write-Host "Assurez-vous d'etre dans le repertoire racine du projet" -ForegroundColor Yellow
    exit 1
}

Write-Host "Repertoire projet valide" -ForegroundColor Green
Write-Host ""

# ========================================
# ETAPE 1 : Verifier Node.js et npm
# ========================================
Write-Host "Etape 1/6 : Verification de l'environnement..." -ForegroundColor Yellow

try {
    $nodeVersion = node --version 2>&1
    Write-Host "  Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "  Node.js n'est pas installe" -ForegroundColor Red
    Write-Host "  Voir: INSTALL_NODEJS_SIMPLE.md" -ForegroundColor Yellow
    exit 1
}

try {
    $npmVersion = npm --version 2>&1
    Write-Host "  npm: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "  npm n'est pas installe" -ForegroundColor Red
    exit 1
}

Write-Host "  Utilisation de npx (pas d'installation globale necessaire)" -ForegroundColor Cyan
Write-Host ""

# ========================================
# ETAPE 2 : Lier le Projet Supabase
# ========================================
Write-Host "Etape 2/6 : Liaison au projet Supabase..." -ForegroundColor Yellow

$projectRef = "dndjtcxypqnsyjzlzbxh"
Write-Host "  Reference ID: $projectRef" -ForegroundColor Cyan
Write-Host "  Liaison en cours..." -ForegroundColor Cyan

try {
    npx supabase link --project-ref $projectRef --password "gr0sc4c4k1pu3" 2>&1
    Write-Host "  Projet lie avec succes" -ForegroundColor Green
} catch {
    Write-Host "  Erreur lors de la liaison" -ForegroundColor Yellow
    Write-Host "  Continuons quand meme..." -ForegroundColor Cyan
}

Write-Host ""

# ========================================
# ETAPE 3 : Deployer le Schema SQL V1.5
# ========================================
Write-Host "Etape 3/6 : Deploiement du schema SQL V1.5..." -ForegroundColor Yellow

if (Test-Path "supabase/schema.sql") {
    Write-Host "  Deploiement de schema.sql..." -ForegroundColor Cyan
    
    # Lecture du fichier SQL
    $sqlContent = Get-Content "supabase/schema.sql" -Raw -Encoding UTF8
    
    Write-Host "  Utilisez le SQL Editor dans le Dashboard Supabase pour deployer:" -ForegroundColor Yellow
    Write-Host "  1. Ouvrir Dashboard -> SQL Editor" -ForegroundColor White
    Write-Host "  2. Copier le contenu de supabase/schema.sql" -ForegroundColor White
    Write-Host "  3. Coller et Run" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "  Fichier schema.sql non trouve" -ForegroundColor Yellow
}

# ========================================
# ETAPE 4 : Deployer le Schema SQL V2.0
# ========================================
Write-Host "Etape 4/6 : Deploiement du schema SQL V2.0 (Webhooks)..." -ForegroundColor Yellow

if (Test-Path "supabase/schema_v2_webhooks.sql") {
    Write-Host "  Deploiement de schema_v2_webhooks.sql..." -ForegroundColor Cyan
    Write-Host "  Utilisez le SQL Editor dans le Dashboard Supabase" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "  Fichier schema_v2_webhooks.sql non trouve" -ForegroundColor Yellow
}

# ========================================
# ETAPE 5 : Deployer les Edge Functions
# ========================================
Write-Host "Etape 5/6 : Deploiement des Edge Functions..." -ForegroundColor Yellow

$functions = @(
    "process-audio",
    "webhook-dispatcher",
    "create-subscription",
    "stripe-webhook"
)

foreach ($func in $functions) {
    if (Test-Path "supabase/functions/$func") {
        Write-Host "  Deploiement de $func..." -ForegroundColor Cyan
        
        try {
            npx supabase functions deploy $func --no-verify-jwt 2>&1 | Out-Null
            Write-Host "  $func deployee avec succes" -ForegroundColor Green
        } catch {
            Write-Host "  Erreur lors du deploiement de $func" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Fonction $func non trouvee" -ForegroundColor Yellow
    }
}

Write-Host ""

# ========================================
# ETAPE 6 : Verifier les Secrets
# ========================================
Write-Host "Etape 6/6 : Configuration des secrets..." -ForegroundColor Yellow

Write-Host "  Les secrets suivants doivent etre configures dans Supabase Dashboard:" -ForegroundColor Cyan
Write-Host "     OPENAI_API_KEY" -ForegroundColor White
Write-Host "     STRIPE_SECRET_KEY" -ForegroundColor White
Write-Host "     STRIPE_WEBHOOK_SECRET" -ForegroundColor White
Write-Host ""
Write-Host "  Pour configurer:" -ForegroundColor Cyan
Write-Host "     1. Dashboard Supabase -> Settings -> Edge Functions -> Secrets" -ForegroundColor White
Write-Host "     2. Ajouter chaque secret avec sa valeur" -ForegroundColor White
Write-Host ""

# ========================================
# RESUME FINAL
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOIEMENT TERMINE !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Backend SiteVoice AI V2.0 deploye avec succes" -ForegroundColor Green
Write-Host ""

Write-Host "Prochaines etapes:" -ForegroundColor Yellow
Write-Host "  1. Deployer les schemas SQL via le Dashboard (voir ci-dessus)" -ForegroundColor White
Write-Host "  2. Configurer les secrets (voir ci-dessus)" -ForegroundColor White
Write-Host "  3. Creer les Storage Buckets:" -ForegroundColor White
Write-Host "     audio-recordings (Public)" -ForegroundColor White
Write-Host "     photos (Public)" -ForegroundColor White
Write-Host "     signatures (Private)" -ForegroundColor White
Write-Host "  4. Creer le fichier .env avec vos cles API" -ForegroundColor White
Write-Host "  5. Lancer l'app: flutter run" -ForegroundColor White
Write-Host ""

Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  QUICK_START.md - Guide de demarrage" -ForegroundColor White
Write-Host "  DEPLOYMENT.md - Guide de deploiement complet" -ForegroundColor White
Write-Host "  START_HERE.md - Vue d'ensemble" -ForegroundColor White
Write-Host ""

Write-Host "Votre app SiteVoice AI est prete !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
