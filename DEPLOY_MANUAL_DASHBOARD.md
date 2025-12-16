# 🖱️ Déploiement Manuel via Dashboard Supabase

## Guide Pas-à-Pas (Sans CLI) - 30 Minutes

---

## ✅ Étape 1 : Créer le Projet (5 min)

### A. Créer un Compte Supabase

1. Aller sur : **https://supabase.com**
2. **Start your project** → **Sign Up**
3. Utiliser Google ou Email

### B. Créer un Nouveau Projet

1. **New Project**
2. Remplir :
   - **Organization** : Créer si besoin (nom de votre entreprise)
   - **Name** : `SiteVoice AI`
   - **Database Password** : (IMPORTANT - le noter quelque part)
   - **Region** : `Europe West (Ireland)`
   - **Pricing Plan** : Free (suffisant pour commencer)
3. **Create new project**

⏳ **Attendre 2-3 minutes** que le projet se crée...

---

## ✅ Étape 2 : Copier les Clés API (2 min)

### Dans le Dashboard

1. Cliquer sur **Settings** (icône engrenage en bas à gauche)
2. **API** dans le menu
3. **Copier** :
   - `Project URL` : `https://abcdefgh.supabase.co`
   - `anon public` key : `eyJhbGc...`
   - `service_role` key : `eyJhbGc...` (secret)

### Créer le fichier `.env`

Dans le projet, créer un fichier `.env` :

```env
SUPABASE_URL=https://VOTRE_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...VOTRE_ANON_KEY...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...VOTRE_SERVICE_ROLE_KEY...

OPENAI_API_KEY=sk-proj-...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

---

## ✅ Étape 3 : Déployer le Schéma SQL (10 min)

### A. Schéma Principal V1.5

1. **SQL Editor** (menu gauche) → **New Query**
2. Dans Cursor, ouvrir `supabase/schema.sql`
3. **Ctrl+A** → **Ctrl+C** (tout copier)
4. **Coller** dans le SQL Editor
5. **Run** (bouton en bas à droite)

⏳ Attendre ~30 secondes...

✅ **Résultat** : Message de succès

### B. Schéma V2.0 (Webhooks)

1. **SQL Editor** → **New Query** (nouvelle query)
2. Dans Cursor, ouvrir `supabase/schema_v2_webhooks.sql`
3. **Ctrl+A** → **Ctrl+C**
4. **Coller** dans le SQL Editor
5. **Run**

✅ **Résultat** : 4 tables supplémentaires créées

### Vérifier

1. **Table Editor** (menu gauche)
2. Vous devez voir :
   - companies
   - users
   - clients
   - products
   - jobs
   - job_items
   - sync_queue
   - webhook_configs
   - webhook_logs
   - erp_integrations
   - sync_mappings

✅ **Total** : 11 tables visibles

---

## ✅ Étape 4 : Créer les Storage Buckets (5 min)

### Dans le Dashboard

1. **Storage** (menu gauche)
2. **Create a new bucket**

### Bucket 1 : audio-recordings

- **Name** : `audio-recordings`
- **Public bucket** : ✅ **Oui**
- **File size limit** : 50 MB
- **Allowed MIME types** : Laisser vide (tous)
- **Create bucket**

### Bucket 2 : photos

- **Name** : `photos`
- **Public bucket** : ✅ **Oui**
- **File size limit** : 10 MB
- **Create bucket**

### Bucket 3 : signatures

- **Name** : `signatures`
- **Public bucket** : ❌ **Non**
- **File size limit** : 1 MB
- **Create bucket**

✅ **Résultat** : 3 buckets visibles dans Storage

---

## ✅ Étape 5 : Tester l'Application (5 min)

### Lancer l'App Flutter

```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
flutter run
```

### Premier Test

1. **Signup** : Créer un compte
   - Email : test@example.com
   - Mot de passe : Test1234!
   - Nom : Test User
   - Entreprise : Test Company

2. **Enregistrer** un vocal test (dire n'importe quoi pendant 10 secondes)

3. **Vérifier dans Supabase** :
   - **Table Editor** → `jobs`
   - Vous devez voir 1 ligne avec votre job

✅ **Si ça marche** : Backend configuré avec succès !

---

## ⚠️ Limitations SANS Edge Functions

### Ce qui FONCTIONNE ✅
- Enregistrement audio
- Sauvegarde locale (Hive)
- Synchronisation vers Supabase
- GPS
- Photos
- Signature
- UI complète

### Ce qui NE fonctionne PAS (pour l'instant) ❌
- Transcription Whisper
- Extraction GPT-4o
- Webhooks automatiques
- TTS Conversationnel

**Solution** : Installer Node.js + Supabase CLI pour déployer les Edge Functions

---

## 🎯 Pour Avoir l'IA (Whisper + GPT-4o)

Il faut **obligatoirement** déployer les Edge Functions.

### Options :

#### Option 1 : Installer Node.js Correctement
Voir `FIX_NODEJS_WINDOWS.md`

#### Option 2 : Utiliser Docker
```powershell
# Si Docker est installé
docker run -it supabase/cli supabase functions deploy
```

#### Option 3 : GitHub Actions (CI/CD)
Pousser le code sur GitHub et configurer le déploiement auto.

Docs : https://supabase.com/docs/guides/functions/deploy

---

## 📊 État Actuel

| Composant | Statut | Méthode |
|-----------|--------|---------|
| **Code Flutter** | ✅ 100% | Développé |
| **Modèles JSON** | ✅ Générés | build_runner |
| **Schéma SQL** | 🟡 À déployer | Dashboard SQL Editor |
| **Storage** | 🟡 À créer | Dashboard Storage |
| **Edge Functions** | 🔴 Nécessite CLI | CLI ou GitHub |
| **App Mobile** | ✅ Prête | flutter run |

---

## 🎬 Action Immédiate

**CHOIX 1** : Déployer le minimum pour tester l'UI
→ Suivre ce guide (étapes 1-5)

**CHOIX 2** : Régler Node.js pour tout avoir
→ Voir `FIX_NODEJS_WINDOWS.md`

---

## 📞 Besoin d'Aide ?

Tous les guides sont dans le projet :
- `FIX_NODEJS_WINDOWS.md` - Fix Node.js
- `INSTALL_SUPABASE_CLI.md` - Installation CLI
- `ALTERNATIVE_DEPLOYMENT.md` - Alternatives
- `QUICK_START.md` - Guide rapide

---

**Commencez maintenant** : Déployez le SQL via le Dashboard (Étape 3) ! 🚀


