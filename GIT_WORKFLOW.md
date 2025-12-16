# 📝 **WORKFLOW GIT - SiteVoice AI**

## 🎯 **Conventions de Commit**

Utilise le format suivant pour tes commits :

```
type(scope): message

Exemples :
✅ feat(clients): ajout recherche par téléphone
✅ fix(auth): correction redirect après signup
✅ refactor(database): optimisation index products
✅ docs(supabase): ajout guide migrations
✅ style(ui): amélioration design home screen
```

### **Types de Commit**

| Type | Usage | Emoji |
|------|-------|-------|
| `feat` | Nouvelle fonctionnalité | ✨ |
| `fix` | Correction de bug | 🐛 |
| `refactor` | Refactoring (pas de changement fonctionnel) | ♻️ |
| `docs` | Documentation | 📝 |
| `style` | Style UI/UX (pas de changement de code) | 💄 |
| `perf` | Amélioration performance | ⚡ |
| `test` | Ajout/modification tests | ✅ |
| `chore` | Tâches diverses (build, config) | 🔧 |
| `db` | Changement de base de données | 🗄️ |

---

## 🌿 **Stratégie de Branches**

### **Branches Principales**

```
main (production)
├── develop (développement)
    ├── feature/nom-feature
    ├── fix/nom-bug
    └── db/nom-migration
```

### **Nommage des Branches**

```bash
# Nouvelle fonctionnalité
feature/clients-search
feature/audio-recording
feature/pdf-export

# Correction de bug
fix/login-redirect
fix/cache-supabase
fix/rls-permissions

# Migration de base de données
db/add-invoice-table
db/add-audit-columns
db/optimize-indexes

# Refactoring
refactor/services-architecture
refactor/home-screen-ui
```

---

## 🔄 **Workflow Standard**

### **1. Créer une Nouvelle Feature**

```bash
# Partir de develop
git checkout develop
git pull origin develop

# Créer une branche feature
git checkout -b feature/ma-feature

# Développer...
git add .
git commit -m "feat(scope): description"

# Pousser
git push origin feature/ma-feature

# Créer une Pull Request vers develop
```

### **2. Migration de Base de Données**

```bash
# Créer une branche db
git checkout -b db/add-audit-columns

# Créer la migration
cp supabase/migrations/TEMPLATE.sql supabase/migrations/003_add_audit_columns.sql

# Éditer la migration

# Commit
git add supabase/migrations/003_add_audit_columns.sql
git commit -m "db(supabase): ajout colonnes d'audit"

# Documenter
git add supabase/migrations/README.md
git commit -m "docs(supabase): documentation migration 003"

# Push et PR
git push origin db/add-audit-columns
```

### **3. Hotfix Urgent**

```bash
# Partir de main
git checkout main
git pull origin main

# Créer branche hotfix
git checkout -b hotfix/nom-bug

# Corriger
git add .
git commit -m "fix(scope): correction urgente"

# Push
git push origin hotfix/nom-bug

# Merge vers main ET develop
```

---

## 📦 **Que Versionner ?**

### ✅ **À Versionner (commit)**

```
✅ Code source Flutter (lib/)
✅ Migrations Supabase (supabase/migrations/)
✅ Documentation (*.md)
✅ Configuration (pubspec.yaml, android/app/build.gradle)
✅ Assets (images, fonts)
✅ Scripts utiles
```

### ❌ **À NE PAS Versionner (.gitignore)**

```
❌ Secrets (.env, .env.local)
❌ Fichiers de build (build/, .dart_tool/)
❌ Fichiers IDE (.vscode/, .idea/)
❌ Dépendances (node_modules/, .flutter-plugins)
❌ Données de test (test_data.sql, seed_data.sql)
❌ Logs (*.log)
```

---

## 📋 **Checklist Avant Commit**

### **Code Flutter**

- [ ] `flutter analyze` sans erreurs
- [ ] Code formaté (`flutter format .`)
- [ ] Pas de `print()` en debug (utiliser logger)
- [ ] Imports organisés
- [ ] Commentaires en français pour logique complexe

