# 🛠️ Guide d'Installation Développement - SiteVoice AI

Ce guide vous aide à configurer l'environnement de développement local.

## 📋 Prérequis

### Logiciels requis

- **Flutter SDK** : >= 3.2.0
  - [Installation Flutter](https://docs.flutter.dev/get-started/install)
- **Supabase CLI**
  - ```bash
    npm install -g supabase
    ```
- **Deno** (pour les Edge Functions)
  - [Installation Deno](https://deno.land/manual/getting_started/installation)
- **Git**

### Comptes requis (pour les tests)

- Supabase (gratuit)
- OpenAI (minimum 5$ de crédits)
- Stripe (mode test gratuit)

---

## 🚀 Installation

### 1. Cloner le projet

```bash
git clone https://github.com/votre-repo/sitevoice-ai.git
cd sitevoice-ai
```

### 2. Installer les dépendances Flutter

```bash
flutter pub get
```

### 3. Générer les fichiers JSON

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configurer Supabase

#### A. Créer un projet local

```bash
supabase init
supabase start
```

Cela va démarrer Docker avec :
- PostgreSQL (port 54322)
- API (port 54321)
- Studio (port 54323)

#### B. Appliquer le schéma

```bash
supabase db push
```

#### C. Créer le bucket Storage

Via Supabase Studio (http://localhost:54323) :
1. Aller dans **Storage**
2. Créer un bucket `audio-recordings`
3. Le rendre public

### 5. Configurer les variables d'environnement

Copier `env.example` vers `.env` :

```bash
cp env.example .env
```

Puis éditer `.env` avec vos vraies valeurs :

```env
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-local-anon-key
OPENAI_API_KEY=sk-...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

**Pour récupérer les clés Supabase locales :**
```bash
supabase status
```

### 6. Déployer les Edge Functions localement

```bash
# Process Audio
supabase functions serve process-audio --env-file .env

# Dans un autre terminal - Create Subscription
supabase functions serve create-subscription --env-file .env

# Dans un autre terminal - Stripe Webhook
supabase functions serve stripe-webhook --env-file .env
```

---

## 🧪 Lancer l'application

### En mode développement

```bash
flutter run --dart-define-from-file=.env
```

### Sur un device spécifique

```bash
# Lister les devices
flutter devices

# Lancer sur un device
flutter run -d <device-id>
```

### Hot Reload

Pendant l'exécution :
- Appuyez sur `r` pour hot reload
- Appuyez sur `R` pour hot restart
- Appuyez sur `q` pour quitter

---

## 🧰 Outils de Développement

### A. Supabase Studio

URL : http://localhost:54323

**Ce que vous pouvez faire :**
- Explorer la base de données
- Tester les requêtes SQL
- Voir les logs des Edge Functions
- Gérer les utilisateurs
- Gérer le Storage

### B. Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Fonctionnalités :**
- Inspector de widgets
- Performance profiling
- Memory analysis
- Network inspector

### C. Logs

**Logs Flutter :**
```bash
flutter logs
```

**Logs Supabase :**
```bash
supabase functions logs
```

---

## 📝 Commandes Utiles

### Flutter

```bash
# Nettoyer le projet
flutter clean

# Rebuild
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Analyser le code
flutter analyze

# Formater le code
dart format .

# Lancer les tests
flutter test
```

### Supabase

```bash
# Redémarrer Supabase
supabase stop
supabase start

# Voir le statut
supabase status

# Réinitialiser la DB
supabase db reset

# Créer une migration
supabase migration new nom_migration
```

### Git

```bash
# Créer une branche feature
git checkout -b feature/nom-feature

# Commit avec convention
git commit -m "feat(module): description"

# Push
git push origin feature/nom-feature
```

---

## 🐛 Débogage

### Problème : Flutter n'est pas reconnu

**Solution :**
```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

### Problème : Supabase ne démarre pas

**Solution :**
```bash
# Vérifier que Docker est lancé
docker ps

# Nettoyer et redémarrer
supabase stop --no-backup
supabase start
```

### Problème : Build Android échoue

**Solution :**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Problème : CocoaPods (iOS)

**Solution :**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

---

## 🧪 Tests

### Tester l'enregistrement audio

1. Lancer l'app
2. Se connecter avec un compte test
3. Aller sur l'écran d'enregistrement
4. Autoriser le microphone
5. Enregistrer un rapport vocal
6. Vérifier dans Supabase Studio que le job est créé

### Tester le traitement IA

1. Créer un enregistrement
2. Vérifier dans les logs de l'Edge Function `process-audio`
3. Vérifier que la transcription apparaît
4. Vérifier que les données sont extraites

### Tester l'Offline-First

1. Créer un enregistrement
2. Désactiver le WiFi/4G
3. L'enregistrement doit être sauvegardé en local
4. Réactiver le réseau
5. Vérifier que la sync se fait automatiquement

---

## 📚 Ressources

### Documentation

- [Flutter](https://docs.flutter.dev)
- [Supabase](https://supabase.com/docs)
- [OpenAI](https://platform.openai.com/docs)
- [Stripe](https://stripe.com/docs)

### Architecture

- Architecture MVVM
- Provider pour le state management
- Hive pour le stockage local
- Supabase pour le backend

---

## 🤝 Contribuer

1. Fork le projet
2. Créer une branche feature
3. Commit avec des messages clairs
4. Pousser vers la branche
5. Ouvrir une Pull Request

**Convention de commit :**
- `feat(scope): description` - Nouvelle fonctionnalité
- `fix(scope): description` - Correction de bug
- `docs(scope): description` - Documentation
- `refactor(scope): description` - Refactoring
- `test(scope): description` - Tests

---

## ⚡ Problèmes Courants

### "Null safety error"

Assurez-vous d'utiliser Flutter >= 3.2.0 avec null safety activé.

### "Package not found"

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Unable to connect to Supabase"

Vérifiez que le Docker Supabase est lancé :
```bash
supabase status
```

---

Bon développement ! 🚀


