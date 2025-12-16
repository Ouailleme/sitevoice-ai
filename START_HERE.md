# 🚀 COMMENCEZ ICI - SiteVoice AI V2.0

## 📍 Vous êtes ici

```
✅ Code 100% terminé (70+ fichiers)
✅ Modèles JSON générés (build_runner réussi)
❌ Node.js téléchargé mais PAS installé
```

---

## 🎯 2 Options Simples

### 🟢 OPTION A : Installation Complète (Recommandé)
**Durée** : 20 minutes  
**Résultat** : App 100% fonctionnelle avec IA

### 🟡 OPTION B : Test Rapide (Sans IA)
**Durée** : 10 minutes  
**Résultat** : App fonctionnelle SANS transcription IA

---

## 🟢 OPTION A : Installation Complète

### Étape 1 : Installer Node.js (5 min)

1. **Aller dans** : `C:\Users\yvesm\Downloads\`
2. **Chercher** : `node-v20.x.x-x64.msi`
3. **Double-cliquer** dessus
4. **Installer** avec les options par défaut
   - ✅ Cocher "Add to PATH"
   - ✅ Cocher "Install necessary tools"
5. **Finish**

**SI VOUS NE TROUVEZ PAS LE FICHIER** :
- Retéléchargez : https://nodejs.org/
- Cliquez sur le gros bouton vert "LTS"
- Attendez le téléchargement
- Double-cliquez sur le fichier téléchargé

### Étape 2 : Redémarrer Cursor (CRUCIAL)

1. **Fermer Cursor complètement**
2. **Rouvrir Cursor**
3. **Ouvrir un nouveau terminal**

### Étape 3 : Vérifier

```powershell
node --version
npm --version
```

**Si ça affiche des versions** → Continuer ⬇️  
**Si ça ne marche pas** → Voir `FIX_NODEJS_WINDOWS.md`

### Étape 4 : Installer Supabase CLI (2 min)

```powershell
npm install -g supabase
```

Attendre 1-2 minutes...

```powershell
# Vérifier
supabase --version
```

### Étape 5 : Créer Projet Supabase (5 min)

1. Aller sur : https://supabase.com
2. **Sign Up** / **Login**
3. **New Project** :
   - Name : `SiteVoice AI`
   - Password : (choisir et NOTER)
   - Region : Europe West
4. **Create** (attendre 2-3 min)

### Étape 6 : Lier le Projet (2 min)

Dans le Dashboard Supabase :
- **Settings** → **General** → Copier le **Reference ID**

Dans le terminal :
```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
supabase link --project-ref VOTRE_REFERENCE_ID
# Entrer le mot de passe quand demandé
```

### Étape 7 : Déployer Automatiquement (5 min)

```powershell
.\scripts\deploy_backend.ps1
```

✅ **TERMINÉ !** Le backend est déployé

### Étape 8 : Tester

```powershell
flutter run
```

---

## 🟡 OPTION B : Test Rapide (Sans CLI)

**Pour tester l'UI immédiatement sans installer Node.js**

### Étape 1 : Créer Projet Supabase (5 min)

1. https://supabase.com → **New Project**
2. Name : `SiteVoice AI`
3. Password : (noter)
4. **Create**

### Étape 2 : Copier les Clés (2 min)

Dashboard → **Settings** → **API**

Copier :
- Project URL
- anon key

### Étape 3 : Créer `.env` (1 min)

Créer un fichier `.env` dans le projet :

```env
SUPABASE_URL=https://XXXXX.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
```

### Étape 4 : Déployer SQL Manuellement (5 min)

Dashboard → **SQL Editor** → **New Query**

1. Copier tout le contenu de `supabase/schema.sql`
2. Coller dans l'éditeur
3. **Run**

### Étape 5 : Créer Storage (3 min)

Dashboard → **Storage** → **Create Bucket**

Créer 3 buckets :
- `audio-recordings` (Public)
- `photos` (Public)
- `signatures` (Private)

### Étape 6 : Lancer l'App

```powershell
flutter run
```

**Fonctionnalités disponibles** :
- ✅ UI complète
- ✅ Enregistrement audio
- ✅ Photos
- ✅ GPS
- ✅ Sauvegarde locale
- ❌ Transcription IA (nécessite Edge Functions)

---

## 🎯 Quelle Option Choisir ?

### Choisissez OPTION A si :
- Vous voulez la **version complète avec IA**
- Vous voulez les **webhooks et geofencing**
- Vous avez 20 minutes

### Choisissez OPTION B si :
- Vous voulez **tester l'UI rapidement**
- Vous n'avez pas le temps maintenant
- Vous ajouterez l'IA plus tard

---

## 📞 Où Êtes-Vous Bloqué ?

### "Je ne trouve pas le fichier .msi"
→ Voir section "Trouver le Fichier" ci-dessus

### "L'installation échoue"
→ Exécuter en tant qu'**Administrateur**

### "node --version ne marche pas"
→ Avez-vous **redémarré Cursor** ?

### "Je n'ai pas le temps maintenant"
→ Utilisez **OPTION B** (test rapide)

---

## ✅ Action Immédiate

**MAINTENANT** :

1. Ouvrir votre dossier **Téléchargements**
2. Chercher `node-v20...msi`
3. Double-cliquer dessus
4. Installer (Next, Next, Install)
5. Redémarrer Cursor
6. Tester : `node --version`

**Ou** :

Si pas le temps → Utilisez **OPTION B** (voir `DEPLOY_MANUAL_DASHBOARD.md`)

---

**Dites-moi laquelle vous choisissez !** 🚀


