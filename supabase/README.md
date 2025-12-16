# 🗄️ Supabase - SiteVoice AI

Base de données PostgreSQL avec Row Level Security pour l'application SiteVoice AI.

---

## 🔗 **Liens Rapides**

- 🌐 [Dashboard Supabase](https://supabase.com/dashboard)
- 📝 [SQL Editor](https://supabase.com/dashboard/project/_/sql)
- 📊 [Table Editor](https://supabase.com/dashboard/project/_/editor)
- 🔒 [Auth Settings](https://supabase.com/dashboard/project/_/auth/users)

---

## 📋 **Structure de la Base de Données**

### **Tables Principales**

| Table | Description | Colonnes Principales |
|-------|-------------|---------------------|
| `companies` | Entreprises clientes | id, name, subscription_status |
| `users` | Utilisateurs/Techniciens | id, email, company_id, role |
| `clients` | Carnet d'adresses | id, company_id, name, phone, email |
| `products` | Catalogue produits/services | id, company_id, reference, name, unit_price |
| `jobs` | Interventions/Chantiers | id, company_id, client_id, status |
| `job_items` | Lignes de facturation | id, job_id, product_id, quantity, total_price |

### **Relations**

```
companies
    ├── users (1:N)
    ├── clients (1:N)
    ├── products (1:N)
    └── jobs (1:N)
        └── job_items (1:N)
```

---

## 🔒 **Sécurité (RLS)**

Toutes les tables ont **Row Level Security activé** :

- ✅ Les utilisateurs voient uniquement les données de leur entreprise
- ✅ Les données sont isolées par `company_id`
- ✅ Fonction helper : `get_user_company_id()`

### **Tester les Permissions**

```sql
-- Voir ce que l'utilisateur actuel peut accéder
SELECT 
    (SELECT COUNT(*) FROM clients) as mes_clients,
    (SELECT COUNT(*) FROM products) as mes_produits,
    (SELECT COUNT(*) FROM jobs) as mes_jobs;
```

---

## 📁 **Fichiers Importants**

| Fichier | Usage |
|---------|-------|
| `migrations/` | 📂 Dossier de migrations versionnées |
| `schema.sql` | 📄 Schéma complet de référence |
| `health_check.sql` | 🏥 Vérification complète de la BDD |
| `fix_complete.sql` | 🔧 Script de réparation d'urgence |

---

## 🚀 **Démarrage Rapide**

### **1. Première Configuration**

Si la base de données est vide, exécute dans cet ordre :

```sql
-- 1. Créer le schéma
-- Exécuter : migrations/001_initial_schema.sql

-- 2. Créer les RLS policies
-- Exécuter : migrations/002_rls_policies.sql

-- 3. Vérifier
-- Exécuter : health_check.sql
```

### **2. Créer un Compte Test**

```sql
-- Créer une company
INSERT INTO companies (name, subscription_status) 
VALUES ('Ma Company Test', 'trial')
RETURNING id;

-- Associer ton user à cette company
UPDATE users 
SET company_id = 'COMPANY_ID_ICI'
WHERE id = auth.uid();
```

### **3. Ajouter des Données de Test**

```sql
-- Ajouter un client
INSERT INTO clients (company_id, name, phone, email, created_by)
SELECT 
    company_id,
    'Client Test',
    '0612345678',
    'test@example.com',
    id
FROM users WHERE id = auth.uid();

-- Ajouter un produit
INSERT INTO products (company_id, reference, name, unit_price, unit)
SELECT 
    company_id,
    'PROD-001',
    'Produit Test',
    100.00,
    'unité'
FROM users WHERE id = auth.uid();
```

---

## 🔄 **Maintenance**

### **Vérification Hebdomadaire**

```bash
# Exécuter health_check.sql dans SQL Editor
# Vérifier :
# - Nombre d'enregistrements
# - Policies RLS actives
# - Index présents
```

### **En Cas de Problème de Cache**

```sql
-- Forcer le rechargement
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
```

**OU** redémarrer le projet :
1. Project Settings > General
2. Pause project (30s)
3. Resume project
4. Attendre 2-3 min

---

## 📝 **Créer une Nouvelle Migration**

```bash
# 1. Copier le template
cp migrations/TEMPLATE.sql migrations/003_ma_migration.sql

# 2. Éditer le fichier
# 3. Appliquer dans SQL Editor
# 4. Documenter dans migrations/README.md
```

---

## 🐛 **Troubleshooting**

### **Erreur PGRST204 (colonne non trouvée)**

```sql
NOTIFY pgrst, 'reload schema';
```

### **Pas de données visibles**

```sql
-- Vérifier ton company_id
SELECT id, email, company_id FROM users WHERE id = auth.uid();

-- Si company_id est NULL, l'assigner
UPDATE users SET company_id = 'COMPANY_ID' WHERE id = auth.uid();
```

### **Erreur de permissions**

```sql
-- Vérifier les RLS policies
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'nom_de_ta_table';
```

---

## 📚 **Ressources**

- 📖 [Guide des Bonnes Pratiques](../BEST_PRACTICES_SUPABASE.md)
- 📁 [Guide des Migrations](migrations/README.md)
- 🔗 [Documentation Supabase](https://supabase.com/docs)

---

## 🆘 **Support**

En cas de problème :

1. ✅ Exécuter `health_check.sql`
2. ✅ Vérifier les logs Supabase
3. ✅ Consulter `BEST_PRACTICES_SUPABASE.md`
4. ✅ Redémarrer le projet si nécessaire

---

**📝 Dernière mise à jour : 2025-12-16**

