# 📊 Résumé Technique - SiteVoice AI

## 🎯 Vision Produit

**SiteVoice AI** est une application mobile SaaS permettant aux techniciens BTP de dicter leurs rapports d'intervention au lieu de les saisir manuellement. L'IA transcrit, extrait et structure les données pour automatiser la facturation.

### Problème Résolu

- ✅ Plus besoin de saisir les rapports le soir
- ✅ Gain de temps : 30 min → 2 min par intervention
- ✅ Zéro oubli de matériel ou temps passé
- ✅ Facturation automatique et précise

### Marché Cible

- **Utilisateurs primaires** : Plombiers, électriciens, chauffagistes
- **Taille de marché** : 1.5M d'artisans en France
- **Prix** : 29€/mois par technicien
- **Potentiel** : 10-50K€ MRR après 1 an

---

## 🏗️ Architecture Technique

### Stack Technologique

| Composant | Technologie | Justification |
|-----------|-------------|---------------|
| **Frontend Mobile** | Flutter | Cross-platform (iOS/Android), performances natives |
| **Backend** | Supabase | Serverless, PostgreSQL, Auth intégré, RLS natif |
| **Base de Données** | PostgreSQL | Relationnel, robuste, RLS pour la sécurité |
| **Storage** | Supabase Storage | Stockage fichiers audio, intégré |
| **Edge Functions** | Deno/TypeScript | Serverless, proche des utilisateurs |
| **IA Transcription** | OpenAI Whisper | Meilleure précision du marché |
| **IA Extraction** | OpenAI GPT-4o | JSON Mode, RAG anti-hallucination |
| **Paiements** | Stripe | Standard industrie, webhooks fiables |
| **State Management** | Provider | Simple, performant, officiellement recommandé |
| **Local Storage** | Hive | NoSQL rapide, parfait pour Offline-First |

### Philosophie : **Offline-First**

L'app fonctionne **100% sans internet** :
1. Enregistrement audio → Stockage local
2. Création du job → Queue de sync Hive
3. Dès que le réseau revient → Upload automatique
4. Edge Function traite l'audio → Résultat stocké
5. L'app récupère les données traitées

---

## 📁 Structure du Projet

```
sitevoice-ai/
├── lib/
│   ├── core/
│   │   ├── constants/          # Constantes globales
│   │   ├── errors/             # Exceptions personnalisées
│   │   ├── routes/             # Configuration GoRouter
│   │   └── utils/              # Helpers
│   ├── data/
│   │   ├── models/             # Modèles de données (JSON)
│   │   ├── repositories/       # Accès données (API + Local)
│   │   └── services/           # Services métier
│   │       ├── auth_service.dart
│   │       ├── audio_service.dart
│   │       ├── sync_service.dart
│   │       └── payment_service.dart
│   ├── domain/
│   │   ├── entities/           # Entités métier
│   │   └── use_cases/          # Logique métier
│   ├── presentation/
│   │   ├── screens/            # Écrans de l'app
│   │   ├── widgets/            # Composants réutilisables
│   │   └── view_models/        # ViewModels (MVVM)
│   └── main.dart
├── supabase/
│   ├── schema.sql              # Schéma PostgreSQL
│   ├── config.toml             # Configuration Supabase
│   └── functions/
│       ├── process-audio/      # Whisper + GPT-4o
│       ├── create-subscription/ # Stripe Payment
│       └── stripe-webhook/     # Webhooks Stripe
├── android/
├── ios/
├── pubspec.yaml
├── .cursorrules                # Règles pour l'IA
└── README.md
```

---

## 🔐 Sécurité

### Row Level Security (RLS)

Chaque table a des policies RLS qui garantissent que :
- Un utilisateur ne voit **que les données de son entreprise**
- Un technicien ne peut **modifier que ses propres jobs**
- Un admin peut **gérer toute l'entreprise**

### Authentification

- Supabase Auth (JWT)
- Email/Password + Google OAuth
- Refresh automatique des tokens
- Session persistée localement

### Données Sensibles

- Clés API stockées en variables d'environnement
- Jamais de secrets dans le code
- Audio uploadé en HTTPS
- RLS actif sur toutes les tables

