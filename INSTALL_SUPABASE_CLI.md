# 📦 Installation Supabase CLI - Windows

## 🎯 Méthode Recommandée : NPM

### Prérequis : Node.js

Si Node.js n'est pas installé :
1. Télécharger : https://nodejs.org/
2. Installer la version LTS
3. Redémarrer le terminal

### Installation

```powershell
# Installer Supabase CLI globalement
npm install -g supabase

# Vérifier l'installation
supabase --version
```

**Résultat attendu** : `supabase 1.x.x`

---

## 🔗 Lier le Projet

### 1. Créer un Projet Supabase

1. Aller sur https://supabase.com
2. Sign Up / Login
3. **New Project** :
   - Name : `SiteVoice AI`
   - Database Password : (noter quelque part)
   - Region : `Europe West (Ireland)`

### 2. Récupérer le Project Reference

Dans le Dashboard :
- **Settings** → **General** → **Reference ID**
- Exemple : `abcdefghijklmnop`

### 3. Lier le Projet Local

```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"

supabase link --project-ref VOTRE_PROJECT_REF
# Vous demandera le mot de passe de la DB
```

**Résultat** : Fichier `.supabase/config.toml` créé ✅

---

## 🔐 Configurer les Clés API

### Dans `.env` (pour l'app Flutter)

1. Dashboard → **Settings** → **API**
2. Copier :
   - `Project URL`
   - `anon` key (public)

Créer un fichier `.env` :

```env
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
OPENAI_API_KEY=sk-...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

### Pour les Edge Functions (Secrets)

```powershell
# OpenAI
supabase secrets set OPENAI_API_KEY=sk-...

# Stripe
supabase secrets set STRIPE_SECRET_KEY=sk_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...

# Vérifier
supabase secrets list
```

---

## ✅ Une Fois Supabase CLI Installé

**Relancer le déploiement** :

```powershell
.\scripts\deploy_backend.ps1
```

---

## 🆘 Problèmes Courants

### Erreur : "npm not found"

**Installer Node.js** :
- https://nodejs.org/
- Version LTS recommandée
- Redémarrer PowerShell après installation

### Erreur : "supabase link failed"

**Vérifier** :
1. Project REF correct (16 caractères)
2. Mot de passe DB correct
3. Connexion internet active

### Erreur : "Permission denied"

**Exécuter PowerShell en Administrateur** :
- Clic droit → Exécuter en tant qu'administrateur

---

## 📋 Checklist Installation

- [ ] Node.js installé
- [ ] `npm --version` fonctionne
- [ ] `npm install -g supabase` réussi
- [ ] `supabase --version` affiche la version
- [ ] Projet Supabase créé sur supabase.com
- [ ] `supabase link` réussi
- [ ] Secrets configurés
- [ ] `.env` créé avec les clés

---

**Temps estimé** : 10-15 minutes

Une fois terminé, relancez :
```powershell
.\scripts\deploy_backend.ps1
```

🚀


