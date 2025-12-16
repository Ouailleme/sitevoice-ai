# 🔧 Déploiement Manuel (Sans CLI) - SiteVoice AI V2.0

Si vous ne pouvez pas installer Supabase CLI, voici comment déployer manuellement via le Dashboard.

---

## 📊 Étape 1 : Déploiement SQL

### Via SQL Editor

1. Aller sur https://supabase.com → Votre Projet
2. **SQL Editor** (menu gauche)
3. **New Query**

#### A. Schéma Principal V1.5

Copier-coller le contenu de `supabase/schema.sql` et **Run**

#### B. Schéma V2.0 (Webhooks)

Copier-coller le contenu de `supabase/schema_v2_webhooks.sql` et **Run**

**Résultat attendu** :
- ✅ 15 tables créées
- ✅ RLS policies actives
- ✅ Triggers configurés

---

## ⚡ Étape 2 : Edge Functions

### Via Dashboard (Limitations)

**Note** : Le Dashboard Supabase ne permet pas de déployer des Edge Functions directement.

**Solutions** :

#### Option 1 : Installer juste le CLI (recommandé)
```powershell
npm install -g supabase
supabase link --project-ref YOUR_REF
supabase functions deploy process-audio --no-verify-jwt
```

#### Option 2 : GitHub Actions (CI/CD)

Créer un workflow GitHub qui déploie automatiquement.

Voir : https://supabase.com/docs/guides/functions/deploy-from-github

#### Option 3 : API REST (Avancé)

Utiliser l'API Supabase Management pour déployer.

Voir : https://supabase.com/docs/reference/api

---

## 💾 Étape 3 : Storage Buckets

### Création Manuelle (Simple)

1. **Storage** → **Create Bucket**

#### Bucket 1 : audio-recordings
- Name : `audio-recordings`
- Public : ✅ Yes
- File size limit : 50 MB
- Allowed MIME types : `audio/mp4, audio/m4a, audio/mpeg`

#### Bucket 2 : photos
- Name : `photos`
- Public : ✅ Yes
- File size limit : 10 MB
- Allowed MIME types : `image/jpeg, image/png`

#### Bucket 3 : signatures
- Name : `signatures`
- Public : ❌ No (Private)
- File size limit : 1 MB
- Allowed MIME types : `image/png, image/svg+xml`

---

## 🔐 Étape 4 : Secrets (Variables d'Environnement)

### Via Dashboard

**Project Settings** → **Edge Functions** → **Secrets** → **Add Secret**

Ajouter :
1. `OPENAI_API_KEY` = `sk-...`
2. `STRIPE_SECRET_KEY` = `sk_...`
3. `STRIPE_WEBHOOK_SECRET` = `whsec_...`

---

## ⏰ Étape 5 : Cron Job (Webhook Dispatcher)

### Via Database Webhooks (Alternative)

Si pas de Cron Job disponible, utiliser **Database Webhooks** :

1. **Database** → **Webhooks** → **Create Webhook**
2. Configuration :
   - Table : `webhook_logs`
   - Events : `INSERT`
   - Type : `HTTP Request`
   - Method : `POST`
   - URL : `https://YOUR_PROJECT.supabase.co/functions/v1/webhook-dispatcher`

---

## 📱 Étape 6 : Configuration App Flutter

### Fichier `.env`

Créer à la racine du projet :

```env
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
OPENAI_API_KEY=sk-proj-...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

**Récupérer les clés** :
- Dashboard → **Settings** → **API**

---

## 🧪 Test Sans Backend

### Mode Local Uniquement

L'app Flutter fonctionne en **Offline-First**, donc vous pouvez tester localement :

```powershell
flutter run
```

**Fonctionnalités testables sans backend** :
- ✅ Enregistrement audio
- ✅ Sauvegarde locale (Hive)
- ✅ UI complète
- ✅ GPS
- ✅ Photos
- ✅ Signature

**Fonctionnalités nécessitant le backend** :
- ❌ Transcription Whisper
- ❌ Extraction GPT-4o
- ❌ Synchronisation cloud
- ❌ Webhooks

---

## 🎯 Recommandation Finale

**Pour un déploiement complet, l'installation du CLI est FORTEMENT recommandée.**

**Installation rapide** :
```powershell
# 1. Installer Node.js (si pas encore fait)
# Télécharger : https://nodejs.org/

# 2. Installer Supabase CLI
npm install -g supabase

# 3. Vérifier
supabase --version

# 4. Lier le projet
supabase link --project-ref YOUR_PROJECT_REF

# 5. Déployer
.\scripts\deploy_backend.ps1
```

**Temps total** : ~15 minutes

---

## 📚 Ressources

- [Supabase CLI Docs](https://supabase.com/docs/guides/cli)
- [Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Installation Node.js](https://nodejs.org/)

---

**Besoin d'aide ?** Consultez `QUICK_START.md` ou `DEPLOYMENT_CHECKLIST.md`


