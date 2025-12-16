# 🎙️ **SiteVoice AI**

Application mobile Flutter pour techniciens BTP permettant la création de rapports d'intervention et de factures par commande vocale.

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-412991?logo=openai)

</div>

---

## 📋 **Table des Matières**

- [Fonctionnalités](#-fonctionnalités)
- [Technologies](#-technologies)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Développement](#-développement)
- [Base de Données](#-base-de-données)
- [Documentation](#-documentation)

---

## ✨ **Fonctionnalités**

### **Déjà Implémenté** ✅

- 🔐 **Authentification** (Signup / Login via Supabase)
- 👥 **Gestion des Clients** (CRUD complet avec recherche)
- 📦 **Gestion des Produits** (CRUD complet avec recherche)
- 📋 **Gestion des Jobs** (Liste des interventions)
- 🏠 **Dashboard Moderne** (Statistiques en temps réel)
- 📱 **Bottom Navigation** (Navigation fluide entre sections)
- 🎨 **Material 3 Design** (UI moderne et cohérente)
- 🔍 **Recherche en Temps Réel** (Clients et Produits)
- 🔄 **Pull-to-Refresh** (Actualisation des données)
- 🔒 **Row Level Security** (Isolation des données par entreprise)

### **À Venir** 🚧

- 🎤 **Enregistrement Audio** (Commandes vocales)
- 🗣️ **Transcription Whisper** (Speech-to-Text)
- 🤖 **Extraction IA GPT-4** (Données structurées depuis vocal)
- 📄 **Génération PDF** (Factures et devis)
- 📴 **Mode Offline** (Hive + Queue de synchronisation)
- 💳 **Stripe Integration** (Abonnements SaaS)
- 📊 **Analytics** (Sentry + Statistiques avancées)

---

## 🛠️ **Technologies**

### **Frontend**
- **Flutter 3.x** - Framework mobile cross-platform
- **Provider** - State management
- **GoRouter** - Navigation déclarative
- **Google Fonts** - Typographie (Inter)
- **Supabase Flutter** - Client Supabase

### **Backend**
- **Supabase** - Backend-as-a-Service
  - PostgreSQL - Base de données
  - Row Level Security - Sécurité au niveau des lignes
  - Realtime - Mises à jour en temps réel
  - Storage - Stockage fichiers audio
  - Edge Functions - Serverless functions

### **IA**
- **OpenAI Whisper** - Transcription audio
- **OpenAI GPT-4** - Extraction de données structurées
- **JSON Mode** - Sorties strictement structurées

### **Storage Local**
- **Hive** - Base de données locale NoSQL
- **Offline-First** - Synchronisation différée

---

## 🏗️ **Architecture**

### **MVVM Strict**

```
lib/
├── core/
│   ├── constants/          # Constantes globales
│   ├── routes/            # Configuration routing
│   ├── theme/             # Thème Material 3
│   ├── animations/        # Widgets animés
│   └── services/          # Services transversaux
├── data/
│   ├── models/            # Data models (JSON serializable)
│   ├── repositories/      # Accès données (API + Local)
│   └── services/          # Services techniques (Auth, Audio, Sync)
├── domain/
│   ├── entities/          # Business entities
│   └── use_cases/         # Business logic
└── presentation/
    ├── screens/           # Pages de l'app
    ├── widgets/           # Composants réutilisables
    └── view_models/       # ViewModels (Provider)
```

### **Principes**

- ✅ **Offline-First** : L'app fonctionne sans connexion
- ✅ **RLS** : Données isolées par entreprise
- ✅ **Error Handling** : Try/catch partout + Telemetry
- ✅ **Type Safety** : Pas de `dynamic` sauf exception
- ✅ **Clean Code** : Variables explicites, commentaires en français

---

## 🚀 **Installation**

### **Prérequis**

- Flutter SDK 3.0+
- Android Studio / Xcode
- Git
- Compte Supabase
- Compte OpenAI (API Key)

### **1. Cloner le Projet**

```bash
git clone https://github.com/ton-username/sitevoice-ai.git
cd sitevoice-ai
```

### **2. Installer les Dépendances**

```bash
flutter pub get
```

### **3. Configurer Supabase**

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Copier l'URL et la clé anonyme
3. Exécuter les migrations :
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_rls_policies.sql`

### **4. Configurer les Variables d'Environnement**

```dart
// lib/core/constants/app_constants.dart
static const String supabaseUrl = 'TON_URL_SUPABASE';
static const String supabaseAnonKey = 'TA_CLE_ANON_SUPABASE';
static const String openaiApiKey = 'TA_CLE_OPENAI';
```

⚠️ **En production**, utiliser des variables d'environnement sécurisées.

### **5. Lancer l'App**

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Build APK
flutter build apk --release
```

---

## ⚙️ **Configuration**

### **Supabase**

Voir [supabase/README.md](supabase/README.md) pour :
- Configuration de la base de données
- Migrations
- RLS Policies
- Health checks

### **OpenAI**

```dart
// lib/data/services/openai_service.dart
static const String model = 'gpt-4o';
static const String whisperModel = 'whisper-1';
```

---

## 💻 **Développement**

### **Structure des Commits**

Suivre [GIT_WORKFLOW.md](GIT_WORKFLOW.md) :

```bash
feat(clients): ajout recherche par téléphone
fix(auth): correction redirect après signup
db(supabase): ajout colonnes d'audit
```

### **Scripts Utiles**

```powershell
# Build et installer l'APK
.\scripts\build-and-install.ps1

# Commit rapide avec convention
.\scripts\quick-commit.ps1
```

### **Commandes Flutter**

```bash
# Analyser le code
flutter analyze

# Formater le code
flutter format .

# Tester
flutter test

# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release
```

---

## 🗄️ **Base de Données**

### **Tables Principales**

| Table | Description |
|-------|-------------|
| `companies` | Entreprises clientes (SaaS multi-tenant) |
| `users` | Utilisateurs/Techniciens |
| `clients` | Carnet d'adresses clients |
| `products` | Catalogue produits/services |
| `jobs` | Interventions/Chantiers |
| `job_items` | Lignes de facturation |

### **Migrations**

```bash
# Voir la liste des migrations
cat supabase/migrations/README.md

# Créer une nouvelle migration
cp supabase/migrations/TEMPLATE.sql supabase/migrations/003_ma_migration.sql

# Appliquer via SQL Editor Supabase
```

### **Health Check**

```sql
-- Exécuter dans SQL Editor
-- Fichier: supabase/health_check.sql
```

---

## 📚 **Documentation**

### **Guides**

- 📖 [Bonnes Pratiques Supabase](BEST_PRACTICES_SUPABASE.md)
- 🔄 [Workflow Git](GIT_WORKFLOW.md)
- 🗄️ [Documentation Supabase](supabase/README.md)
- 📁 [Guide des Migrations](supabase/migrations/README.md)

### **Architecture**

- 🏗️ [Architecture MVVM](.cursorrules)
- 🎨 [Thème Material 3](lib/core/theme/app_theme.dart)
- 🔐 [Authentification](lib/data/services/auth_service.dart)

### **Ressources Externes**

- [Documentation Flutter](https://docs.flutter.dev/)
- [Documentation Supabase](https://supabase.com/docs)
- [Documentation OpenAI](https://platform.openai.com/docs)

---

## 🧪 **Tests**

```bash
# Lancer tous les tests
flutter test

# Tests unitaires
flutter test test/unit/

# Tests d'intégration
flutter test test/integration/

# Coverage
flutter test --coverage
```

---

## 🚀 **Déploiement**

### **Android (Google Play)**

```bash
# Build AAB (Android App Bundle)
flutter build appbundle --release

# Upload sur Google Play Console
```

### **iOS (App Store)**

```bash
# Build IPA
flutter build ipa --release

# Upload via Xcode ou Transporter
```

---

## 📝 **Changelog**

Voir [CHANGELOG.md](CHANGELOG.md) pour l'historique des versions.

---

## 📄 **Licence**

Ce projet est sous licence privée. Tous droits réservés.

---

## 👥 **Équipe**

- **Lead Developer** : [Ton Nom]
- **UI/UX Designer** : [Nom]
- **Backend** : Supabase
- **IA** : OpenAI

---

## 🆘 **Support**

Pour toute question ou problème :

1. 📖 Consulter la [documentation](BEST_PRACTICES_SUPABASE.md)
2. 🐛 Ouvrir une [issue](https://github.com/ton-username/sitevoice-ai/issues)
3. 💬 Contacter l'équipe

---

## ⭐ **Roadmap**

### **v1.0.0** (Actuel)
- ✅ Authentification
- ✅ CRUD Clients/Produits/Jobs
- ✅ Dashboard moderne
- ✅ Recherche

### **v1.1.0** (Prochain)
- 🎤 Enregistrement audio
- 🗣️ Transcription Whisper
- 🤖 Extraction GPT-4

### **v2.0.0** (Futur)
- 📄 Génération PDF
- 💳 Stripe Integration
- 📴 Mode Offline complet
- 📊 Analytics avancées

---

<div align="center">

**Fait avec ❤️ pour les techniciens BTP**

</div>
