# 🎤 SiteVoice AI

[![Build APK](https://github.com/Ouailleme/sitevoice-ai/actions/workflows/build-apk.yml/badge.svg)](https://github.com/Ouailleme/sitevoice-ai/actions/workflows/build-apk.yml)

**L'Assistant Vocal pour Techniciens Terrain** - Voice-to-Action Reporting

---

## 🎯 **Description**

App mobile Flutter pour techniciens BTP. Enregistrement vocal → Transcription → Extraction Données (JSON) → Facturation automatique.

### **Stack Technique**
- **Frontend** : Flutter (Dernière version stable)
- **Backend** : Supabase (Postgres, Edge Functions, Storage, Auth)
- **IA** : OpenAI (Whisper, GPT-4o)
- **State** : Provider
- **Storage** : Hive (Offline-First)

---

## 🚀 **Quick Start**

### **1. Télécharger l'APK**

Deux options :

#### **Option A : GitHub Actions** (Recommandé)
1. Va sur [Actions](https://github.com/Ouailleme/sitevoice-ai/actions)
2. Clique sur le dernier workflow ✅
3. Scroll en bas → Section "Artifacts"
4. Télécharge `app-debug` ou `app-release`

#### **Option B : Build Local** (Nécessite Linux/Mac ou WSL)
```bash
flutter pub get
flutter build apk --debug
```

### **2. Installer**

```bash
adb install app-debug.apk
```

### **3. Configurer Supabase**

Crée un projet sur [supabase.com](https://supabase.com) et :

1. **Exécute les migrations** :
   ```bash
   # Dans le SQL Editor de Supabase
   supabase/migrations/001_initial_schema.sql
   supabase/migrations/002_rls_policies.sql
   ```

2. **Crée le bucket Storage** :
   ```sql
   INSERT INTO storage.buckets (id, name, public)
   VALUES ('audio-recordings', 'audio-recordings', false);
   ```

3. **Configure les variables** :
   - Copie `SUPABASE_URL` et `SUPABASE_ANON_KEY`
   - Mets-les dans `lib/core/constants/app_constants.dart`

---

## 📱 **Features**

### **✅ Implémentées**

- [x] 🔐 Authentification (Email/Password)
- [x] 👥 Gestion Clients (CRUD)
- [x] 📦 Gestion Produits (CRUD)
- [x] 📋 Gestion Jobs (Liste)
- [x] 🏠 Dashboard avec statistiques
- [x] 🔍 Recherche en temps réel
- [x] 🎨 UI Material 3 moderne
- [x] 📱 Bottom Navigation
- [x] 🌐 Multi-langue (FR, EN, ES)
- [x] 🎤 Services Audio (flutter_sound)
- [x] ☁️ Services Storage (Supabase)
- [x] 🤖 Services IA (Whisper + GPT-4)

### **🚧 En Cours - v1.1.0**

- [ ] 🎤 Enregistrement vocal complet
- [ ] 📤 Upload audio vers Supabase
- [ ] 🗣️ Transcription avec Whisper
- [ ] 🧠 Extraction données avec GPT-4
- [ ] ✅ Page validation job

### **📋 Roadmap - v1.2.0+**

- [ ] 📴 Mode Offline (Hive)
- [ ] 🔄 Synchronisation auto
- [ ] 📄 Génération PDF factures
- [ ] 📸 Photos & Signature
- [ ] 📍 Géolocalisation
- [ ] 🔔 Notifications push
- [ ] 📊 Analytics avancées

Voir [`ROADMAP.md`](ROADMAP.md) pour le plan complet.

---

## 🏗️ **Build & Déploiement**

### **GitHub Actions** (Automatique)

Chaque push vers `main` déclenche un build automatique :

1. ✅ Compile APK Debug + Release
2. ✅ Upload vers Artifacts
3. ✅ Disponible en téléchargement

Voir [`GITHUB_ACTIONS_GUIDE.md`](GITHUB_ACTIONS_GUIDE.md)

### **Build Local**

**⚠️ Windows** : Problème JDK connu ([voir SOLUTION_FINALE_JLINK.md](SOLUTION_FINALE_JLINK.md))

**✅ Linux/Mac** :
```bash
flutter build apk --release
```

**✅ WSL2** :
```bash
wsl --install
flutter build apk --release
```

---

## 📚 **Documentation**

| Document | Description |
|----------|-------------|
| [`ROADMAP.md`](ROADMAP.md) | Plan des 18 features (v1.1.0 → v2.0.0) |
| [`IMPLEMENTATION_GUIDE.md`](IMPLEMENTATION_GUIDE.md) | Guide pas à pas Audio & IA |
| [`AUDIO_IMPLEMENTATION_STATUS.md`](AUDIO_IMPLEMENTATION_STATUS.md) | État actuel implémentation (80%) |
| [`GITHUB_ACTIONS_GUIDE.md`](GITHUB_ACTIONS_GUIDE.md) | Build automatique avec CI/CD |
| [`SOLUTION_FINALE_JLINK.md`](SOLUTION_FINALE_JLINK.md) | 5 solutions problème Windows build |
| [`GIT_WORKFLOW.md`](GIT_WORKFLOW.md) | Conventions Git du projet |
| [`BEST_PRACTICES_SUPABASE.md`](BEST_PRACTICES_SUPABASE.md) | Bonnes pratiques Supabase |

---

## 🗂️ **Structure du Projet**

```
lib/
├── core/
│   ├── constants/          # Constantes globales
│   ├── errors/             # Custom exceptions
│   ├── routes/             # Navigation (go_router)
│   └── theme/              # Material 3 theme
├── data/
│   ├── models/             # Data models
│   ├── repositories/       # Accès données
│   └── services/           # Services (Auth, Audio, Storage, OpenAI)
├── presentation/
│   ├── screens/            # Pages de l'app
│   ├── widgets/            # Composants réutilisables
│   └── view_models/        # ViewModels (Provider)
└── main.dart

supabase/
├── migrations/             # Migrations SQL versionnées
├── functions/              # Edge Functions
└── *.sql                   # Scripts de maintenance

.github/
└── workflows/
    └── build-apk.yml       # CI/CD GitHub Actions
```

---

## 🤝 **Contribution**

### **Workflow**

```bash
# 1. Fork le projet
# 2. Crée une branche
git checkout -b feature/ma-feature

# 3. Commit
git commit -m "feat(scope): description"

# 4. Push
git push origin feature/ma-feature

# 5. Crée une Pull Request
```

### **Conventions**

- **Commits** : `type(scope): message` (voir [`GIT_WORKFLOW.md`](GIT_WORKFLOW.md))
- **Code** : Flutter best practices + Architecture MVVM
- **Tests** : Tests unitaires pour logique métier

---

## 📄 **License**

Propriétaire - Tous droits réservés

---

## 🆘 **Support**

- **Issues** : [GitHub Issues](https://github.com/Ouailleme/sitevoice-ai/issues)
- **Discussions** : [GitHub Discussions](https://github.com/Ouailleme/sitevoice-ai/discussions)
- **Email** : support@sitevoice.ai

---

## 📊 **Statut du Projet**

```
✅ Authentification       : 100%
✅ CRUD Clients           : 100%
✅ CRUD Produits          : 100%
✅ Liste Jobs             : 100%
✅ Dashboard              : 100%
✅ Services Audio/IA      : 100% (Code)
⏳ Intégration Audio      : 30% (En attente tests)
⏳ Mode Offline           : 0%
⏳ Génération PDF         : 0%

TOTAL : 65%
```

---

**🎉 Merci d'utiliser SiteVoice AI !**
