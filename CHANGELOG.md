# 📝 Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

---

## [Unreleased]

### À Venir
- 🎤 Enregistrement audio vocal
- 🗣️ Transcription via Whisper AI
- 🤖 Extraction de données structurées via GPT-4
- 📄 Génération de PDF de facturation
- 📴 Mode offline complet avec Hive
- 💳 Intégration Stripe pour abonnements

---

## [1.0.0] - 2025-12-16

### ✨ Ajouté
- **Authentification**
  - Inscription et connexion via Supabase
  - Gestion des sessions
  - Redirection automatique si authentifié
  - Logout fonctionnel

- **Gestion des Clients**
  - CRUD complet (Créer, Lire, Modifier, Supprimer)
  - Barre de recherche en temps réel
  - Filtrage par nom, email, téléphone
  - Interface moderne avec cartes
  - Pull-to-refresh
  - États vides personnalisés

- **Gestion des Produits**
  - CRUD complet
  - Barre de recherche en temps réel
  - Filtrage par nom, référence, catégorie
  - Affichage du prix et de l'unité
  - Interface moderne avec badges de catégorie
  - Pull-to-refresh

- **Gestion des Jobs (Interventions)**
  - Liste des interventions
  - Affichage des statuts avec badges colorés
  - Recherche par statut et transcription
  - Formatage des dates en français
  - Interface moderne

- **Dashboard (Home Screen)**
  - Statistiques en temps réel (clients, produits, jobs)
  - Cartes de statistiques interactives
  - Bouton d'enregistrement principal
  - Actions rapides
  - Pull-to-refresh
  - Design moderne avec dégradés

- **Navigation**
  - Bottom Navigation Bar avec 5 onglets
  - Navigation fluide avec IndexedStack
  - Conservation de l'état des pages
  - Icons actifs/inactifs
  - Design moderne avec bordures arrondies

- **UI/UX**
  - Thème Material 3 complet
  - Palette de couleurs cohérente
  - Typographie Google Fonts (Inter)
  - Animations fluides
  - Ombres et élévations
  - Coins arrondis partout

- **Base de Données**
  - Schema PostgreSQL complet
  - Row Level Security (RLS) activé
  - Isolation des données par entreprise
  - Index pour performance
  - Migrations versionnées

- **Documentation**
  - README principal complet
  - Guide des bonnes pratiques Supabase
  - Workflow Git documenté
  - Guide des migrations
  - Scripts d'automatisation

### 🔒 Sécurité
- Row Level Security sur toutes les tables
- Fonction `get_user_company_id()` sécurisée
- Validation des données côté client et serveur
- Gestion des permissions

### ⚡ Performance
- Index sur toutes les foreign keys
- Index sur les colonnes de recherche
- Lazy loading des données
- Optimisation des requêtes Supabase

### 🐛 Corrections
- Résolution du problème de cache Supabase (PGRST204)
- Correction de la redirection après signup
- Correction de la gestion d'erreur dans les formulaires
- Amélioration des messages d'erreur

### 📚 Documentation
- `README.md` - Documentation principale
- `BEST_PRACTICES_SUPABASE.md` - Guide Supabase
- `GIT_WORKFLOW.md` - Convention Git
- `supabase/README.md` - Documentation BDD
- `supabase/migrations/README.md` - Guide migrations

### 🛠️ Infrastructure
- Structure de migrations
- Scripts PowerShell d'automatisation
- .gitignore complet
- Health check SQL

---

## [0.1.0] - 2025-12-15

### ✨ Initial
- Création du projet Flutter
- Configuration de base Supabase
- Structure MVVM
- Écrans d'authentification basiques

---

## Format des Versions

### Types de Changements
- `✨ Ajouté` - Nouvelles fonctionnalités
- `🔄 Modifié` - Changements dans les fonctionnalités existantes
- `❌ Déprécié` - Fonctionnalités bientôt supprimées
- `🗑️ Supprimé` - Fonctionnalités supprimées
- `🐛 Corrections` - Corrections de bugs
- `🔒 Sécurité` - Vulnérabilités corrigées
- `⚡ Performance` - Améliorations de performance
- `📚 Documentation` - Changements dans la documentation

---

## Liens

- [Unreleased]: https://github.com/ton-username/sitevoice-ai/compare/v1.0.0...HEAD
- [1.0.0]: https://github.com/ton-username/sitevoice-ai/releases/tag/v1.0.0
- [0.1.0]: https://github.com/ton-username/sitevoice-ai/releases/tag/v0.1.0

