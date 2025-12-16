# 📁 Migrations Supabase - SiteVoice AI

## 📋 **Liste des Migrations**

| # | Fichier | Date | Description |
|---|---------|------|-------------|
| 001 | `001_initial_schema.sql` | 2025-12-16 | Schéma initial (tables, index) |
| 002 | `002_rls_policies.sql` | 2025-12-16 | Politiques RLS et fonction helper |

---

## 🚀 **Comment Appliquer une Migration**

### **Méthode 1 : SQL Editor (Recommandé)**

1. Va sur **https://supabase.com/dashboard**
2. Sélectionne ton projet **SiteVoice AI**
3. Clique sur **SQL Editor**
4. Ouvre le fichier de migration dans VS Code
5. Copie tout le contenu
6. Colle dans le SQL Editor
7. Clique sur **Run** (F5)

### **Méthode 2 : Supabase CLI** (si installé)

```bash
supabase db push
```

---

## 📝 **Créer une Nouvelle Migration**

### **Étape 1 : Créer le fichier**

Nomme ton fichier avec le format : `XXX_description.sql`

Exemple :
```
003_add_invoice_table.sql
004_add_search_indexes.sql
005_update_jobs_status_enum.sql
```

### **Étape 2 : Utiliser le template**

```sql
-- =====================================================
-- MIGRATION XXX: TITRE DE LA MIGRATION
-- =====================================================
-- Date: YYYY-MM-DD
-- Description: Description détaillée de ce que fait cette migration
-- =====================================================

-- Ton code SQL ici

-- À la fin, toujours recharger le schéma
NOTIFY pgrst, 'reload schema';
```

### **Étape 3 : Tester**

1. Teste d'abord sur un **projet Supabase de test** si possible
2. Vérifie que la migration s'applique sans erreur
3. Vérifie que l'app fonctionne après la migration

### **Étape 4 : Documenter**

Ajoute une ligne dans ce README avec :
- Le numéro de la migration
- Le nom du fichier
- La date
- Une description courte

---

## ⚠️ **Bonnes Pratiques**

### ✅ **À FAIRE**

- **Toujours** utiliser `IF NOT EXISTS` pour les créations
- **Toujours** utiliser `DROP ... IF EXISTS` avant les recréations
- Ajouter des commentaires clairs
- Tester avant de déployer en production
- Garder les migrations **petites et atomiques**
- Versionner les migrations dans Git

### ❌ **À ÉVITER**

- Modifier une migration déjà appliquée (crée-en une nouvelle à la place)
- Supprimer des colonnes sans plan de migration des données
- Oublier les index sur les foreign keys
- Oublier les RLS policies sur les nouvelles tables

---

## 🔄 **Rollback d'une Migration**

Si une migration pose problème :

1. Créer une nouvelle migration de **rollback**
   ```
   XXX_rollback_YYY.sql
   ```

2. Annuler les changements de la migration problématique

3. Tester le rollback

---

## 📊 **Vérifier l'État Actuel**

### **Lister toutes les tables**

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### **Vérifier les RLS policies**

```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### **Vérifier les index**

```sql
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

---

## 🛠️ **Outils Utiles**

### **Recharger le cache Supabase**

```sql
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
```

### **Vérifier une table spécifique**

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'nom_de_ta_table'
ORDER BY ordinal_position;
```

---

## 📚 **Ressources**

- [Documentation Supabase](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

