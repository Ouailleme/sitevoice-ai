# 📦 Installer Node.js sur Windows - Guide Ultra-Simple

## 🎯 Situation Actuelle

❌ Node.js **téléchargé** mais **PAS ENCORE INSTALLÉ**

---

## ✅ Solution en 5 Minutes

### 1️⃣ Trouver le Fichier Téléchargé

Aller dans votre dossier **Téléchargements** :
- Chercher un fichier nommé : `node-v20.x.x-x64.msi` (ou similaire)
- Icône : Logo Node.js (hexagone vert)

### 2️⃣ Lancer l'Installation

1. **Double-cliquer** sur le fichier `.msi`
2. Une fenêtre s'ouvre : "Node.js Setup"
3. Cliquer **Next**
4. Accepter la licence → **Next**
5. **IMPORTANT** : Garder le chemin par défaut
   - `C:\Program Files\nodejs\`
6. **Next**
7. **IMPORTANT** : Vérifier que "Add to PATH" est coché ✅
8. **Next**
9. **Cocher** : "Automatically install necessary tools" ✅
10. **Next** → **Install**

⏳ **Attendre 2-3 minutes**...

11. **Finish**

### 3️⃣ REDÉMARRER Cursor

**CRUCIAL** :
1. Fermer Cursor **complètement**
2. Rouvrir Cursor
3. Ouvrir un **nouveau terminal**

### 4️⃣ Tester

```powershell
node --version
npm --version
```

**Résultat attendu** :
```
v20.11.0
10.2.4
```

✅ **Si vous voyez des versions** : Node.js est installé !

---

## 🚀 Ensuite : Installer Supabase CLI

```powershell
# Une fois Node.js installé
npm install -g supabase

# Attendre 1-2 minutes...

# Vérifier
supabase --version
```

**Résultat attendu** :
```
1.142.2
```

---

## 🎯 Déployer le Backend

```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"

# Lier le projet (vous demandera le project-ref)
supabase link

# Déployer automatiquement
.\scripts\deploy_backend.ps1
```

---

## ❓ FAQ

### Q : "Je ne trouve pas le fichier .msi"

**R** : Retéléchargez Node.js :
1. https://nodejs.org/
2. Cliquez sur le gros bouton vert "Download Node.js (LTS)"
3. Attendez le téléchargement
4. Fichier dans `C:\Users\yvesm\Downloads\`

### Q : "L'installation dit 'déjà installé'"

**R** : Désinstallez d'abord :
1. Panneau de configuration → Programmes
2. Chercher "Node.js"
3. Désinstaller
4. Réinstaller proprement

### Q : "node --version" ne marche toujours pas

**R** : Vérifiez que vous avez bien **redémarré Cursor**

### Q : "Je veux juste tester l'app"

**R** : Utilisez `DEPLOY_MANUAL_DASHBOARD.md` pour déployer le SQL manuellement

---

## 🎬 Résumé en 1 Image

```
[ Téléchargement Node.js ] ✅ (Vous êtes ici)
           ↓
[ Double-clic sur .msi ] ← FAITES ÇA MAINTENANT
           ↓
[ Installer (2-3 min) ]
           ↓
[ REDÉMARRER Cursor ] ← CRUCIAL
           ↓
[ node --version ] ← Tester
           ↓
[ npm install -g supabase ]
           ↓
[ .\scripts\deploy_backend.ps1 ]
           ↓
[ 🎉 TERMINÉ ! ]
```

---

## ⚡ Action MAINTENANT

1. **Aller dans Téléchargements**
2. **Double-cliquer** sur `node-v20...msi`
3. **Next, Next, Install**
4. **Redémarrer Cursor**
5. **Tester** : `node --version`

**Temps** : 5 minutes chrono ! ⏱️

---

**Besoin d'aide ?** Dites-moi où vous bloquez exactement ! 🤝


