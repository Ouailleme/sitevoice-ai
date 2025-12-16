# 📊 Déployer les Schémas SQL - Guide Rapide

## ✅ Les Edge Functions sont Déployées !

Maintenant, il faut déployer les schémas SQL pour créer les tables.

---

## 🎯 Méthode Rapide : SQL Editor

### Étape 1 : Ouvrir le SQL Editor

1. Aller sur : **https://supabase.com/dashboard/project/dndjtcxypqnsyjzlzbxh**
2. Cliquer sur **SQL Editor** (menu gauche)
3. Cliquer sur **New Query**

### Étape 2 : Déployer le Schéma Principal (V1.5)

1. Dans Cursor, ouvrir le fichier : `supabase/schema.sql`
2. **Sélectionner TOUT** (Ctrl+A)
3. **Copier** (Ctrl+C)
4. **Coller** dans le SQL Editor de Supabase
5. Cliquer sur **Run** (en bas à droite)

⏳ Attendre 10-15 secondes...

✅ **Résultat** : "Success. No rows returned"

**Tables créées** :
- companies
- users
- clients
- products
- jobs
- job_items
- subscriptions
- sync_queue

### Étape 3 : Déployer le Schéma V2.0 (Webhooks)

1. Dans le SQL Editor, cliquer sur **New Query** (nouvelle query)
2. Dans Cursor, ouvrir : `supabase/schema_v2_webhooks.sql`
3. **Sélectionner TOUT** (Ctrl+A)
4. **Copier** (Ctrl+C)
5. **Coller** dans le SQL Editor
6. Cliquer sur **Run**

✅ **Résultat** : "Success. No rows returned"

**Tables supplémentaires** :
- webhook_configs
- webhook_logs
- erp_integrations
- sync_mappings

### Étape 4 : Vérifier

1. Cliquer sur **Table Editor** (menu gauche)
2. Vous devez voir **11 tables** au total

✅ **Si vous voyez les tables** → Schémas déployés avec succès !

---

## 🗄️ Créer les Storage Buckets (3 min)

### Dashboard → Storage → New Bucket

#### Bucket 1 : audio-recordings
- Name : `audio-recordings`
- Public : ✅ **OUI**
- File size limit : 50 MB
- **Create bucket**

#### Bucket 2 : photos
- Name : `photos`
- Public : ✅ **OUI**
- File size limit : 10 MB
- **Create bucket**

#### Bucket 3 : signatures
- Name : `signatures`
- Public : ❌ **NON**
- File size limit : 1 MB
- **Create bucket**

---

## 🔐 Configurer les Secrets (3 min)

### Dashboard → Settings → Edge Functions → Secrets

Ajouter ces 3 secrets :

#### 1. OPENAI_API_KEY
- Name : `OPENAI_API_KEY`
- Value : Votre clé OpenAI (commence par `sk-proj-...`)

#### 2. STRIPE_SECRET_KEY
- Name : `STRIPE_SECRET_KEY`
- Value : Votre clé Stripe (commence par `sk_test_...` ou `sk_live_...`)

#### 3. STRIPE_WEBHOOK_SECRET
- Name : `STRIPE_WEBHOOK_SECRET`
- Value : Votre webhook secret Stripe (commence par `whsec_...`)

---

## 📝 Créer le Fichier .env (2 min)

### Dans le Projet Flutter

1. Créer un fichier `.env` à la racine du projet
2. Copier le contenu ci-dessous :

```env
SUPABASE_URL=https://dndjtcxypqnsyjzlzbxh.supabase.co
SUPABASE_ANON_KEY=VOTRE_ANON_KEY_ICI
OPENAI_API_KEY=sk-proj-VOTRE_CLE_ICI
STRIPE_PUBLISHABLE_KEY=pk_test_VOTRE_CLE_ICI
```

### Récupérer les Clés

**Dashboard Supabase** → **Settings** → **API** :
- Copier `anon` `public` key
- Coller dans `.env` comme `SUPABASE_ANON_KEY`

---

## ✅ Checklist Finale

Avant de lancer l'app, vérifiez :

- [ ] Schéma SQL V1.5 déployé (11 tables visibles)
- [ ] Schéma SQL V2.0 déployé (webhooks)
- [ ] 3 Storage Buckets créés (audio-recordings, photos, signatures)
- [ ] 3 Secrets configurés (OpenAI, Stripe x2)
- [ ] Fichier `.env` créé avec les bonnes clés
- [ ] Edge Functions déployées (déjà fait ✅)

---

## 🚀 Lancer l'App

```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
flutter run
```

---

## 🎯 Ordre Recommandé

1. **SQL (5 min)** → Tables créées
2. **Storage (3 min)** → Buckets prêts
3. **Secrets (3 min)** → IA fonctionnelle
4. **`.env` (2 min)** → App configurée
5. **`flutter run`** → 🎉 TEST !

---

**Commencez par le SQL maintenant !** 

Dashboard → SQL Editor → Copier/Coller `schema.sql` → Run 🚀