### **Migration Supabase**

- [ ] Migration testée dans SQL Editor
- [ ] `NOTIFY pgrst, 'reload schema'` à la fin
- [ ] Documentation mise à jour (migrations/README.md)
- [ ] Commentaires clairs dans le SQL
- [ ] Health check passé après migration

### **Documentation**

- [ ] README à jour si changement d'architecture
- [ ] Commentaires de code clairs
- [ ] Exemples d'utilisation si nouvelle feature

---

## 🏷️ **Tags et Releases**

### **Nommage des Versions**

Utilise [Semantic Versioning](https://semver.org/) :

```
v1.0.0 - Version initiale
v1.1.0 - Nouvelle feature mineure
v1.1.1 - Patch/bugfix
v2.0.0 - Breaking change majeur
```

### **Créer une Release**

```bash
# Tag
git tag -a v1.0.0 -m "Release 1.0.0 - Première version stable"

# Push le tag
git push origin v1.0.0

# Créer Release sur GitHub
# Ajouter notes de release (changelog)
```

---

## 📝 **Messages de Commit Détaillés**

### **Bon Commit**

```
feat(clients): ajout recherche par nom, email et téléphone

- Implémentation SearchBar dans ClientsListScreen
- Filtrage en temps réel côté client
- Animation de l'icône de recherche
- Tests unitaires ajoutés

Closes #42
```

### **Mauvais Commit**

```
update
```

```
fix bug
```

```
work in progress
```

---

## 🔍 **Revue de Code**

### **Pull Request Template**

```markdown
## 📝 Description
Qu'est-ce que cette PR fait ?

## 🎯 Type de Changement
- [ ] 🐛 Bug fix
- [ ] ✨ Nouvelle feature
- [ ] 🗄️ Migration DB
- [ ] 📝 Documentation

## ✅ Checklist
- [ ] Code testé manuellement
- [ ] Migrations appliquées et testées
- [ ] Documentation mise à jour
- [ ] Pas de console.log/print()
- [ ] Flutter analyze OK

## 📸 Screenshots (si applicable)
[Ajouter screenshots]

## 🔗 Issues Liées
Closes #XX
```

---

## 🚀 **Déploiement**

### **Workflow de Déploiement**

```bash
# 1. Merge feature vers develop
git checkout develop
git merge feature/ma-feature
git push origin develop

# 2. Test sur environnement de staging
# (si disponible)

# 3. Merge develop vers main
git checkout main
git merge develop
git push origin main

# 4. Tag la release
git tag -a v1.1.0 -m "Release 1.1.0"
git push origin v1.1.0

# 5. Build et déploiement
flutter build apk --release
# Ou via CI/CD
```

---

## 📊 **Historique et Statistiques**

### **Voir l'Historique**

```bash
# Log complet
git log --oneline --graph --all

# Log d'un fichier
git log -- supabase/migrations/

# Commits d'un auteur
git log --author="Ton Nom"

# Statistiques
git shortlog -sn
```

### **Comparer des Branches**

```bash
# Voir les différences
git diff develop main

# Voir les commits
git log develop..main
```

---

## 🆘 **Commandes Utiles**

### **Annuler des Changements**

```bash
# Annuler le dernier commit (garder les changements)
git reset --soft HEAD~1

# Annuler les changements d'un fichier
git checkout -- fichier.dart

# Annuler tous les changements non commités
git reset --hard HEAD
```

### **Nettoyer**

```bash
# Supprimer les branches locales mergées
git branch --merged | grep -v "main\|develop" | xargs git branch -d

# Nettoyer les branches remote supprimées
git fetch --prune
```

---

## 🔐 **Secrets et Variables d'Environnement**

### **Fichier .env**

```bash
# Ne JAMAIS commiter .env
# Utiliser .env.example comme template

# .env (local, pas dans Git)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx

# .env.example (dans Git)
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_anon_key_here
```

---

## 📚 **Ressources**

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)

---

**📝 Dernière mise à jour : 2025-12-16**

