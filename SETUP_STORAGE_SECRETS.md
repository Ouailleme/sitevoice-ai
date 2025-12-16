# 🗄️ Configuration Storage & Secrets - Guide Rapide

## Étape 2/4 : Storage Buckets

### Accéder au Storage

**Lien direct** : https://supabase.com/dashboard/project/dndjtcxypqnsyjzlzbxh/storage/buckets

Ou : Dashboard → **Storage** (menu gauche)

---

### Bucket 1 : audio-recordings

1. Cliquer sur **New bucket**
2. Remplir :
   - **Name** : `audio-recordings`
   - **Public bucket** : ✅ **Cocher** (OUI)
   - **File size limit** : `50000000` (50 MB)
   - **Allowed MIME types** : Laisser vide
3. **Create bucket**

✅ Bucket créé

---

### Bucket 2 : photos

1. **New bucket** (encore)
2. Remplir :
   - **Name** : `photos`
   - **Public bucket** : ✅ **Cocher** (OUI)
   - **File size limit** : `10000000` (10 MB)
   - **Allowed MIME types** : Laisser vide
3. **Create bucket**

✅ Bucket créé

---

### Bucket 3 : signatures

1. **New bucket** (dernière fois)
2. Remplir :
   - **Name** : `signatures`
   - **Public bucket** : ❌ **NE PAS cocher** (NON)
   - **File size limit** : `1000000` (1 MB)
   - **Allowed MIME types** : Laisser vide
3. **Create bucket**

✅ Bucket créé

---

### Vérification

Vous devez voir **3 buckets** dans la liste :
- audio-recordings (Public)
- photos (Public)
- signatures (Private)

---

## 🔐 Étape 3/4 : Configurer les Secrets

### Accéder aux Secrets

**Lien direct** : https://supabase.com/dashboard/project/dndjtcxypqnsyjzlzbxh/settings/functions

Ou : Dashboard → **Settings** → **Edge Functions**

---

### Secret 1 : OPENAI_API_KEY

1. Scroller vers le bas jusqu'à la section **Secrets**
2. Cliquer sur **Add new secret**
3. Remplir :
   - **Secret name** : `OPENAI_API_KEY`
   - **Secret value** : Votre clé OpenAI (commence par `sk-proj-...`)
4. **Add secret**

✅ Secret ajouté

---

### Secret 2 : STRIPE_SECRET_KEY

1. **Add new secret** (encore)
2. Remplir :
   - **Secret name** : `STRIPE_SECRET_KEY`
   - **Secret value** : Votre clé Stripe secrète (commence par `sk_test_...` ou `sk_live_...`)
3. **Add secret**

✅ Secret ajouté

---

### Secret 3 : STRIPE_WEBHOOK_SECRET

1. **Add new secret** (dernière fois)
2. Remplir :
   - **Secret name** : `STRIPE_WEBHOOK_SECRET`
   - **Secret value** : Votre webhook secret Stripe (commence par `whsec_...`)
3. **Add secret**

✅ Secret ajouté

**Note** : Si vous n'avez pas encore les clés Stripe, vous pouvez les ajouter plus tard. L'app fonctionnera sans Stripe pour les tests.

---

### Vérification

Vous devez voir **3 secrets** configurés :
- OPENAI_API_KEY
- STRIPE_SECRET_KEY
- STRIPE_WEBHOOK_SECRET

---

## 📝 Étape 4/4 : Créer le fichier .env

### Récupérer les Clés Supabase

**Lien direct** : https://supabase.com/dashboard/project/dndjtcxypqnsyjzlzbxh/settings/api

Ou : Dashboard → **Settings** → **API**

### Copier ces valeurs :

- **Project URL** : `https://dndjtcxypqnsyjzlzbxh.supabase.co`
- **anon public** : La longue clé qui commence par `eyJhbGc...`

---

### Créer le Fichier .env

Dans Cursor, à la **racine du projet** :

1. **Clic droit** sur l'espace vide → **New File**
2. Nom : `.env`
3. Contenu :

```env
# Supabase
SUPABASE_URL=https://dndjtcxypqnsyjzlzbxh.supabase.co
SUPABASE_ANON_KEY=COLLER_VOTRE_ANON_KEY_ICI

# OpenAI
OPENAI_API_KEY=sk-proj-VOTRE_CLE_OPENAI

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_test_VOTRE_CLE_STRIPE
```

4. **Remplacer** :
   - `COLLER_VOTRE_ANON_KEY_ICI` avec la clé `anon public` copiée
   - `sk-proj-VOTRE_CLE_OPENAI` avec votre vraie clé OpenAI
   - `pk_test_VOTRE_CLE_STRIPE` avec votre clé publique Stripe

5. **Sauvegarder** (Ctrl+S)

✅ Fichier .env créé

---

## ✅ Checklist Complète

- [ ] 3 Storage Buckets créés (audio, photos, signatures)
- [ ] 3 Secrets configurés (OpenAI, Stripe x2)
- [ ] Fichier .env créé avec les bonnes clés
- [ ] Fichier .env sauvegardé

---

## 🚀 Lancer l'Application !

Une fois tout configuré :

```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
flutter run
```

---

## 🎯 Résumé Final

| Étape | Statut |
|-------|--------|
| SQL V1.5 | ✅ Fait |
| SQL V2.0 | ✅ Fait |
| Edge Functions | ✅ Fait |
| Storage Buckets | ⏳ En cours |
| Secrets | ⏳ Ensuite |
| .env | ⏳ Après |
| Flutter Run | ⏳ Final |

---

**Commencez par le Storage maintenant !** 🗄️

https://supabase.com/dashboard/project/dndjtcxypqnsyjzlzbxh/storage/buckets