---

## 🧠 Intelligence Artificielle

### Pipeline de Traitement

1. **Upload Audio** → Supabase Storage
2. **Edge Function** `process-audio` déclenchée
3. **Transcription** → OpenAI Whisper
4. **Contexte RAG** → Récupération clients/produits existants
5. **Extraction** → GPT-4o en JSON Mode
6. **Score de confiance** → 0.0 à 1.0
7. **Stockage** → Base de données
8. **Notification** → App mobile

### Anti-Hallucination (RAG)

Le prompt GPT-4o reçoit :
- **Liste des clients existants** (noms, adresses)
- **Catalogue produits** (références, noms, prix)

Cela force l'IA à **matcher** au lieu d'inventer.

### JSON Mode

GPT-4o est configuré avec `response_format: json_object`, garantissant une sortie structurée valide.

---

## 💰 Modèle Économique

### Pricing

- **29€/mois par technicien**
- **7 jours d'essai gratuit**
- Paiement par carte (Stripe)

### Coûts Variables

| Service | Coût unitaire | Pour 1000 jobs/mois |
|---------|---------------|---------------------|
| Whisper (3 min/audio) | 0.006$/min | ~18$ |
| GPT-4o (extraction) | 0.01$/requête | ~10$ |
| Supabase | Gratuit jusqu'à 500MB DB | 0$ |
| Stripe | 1.4% + 0.25€ | ~58€ |
| **TOTAL** | | **~86€** |

**Marge brute** : 29€ × 1000 - 86€ = **28,914€** (99.7%)

---

## 📊 Base de Données - Schéma Simplifié

```
companies
├── id (uuid)
├── name
├── subscription_status (trial/active/cancelled/expired)
└── subscription_ends_at

users
├── id (uuid, FK auth.users)
├── email
├── role (admin/tech)
└── company_id (FK companies)

clients
├── id (uuid)
├── company_id (FK companies)
├── name
└── address

products
├── id (uuid)
├── company_id (FK companies)
├── reference
├── name
└── unit_price

jobs (Interventions)
├── id (uuid)
├── company_id (FK companies)
├── created_by (FK users)
├── client_id (FK clients)
├── status (pending_audio/processing/review_needed/validated)
├── audio_url
├── transcription_text
├── ai_confidence_score
├── ai_extracted_data (jsonb)
└── synced_at

job_items (Lignes de facture)
├── id (uuid)
├── job_id (FK jobs)
├── product_id (FK products)
├── description
├── quantity
└── unit_price
```

---

## 🚀 Flux Utilisateur Principal

### 1. Enregistrement Vocal (2 min)

1. Technicien appuie sur le gros bouton micro 🎙️
2. Parle librement : *"Intervention chez M. Dupont, 12 rue de la Paix. J'ai changé le chauffe-eau, posé 2 radiateurs, et passé 3 heures sur place."*
3. Appuie sur "Terminer"

### 2. Traitement IA (30 secondes)

1. Audio uploadé en background
2. Whisper transcrit en texte
3. GPT-4o extrait :
   - Client : M. Dupont
   - Adresse : 12 rue de la Paix
   - Produits : Chauffe-eau, 2× Radiateur
   - Durée : 3 heures
4. Score de confiance calculé

### 3. Validation (1 min)

1. Technicien reçoit une notification
2. Ouvre l'écran de validation
3. Vérifie les données (pré-remplies)
4. Ajuste si nécessaire
5. Valide → Job prêt à facturer

**Total : 3-4 minutes vs 30+ minutes manuellement**

---

## 🎨 Design UX/UI

### Principes

1. **Minimaliste** : Gros bouton, peu de choix
2. **Industriel** : Couleurs sobres (bleu, gris)
3. **Touch-Friendly** : Éléments > 48×48dp
4. **Feedback immédiat** : Animations, confirmations
5. **Offline-First** : Toujours fonctionnel

### Écrans Principaux

