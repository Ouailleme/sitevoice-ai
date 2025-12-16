# 🔧 Installer Supabase CLI - Méthode Windows

## ⚠️ Problème
`npm install -g supabase` ne fonctionne plus (changement récent de Supabase)

---

## ✅ Solution A : NPX (Sans Installation) - RECOMMANDÉ

### Utiliser Supabase via npx

**Aucune installation nécessaire !** Utilisez directement :

```powershell
npx supabase --version
```

**Résultat attendu** :
```
1.142.2
```

### Pour tous les scripts

Remplacez `supabase` par `npx supabase` :

```powershell
# Au lieu de :
supabase link

# Utilisez :
npx supabase link
```

**Avantages** :
- ✅ Pas d'installation
- ✅ Toujours la dernière version
- ✅ Fonctionne immédiatement

---

## ✅ Solution B : Télécharger le Binaire

### Installer avec Scoop (Package Manager Windows)

#### 1. Installer Scoop (si pas déjà installé)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

#### 2. Installer Supabase CLI

```powershell
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

#### 3. Vérifier

```powershell
supabase --version
```

---

## ⚡ OPTION RAPIDE : Modifier le Script de Déploiement

### Utiliser npx dans le Script

On peut modifier le script pour utiliser `npx` au lieu de `supabase` :

```powershell
# Au lieu de vérifier si supabase est installé,
# on utilise npx supabase directement
```

**Je peux modifier le script maintenant pour vous ?**

---

## 🎯 Recommandation

### UTILISEZ NPX (Option A)

**C'est la solution la plus simple** :
- Pas d'installation complexe
- Fonctionne immédiatement
- Recommandé par Supabase

### Test Immédiat

```powershell
npx supabase --version
```

**Si ça affiche une version** → On continue !

---

## 🚀 Prochaine Étape : Déployer

Une fois que `npx supabase --version` fonctionne :

```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"

# Lier le projet Supabase
npx supabase link --project-ref VOTRE_PROJECT_REF

# Option 1 : Script modifié (je le modifie pour vous)
.\scripts\deploy_backend_npx.ps1

# Option 2 : Commandes manuelles
npx supabase db push
npx supabase functions deploy process-audio
npx supabase functions deploy webhook-dispatcher
npx supabase functions deploy create-subscription
npx supabase functions deploy stripe-webhook
```

---

## ❓ FAQ

### Q : "Qu'est-ce que npx ?"
**R** : C'est un outil inclus avec npm qui permet d'exécuter des commandes sans installation globale.

### Q : "C'est plus lent ?"
**R** : Premier lancement : 2-3 secondes. Ensuite, c'est mis en cache.

### Q : "Je préfère installer quand même"
**R** : Utilisez Scoop (Option B ci-dessus)

---

## 🎬 Action MAINTENANT

**TESTEZ** :

```powershell
npx supabase --version
```

**Résultat attendu** : `1.142.2` (ou supérieur)

**Si ça marche** → Dites-moi et je modifie le script de déploiement ! 🚀

