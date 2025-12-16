# ⚡ SOLUTION IMMÉDIATE - 2 Options

## 🎯 Option A : Faire Fonctionner Node.js (5 minutes)

### Problème Détecté
Node.js est téléchargé mais **pas encore installé** ou **pas dans le PATH**.

### Solution en 3 Étapes

#### 1️⃣ Lancer l'Installateur
- Double-cliquer sur le fichier `.msi` téléchargé
- **IMPORTANT** : Cocher "Add to PATH" ✅
- Installer avec les options par défaut
- Attendre la fin (2-3 minutes)

#### 2️⃣ Redémarrer le Terminal
- **Fermer Cursor complètement**
- **Rouvrir Cursor**
- Ouvrir un nouveau terminal

#### 3️⃣ Tester
```powershell
node --version
npm --version
```

**Si ça marche** :
```powershell
# Installer Supabase CLI
npm install -g supabase

# Déployer
.\scripts\deploy_backend.ps1
```

---

## 🚀 Option B : Déployer SANS CLI (30 minutes)

**Bonne nouvelle** : On peut tout faire via le Dashboard Supabase !

### Étape 1 : Créer le Projet Supabase

1. Aller sur https://supabase.com
2. **Sign Up** / **Login**
3. **New Project** :
   - Name : `SiteVoice AI`
   - Database Password : (choisir un mot de passe fort)
   - Region : `Europe West (Ireland)`
   - **Create Project** (attendre 2-3 minutes)

### Étape 2 : Récupérer les Clés API

1. **Settings** (icône engrenage) → **API**
2. Noter :
   - `Project URL` : https://XXXXX.supabase.co
   - `anon` key (public)
   - `service_role` key (secret)

### Étape 3 : Déployer le Schéma SQL

1. **SQL Editor** (menu gauche) → **New Query**

2. **Copier-coller le contenu de** `supabase/schema.sql`
   - Cliquer sur le fichier dans Cursor
   - Ctrl+A → Ctrl+C
   - Coller dans SQL Editor
   - **Run** (en bas à droite)

3. **Nouvelle Query** → Copier-coller `supabase/schema_v2_webhooks.sql`
   - **Run**

**Résultat** : ✅ 15 tables créées

### Étape 4 : Créer les Storage Buckets

1. **Storage** (menu gauche) → **Create Bucket**

**Créer 3 buckets** :

#### Bucket 1
- Name : `audio-recordings`
- Public : ✅ Yes
- File size limit : 50 MB

#### Bucket 2
- Name : `photos`
- Public : ✅ Yes
- File size limit : 10 MB

#### Bucket 3
- Name : `signatures`
- Public : ❌ No
- File size limit : 1 MB

### Étape 5 : Configurer l'App Flutter

Créer un fichier `.env` à la racine :

```env
SUPABASE_URL=https://VOTRE_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
OPENAI_API_KEY=sk-proj-...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

(Remplacer avec vos vraies valeurs)

### Étape 6 : Tester l'App

```powershell
flutter run
```

**Fonctionnalités disponibles SANS Edge Functions** :
- ✅ Enregistrement audio
- ✅ Sauvegarde locale
- ✅ GPS
- ✅ Photos
- ✅ Signature
- ✅ UI complète

**Ce qui nécessite les Edge Functions** :
- ❌ Transcription Whisper (mais on peut l'ajouter plus tard)
- ❌ Extraction GPT-4o
- ❌ Webhooks

---

## 🎯 Recommandation

### Pour tester rapidement l'APP
👉 **Option B** : Déployer SQL + Storage via Dashboard

### Pour avoir toutes les features IA
👉 **Option A** : Installer Node.js correctement

---

## 📝 Étapes Node.js Détaillées

1. **Télécharger** : https://nodejs.org/ (Version LTS)
2. **Exécuter** le fichier `.msi`
3. **Cocher** "Automatically install necessary tools" ✅
4. **Cocher** "Add to PATH" ✅
5. **Next** → **Next** → **Install**
6. **Attendre** que l'installation finisse
7. **FERMER tous les terminaux**
8. **Redémarrer Cursor**
9. **Tester** : `node --version`

---

## ⚡ Quelle Option Choisir ?

### Vous voulez TESTER l'UI rapidement ?
→ **Option B** (30 min, pas de CLI)

### Vous voulez TOUT (IA, Webhooks, etc.) ?
→ **Option A** (Réinstaller Node.js proprement)

---

**Mon conseil** : Commencez par **Option B** pour voir l'app fonctionner, puis installez Node.js tranquillement pour ajouter l'IA plus tard.

🚀