| Écran | Description |
|-------|-------------|
| **Splash** | Logo + Loading |
| **Login** | Email/Password + Google |
| **Home** | Dashboard avec stats |
| **Record** | GROS bouton micro central |
| **Validation** | Formulaire pré-rempli par l'IA |
| **Jobs List** | Historique des interventions |
| **Settings** | Profil, abonnement, déconnexion |

---

## 🧪 Tests & Qualité

### Tests Unitaires

- Services (Auth, Audio, Sync, Payment)
- ViewModels (logique métier)
- Modèles (sérialisation JSON)

### Tests d'Intégration

- Flow complet : Enregistrement → Traitement → Validation
- Sync offline → online
- Paiement Stripe

### Linting

- `flutter analyze` : 0 erreur
- `analysis_options.yaml` strict
- Format automatique avec `dart format`

---

## 📈 Métriques à Suivre (Post-Lancement)

### Product Metrics

- **Taux d'activation** : % utilisateurs qui font leur 1er enregistrement
- **Rétention D7/D30** : % utilisateurs actifs après 7/30 jours
- **Temps moyen par rapport** : Mesurer le gain de temps
- **Taux de validation automatique** : % de jobs validés sans modification

### Business Metrics

- **MRR** (Monthly Recurring Revenue)
- **Churn Rate** : % désabonnements/mois
- **CAC** (Customer Acquisition Cost)
- **LTV** (Lifetime Value)

### Technical Metrics

- **Uptime** : > 99.9%
- **Latency Edge Functions** : < 2s
- **Taux de succès IA** : > 95%
- **Crash-free rate** : > 99.5%

---

## 🔮 Roadmap Future

### V1.1 (Mois 2)

- [ ] Export PDF des interventions
- [ ] Templates de rapports personnalisables
- [ ] Signature électronique client

### V1.2 (Mois 3)

- [ ] Mode hors-ligne amélioré (maps)
- [ ] Photos avant/après
- [ ] Planning d'interventions

### V2.0 (Mois 6)

- [ ] Facturation automatique (Stripe Invoicing)
- [ ] Intégration comptable (Pennylane, Quickbooks)
- [ ] Multi-langues (Anglais, Espagnol)

---

## 👥 Équipe Recommandée

### Phase MVP (1-2 personnes)

- **Full-Stack Developer** : Flutter + Supabase
- OU : **Solopreneur** avec compétences polyvalentes

### Phase Scale (3-5 personnes)

- **Mobile Lead** : Flutter expert
- **Backend/DevOps** : Supabase, Edge Functions
- **Product Manager** : Roadmap, user research
- **Designer UI/UX** : Prototypes, tests utilisateurs
- **Support Client** : Onboarding, FAQ

---

## 💡 Points Clés de Succès

1. **Offline-First** → Fonctionne partout (caves, chantiers)
2. **Rapidité** → Rapport en 2 min au lieu de 30 min
3. **Fiabilité IA** → RAG + validation humaine
4. **Simplicité** → 1 bouton pour démarrer
5. **Prix juste** → 29€/mois = 1 intervention économisée
6. **Support réactif** → Artisans = pas tech-savvy

---

## 🎓 Leçons Apprises

### Ce qui marche

✅ **Architecture Serverless** : 0 maintenance, scalabilité automatique  
✅ **Flutter** : Vraiment cross-platform, hot reload magique  
✅ **Supabase** : Backend en 1h, RLS puissant  
✅ **RAG** : Indispensable pour éviter les hallucinations IA

### Ce qui pourrait être amélioré

⚠️ **Compression audio** : Prévoir sur device avant upload  
⚠️ **Cache** : Ajouter un layer de cache pour les produits/clients  
⚠️ **Tests E2E** : Automatiser avec integration_test de Flutter

---

## 📞 Support Technique

En cas de problème :

1. **Logs Supabase** : Dashboard → Logs → Edge Functions
2. **Logs Flutter** : `flutter logs` ou DevTools
3. **Sentry** : Si activé, voir les crash reports
4. **Stripe Dashboard** : Pour les problèmes de paiement

---

## 📄 Licence

Propriétaire - © 2024 SiteVoice AI

---

**Version du document** : 1.0  
**Dernière mise à jour** : Décembre 2024  
**Statut** : MVP Prêt à Déployer 🚀


