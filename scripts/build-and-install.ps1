# =====================================================
# BUILD AND INSTALL - SiteVoice AI
# =====================================================
# Script PowerShell pour compiler et installer l'app sur Android
# Usage: .\scripts\build-and-install.ps1

Write-Host "🚀 SiteVoice AI - Build & Install" -ForegroundColor Cyan
Write-Host "===================================`n" -ForegroundColor Cyan

# Vérifier qu'on est dans le bon dossier
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Erreur: Ce script doit être exécuté depuis la racine du projet" -ForegroundColor Red
    exit 1
}

# Étape 1: Clean
Write-Host "🧹 Nettoyage des fichiers de build..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du nettoyage" -ForegroundColor Red
    exit 1
}

# Étape 2: Get dependencies
Write-Host "`n📦 Installation des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de l'installation des dépendances" -ForegroundColor Red
    exit 1
}

# Étape 3: Analyze
Write-Host "`n🔍 Analyse du code..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Attention: Des erreurs d'analyse ont été détectées" -ForegroundColor Yellow
    $continue = Read-Host "Voulez-vous continuer quand même? (o/n)"
    if ($continue -ne "o") {
        exit 1
    }
}

# Étape 4: Build APK
Write-Host "`n🔨 Compilation de l'APK..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la compilation" -ForegroundColor Red
    exit 1
}

# Étape 5: Vérifier qu'un device est connecté
Write-Host "`n📱 Vérification des appareils connectés..." -ForegroundColor Yellow
$devices = & adb devices
if ($devices -match "device$") {
    Write-Host "✅ Appareil Android détecté" -ForegroundColor Green
    
    # Étape 6: Installer l'APK
    Write-Host "`n📲 Installation de l'APK..." -ForegroundColor Yellow
    & adb install -r "build\app\outputs\flutter-apk\app-release.apk"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Installation réussie!" -ForegroundColor Green
        Write-Host "🎉 L'application est prête à être testée" -ForegroundColor Cyan
    } else {
        Write-Host "`n❌ Erreur lors de l'installation" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠️  Aucun appareil Android détecté" -ForegroundColor Yellow
    Write-Host "📂 L'APK est disponible ici: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
}

Write-Host "`n✨ Terminé!" -ForegroundColor Green

