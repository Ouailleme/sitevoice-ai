# =====================================================
# QUICK COMMIT - SiteVoice AI
# =====================================================
# Script PowerShell pour faciliter les commits Git
# Usage: .\scripts\quick-commit.ps1

Write-Host "📝 SiteVoice AI - Quick Commit" -ForegroundColor Cyan
Write-Host "==============================`n" -ForegroundColor Cyan

# Vérifier qu'on est dans un repo Git
if (-not (Test-Path ".git")) {
    Write-Host "❌ Erreur: Pas de repository Git détecté" -ForegroundColor Red
    exit 1
}

# Afficher le statut
Write-Host "📊 Statut actuel:" -ForegroundColor Yellow
git status -s

# Demander le type de commit
Write-Host "`n🏷️  Type de commit:" -ForegroundColor Cyan
Write-Host "1. feat     ✨ Nouvelle fonctionnalité"
Write-Host "2. fix      🐛 Correction de bug"
Write-Host "3. refactor ♻️  Refactoring"
Write-Host "4. docs     📝 Documentation"
Write-Host "5. style    💄 Style UI/UX"
Write-Host "6. db       🗄️  Migration database"
Write-Host "7. chore    🔧 Tâches diverses"
Write-Host "8. perf     ⚡ Performance"

$typeChoice = Read-Host "`nChoisir un type (1-8)"

$types = @{
    "1" = "feat"
    "2" = "fix"
    "3" = "refactor"
    "4" = "docs"
    "5" = "style"
    "6" = "db"
    "7" = "chore"
    "8" = "perf"
}

if (-not $types.ContainsKey($typeChoice)) {
    Write-Host "❌ Choix invalide" -ForegroundColor Red
    exit 1
}

$type = $types[$typeChoice]

# Demander le scope
$scope = Read-Host "`n🎯 Scope (ex: clients, auth, supabase)"

# Demander le message
$message = Read-Host "`n💬 Message du commit"

# Construire le message de commit
$commitMessage = "$type($scope): $message"

Write-Host "`n📋 Message de commit:" -ForegroundColor Yellow
Write-Host "   $commitMessage" -ForegroundColor Green

# Demander confirmation
$confirm = Read-Host "`n✅ Confirmer? (o/n)"

if ($confirm -eq "o") {
    # Ajouter tous les fichiers
    git add .
    
    # Commit
    git commit -m $commitMessage
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Commit réussi!" -ForegroundColor Green
        
        # Demander si on veut push
        $push = Read-Host "`n🚀 Pousser vers le remote? (o/n)"
        if ($push -eq "o") {
            $branch = git branch --show-current
            git push origin $branch
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Push réussi vers $branch!" -ForegroundColor Green
            } else {
                Write-Host "❌ Erreur lors du push" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "❌ Erreur lors du commit" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ Commit annulé" -ForegroundColor Yellow
}

Write-Host "`n✨ Terminé!" -ForegroundColor Green

