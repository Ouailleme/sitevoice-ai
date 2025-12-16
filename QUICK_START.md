# 🚀 Quick Start - SiteVoice AI V2.0

Guide rapide pour démarrer le projet en 5 minutes.

---

## ✅ Étape 1 : Générer les Modèles JSON

### Option A : Script Automatique (Recommandé)

```bash
# Rendre le script exécutable
chmod +x scripts/generate_models.sh

# Exécuter
./scripts/generate_models.sh
```

### Option B : Manuel

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Résultat** : Fichiers `.g.dart` générés pour tous les modèles.

---

## ✅ Étape 2 : Déployer les Edge Functions

### Prérequis

1. Installer Supabase CLI :
```bash
npm install -g supabase
```

2. Lier le projet :
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

### Option A : Script Automatique (Recommandé)

```bash
# Rendre le script exécutable
chmod +x scripts/deploy_backend.sh

# Exécuter
./scripts/deploy_backend.sh
```

### Option B : Manuel

```bash
# Schéma SQL principal
supabase db push

# Schéma V2 (Webhooks)
supabase db execute --file supabase/schema_v2_webhooks.sql

# Edge Functions
supabase functions deploy process-audio --no-verify-jwt
supabase functions deploy webhook-dispatcher --no-verify-jwt
supabase functions deploy create-subscription --no-verify-jwt
supabase functions deploy stripe-webhook --no-verify-jwt
```

---

## ✅ Étape 3 : Configurer les Secrets

```bash
# OpenAI (pour Whisper + GPT-4o + TTS)
supabase secrets set OPENAI_API_KEY=sk-...

# Stripe
supabase secrets set STRIPE_SECRET_KEY=sk_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

---

## 🔧 Configuration Post-Déploiement

### 1. Créer les Storage Buckets

Via Supabase Dashboard → **Storage** :

- `audio-recordings` (Public)
- `photos` (Public)
- `signatures` (Private)

### 2. Configurer le Cron Job (Webhook Dispatcher)

Via Supabase Dashboard → **Database** → **Cron Jobs** :

```sql
-- Nom: webhook-dispatcher
-- Fréquence: Toutes les 1 minute
-- Commande:
SELECT net.http_post(
  'https://YOUR_PROJECT.supabase.co/functions/v1/webhook-dispatcher',
  '{}'::jsonb
);
```

### 3. Configuration Mobile

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### iOS (`ios/Runner/Info.plist`)

Déjà configuré ! Voir le fichier pour les descriptions.

---

## 🧪 Tester l'Installation

### 1. Lancer l'App

```bash
flutter run
```

### 2. Test Minimal

1. **Créer un compte** (Signup)
2. **Enregistrer un vocal** test
3. **Vérifier la transcription** dans Supabase Dashboard
4. **Activer le geofencing** dans Settings
5. **Configurer un webhook** Zapier test

---

## 🐛 Dépannage

### Erreur : Supabase CLI not found

```bash
npm install -g supabase
```

### Erreur : Project not linked

```bash
supabase link --project-ref YOUR_PROJECT_REF
```

### Erreur : OpenAI API Key

Vérifiez les secrets :
```bash
supabase secrets list
```

### Erreur : Build Runner

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📚 Documentation Complète

- [SETUP_DEV.md](SETUP_DEV.md) : Installation développeur détaillée
- [DEPLOYMENT.md](DEPLOYMENT.md) : Déploiement production
- [V2_FEATURES_SUMMARY.md](V2_FEATURES_SUMMARY.md) : Fonctionnalités V2.0
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) : Architecture complète

---

## 🆘 Support

En cas de problème :

1. Vérifier les logs Supabase Dashboard
2. Consulter la documentation
3. Vérifier les permissions mobiles

---

**Temps total** : ~5-10 minutes  
**Difficulté** : ⭐⭐ (Moyen)

Bon déploiement ! 🚀


