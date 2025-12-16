# 🤖 Guide GitHub Actions - Build Automatique

**Build garanti à 100%** sur les serveurs Linux de GitHub !

---

## 🎯 **COMMENT ÇA MARCHE ?**

### **Automatique**
Chaque fois que tu push vers `main`, GitHub Actions :
1. ✅ Clone ton projet
2. ✅ Installe Flutter + Java
3. ✅ Compile l'APK Debug + Release
4. ✅ Met les APK à disposition en téléchargement

### **Manuel**
Tu peux aussi lancer le build manuellement depuis GitHub.

---

## 📥 **RÉCUPÉRER L'APK**

### **Méthode 1 : Après un Push**

1. **Va sur GitHub** :
   ```
   https://github.com/Ouailleme/sitevoice-ai/actions
   ```

2. **Clique sur le dernier workflow** :
   - Tu verras "🏗️ Build Android APK"
   - Statut : ⏳ En cours → ✅ Terminé

3. **Télécharge l'APK** :
   - Scroll en bas de la page
   - Section **"Artifacts"**
   - Clique sur `app-debug` (pour tester)
   - OU `app-release` (pour production)

4. **Extrait et installe** :
   ```powershell
   # Extraire le ZIP téléchargé
   Expand-Archive -Path app-debug.zip -DestinationPath .
   
   # Installer sur le téléphone
   adb install app-debug.apk
   ```

### **Méthode 2 : Build Manuel**

1. **Va sur GitHub Actions** :
   ```
   https://github.com/Ouailleme/sitevoice-ai/actions
   ```

2. **Sélectionne le workflow** :
   - Clique sur "🏗️ Build Android APK" dans la liste de gauche

3. **Lance le build** :
   - Bouton **"Run workflow"** en haut à droite
   - Sélectionne la branche `main`
   - Clique **"Run workflow"**

4. **Attends 5-10 minutes** ⏱️

5. **Télécharge l'APK** (voir Méthode 1, étape 3)

---

## 🎬 **EXEMPLE COMPLET**

```powershell
# 1. Faire une modification dans le code
code lib/main.dart

# 2. Commit et push
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push

# 3. Aller sur GitHub Actions
Start-Process "https://github.com/Ouailleme/sitevoice-ai/actions"

# 4. Attendre le build (5-10 min)

# 5. Télécharger l'APK depuis "Artifacts"

# 6. Installer
adb install app-debug.apk
```

---

## 📊 **STATUT DU BUILD**

### **Badge Status**

Ajoute ce badge dans ton `README.md` :

```markdown
[![Build APK](https://github.com/Ouailleme/sitevoice-ai/actions/workflows/build-apk.yml/badge.svg)](https://github.com/Ouailleme/sitevoice-ai/actions/workflows/build-apk.yml)
```

Résultat : ![Build APK](https://img.shields.io/badge/build-passing-brightgreen)

### **Vérifier le Build**

```powershell
# Ouvrir les logs du dernier build
Start-Process "https://github.com/Ouailleme/sitevoice-ai/actions"
```

---

## ⏱️ **DURÉE DES BUILDS**

| Étape | Durée |
|-------|-------|
| Checkout + Setup | 1-2 min |
| Flutter pub get | 1-2 min |
| Build Debug APK | 2-3 min |
| Build Release APK | 3-5 min |
| **TOTAL** | **7-12 min** |

---

## 💡 **ASTUCES**

### **1. Build Plus Rapide**

Si tu veux seulement le Debug APK (pour tester) :

Édite `.github/workflows/build-apk.yml` et commente :

```yaml
# - name: 🏗️ Build Release APK
#   run: flutter build apk --release
# 
# - name: 📤 Upload Release APK
#   uses: actions/upload-artifact@v4
#   with:
#     name: app-release
#     path: build/app/outputs/flutter-apk/app-release.apk
```

→ Build en **~5 minutes** au lieu de 10

### **2. Notifications**

GitHub t'envoie un email quand le build est terminé.

Configurer : https://github.com/settings/notifications

### **3. Build sur Tag**

Pour build automatiquement quand tu crées une release :

Ajoute dans `.github/workflows/build-apk.yml` :

```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

Puis :

```powershell
git tag v1.1.0
git push origin v1.1.0
```

---

## 🐛 **DÉPANNAGE**

### **Build échoue ?**

1. **Voir les logs** :
   - Clique sur le build rouge ❌
   - Clique sur "build" → Détails des étapes

2. **Erreur commune : Dépendance manquante**
   ```
   Error: Package xxx not found
   ```
   
   **Solution** : Vérifier `pubspec.yaml`

3. **Erreur commune : Tests échouent**
   
   **Solution** : Désactiver les tests dans le workflow :
   ```yaml
   # - name: Run tests
   #   run: flutter test
   ```

### **APK trop gros ?**

```yaml
- name: 🏗️ Build Release APK (Optimisé)
  run: |
    flutter build apk --release --split-per-abi
```

→ Génère 3 APK (arm64-v8a, armeabi-v7a, x86_64)

---

## 📚 **RESSOURCES**

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
- [flutter-action](https://github.com/subosito/flutter-action)

---

## ✅ **CHECKLIST PREMIÈRE UTILISATION**

- [ ] Workflow créé (`.github/workflows/build-apk.yml`)
- [ ] Push vers GitHub
- [ ] Aller sur Actions tab
- [ ] Voir le build en cours ⏳
- [ ] Build terminé ✅
- [ ] Télécharger l'APK depuis Artifacts
- [ ] Extraire le ZIP
- [ ] Installer l'APK sur le téléphone
- [ ] Tester l'app ! 🎉

---

**🎯 Prochaine étape : PUSH vers GitHub !**

```powershell
cd "C:\Users\yvesm\Desktop\SiteVoice AI"
git add .
git commit -m "ci: configuration GitHub Actions pour build APK"
git push
```

Puis va sur : **https://github.com/Ouailleme/sitevoice-ai/actions**


