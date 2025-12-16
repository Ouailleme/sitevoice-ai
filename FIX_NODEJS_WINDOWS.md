# 🔧 Fix Node.js sur Windows - Guide de Dépannage

## ⚠️ Problème : "node n'est pas reconnu"

C'est normal après l'installation ! Voici les solutions.

---

## 🎯 Solution Rapide (1 minute)

### Étape 1 : Fermer TOUS les PowerShell/Terminals

1. Fermer cette fenêtre PowerShell
2. Fermer Cursor/VS Code complètement
3. Fermer tous les terminaux ouverts

### Étape 2 : Rouvrir

1. Rouvrir Cursor/VS Code
2. Ouvrir un nouveau terminal (PowerShell)

### Étape 3 : Tester

```powershell
node --version
npm --version
```

**Résultat attendu** :
```
v20.x.x
10.x.x
```

✅ **Si ça marche** : Continuez avec l'installation de Supabase CLI

---

## 🔍 Solution Manuelle (si la solution rapide ne marche pas)

### Vérifier l'Installation

1. Ouvrir l'Explorateur de fichiers
2. Aller dans : `C:\Program Files\nodejs`
3. Vérifier que `node.exe` et `npm.cmd` existent

**Si le dossier n'existe pas** → Node.js n'est pas installé correctement.

### Réinstaller Node.js

1. Désinstaller via **Panneau de configuration** → **Programmes**
2. Télécharger la dernière version LTS : https://nodejs.org/
3. **Important** : Cocher "Add to PATH" pendant l'installation
4. Redémarrer l'ordinateur

---

## 🛠️ Solution Alternative : Ajouter au PATH Manuellement

### Si Node.js est installé mais pas reconnu

1. Rechercher "Variables d'environnement" dans Windows
2. **Modifier les variables d'environnement système**
3. Dans **Variables système** → **Path** → **Modifier**
4. **Ajouter** :
   - `C:\Program Files\nodejs\`
5. **OK** → **OK** → Redémarrer PowerShell

### Tester

```powershell
refreshenv  # Si disponible
# OU
node --version
```

---

## ⚡ Solution IMMÉDIATE : Utiliser le Terminal Intégré

### Sans Redémarrer

Ouvrir **Invite de commandes** (cmd.exe) au lieu de PowerShell :

```cmd
cd C:\Users\yvesm\Desktop\SiteVoice AI
node --version
npm --version
```

**Si ça marche dans cmd** : Node.js est installé, c'est juste PowerShell qui n'a pas rafraîchi.

---

## 🎯 Une Fois Node.js Reconnu

```powershell
# Installer Supabase CLI
npm install -g supabase

# Vérifier
supabase --version

# Déployer le backend
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
.\scripts\deploy_backend.ps1
```

---

## 🆘 Si Rien ne Marche

### Alternative : Déploiement Manuel via Dashboard

**Pas de CLI nécessaire !**

Suivez le guide : `ALTERNATIVE_DEPLOYMENT.md`

**Résumé** :
1. Copier `supabase/schema.sql` dans **SQL Editor** de Supabase Dashboard
2. Copier `supabase/schema_v2_webhooks.sql` dans **SQL Editor**
3. Pour les Edge Functions : Utiliser GitHub Actions (voir docs)

---

## 🎬 Action Immédiate

**ESSAYEZ MAINTENANT** :

1. **Fermer Cursor complètement**
2. **Rouvrir Cursor**
3. **Nouveau terminal**
4. **Tester** :
   ```powershell
   node --version
   ```

Si ça ne marche toujours pas → Consulter `ALTERNATIVE_DEPLOYMENT.md`

---

**La bonne nouvelle** : Le code est 100% prêt ! C'est juste une question de configuration de l'environnement. 💪


