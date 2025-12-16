# 🎯 **BONNES PRATIQUES SUPABASE - SiteVoice AI**

## 📋 **TABLE DES MATIÈRES**

1. [Structure des Migrations](#structure-des-migrations)
2. [Gestion du Schéma](#gestion-du-schéma)
3. [Row Level Security (RLS)](#row-level-security)
4. [Performance](#performance)
5. [Sécurité](#sécurité)
6. [Debugging](#debugging)

---

## 📁 **Structure des Migrations**

### **Organisation des Fichiers**

```
supabase/
├── migrations/
│   ├── README.md              # Documentation des migrations
│   ├── TEMPLATE.sql           # Template pour nouvelles migrations
│   ├── 001_initial_schema.sql
│   ├── 002_rls_policies.sql
│   └── ...
├── schema.sql                 # Schéma complet (référence)
├── health_check.sql           # Script de vérification
├── fix_complete.sql           # Script de réparation
└── .gitignore
```

### **Convention de Nommage**

```
XXX_description_courte.sql

Exemples :
✅ 001_initial_schema.sql
✅ 002_rls_policies.sql
✅ 003_add_invoice_table.sql
✅ 004_add_search_indexes.sql

❌ migration.sql
❌ fix.sql
❌ update_db.sql
```

---

## 🔄 **Gestion du Schéma**

### **Workflow de Modification**

1. **Créer une nouvelle migration**
   ```bash
   # Copier le template
   cp supabase/migrations/TEMPLATE.sql supabase/migrations/003_ma_migration.sql
   ```

2. **Éditer la migration**
   - Ajouter ton code SQL
   - Ajouter des commentaires clairs
   - Tester localement si possible

3. **Appliquer la migration**
   - Ouvrir le SQL Editor dans Supabase
   - Copier/coller le contenu
   - Exécuter avec Run (F5)

4. **Vérifier**
   ```sql
   -- Exécuter health_check.sql
   -- Tester l'app Flutter
   ```

5. **Documenter**
   - Ajouter une ligne dans `migrations/README.md`
   - Commit et push vers Git

### **Commandes SQL Essentielles**

#### **Créer une table**
```sql
CREATE TABLE IF NOT EXISTS table_name (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **Ajouter une colonne**
```sql
ALTER TABLE table_name 
ADD COLUMN IF NOT EXISTS column_name TYPE DEFAULT value;
```

#### **Créer un index**
```sql
CREATE INDEX IF NOT EXISTS idx_table_column 
ON table_name(column_name);
```

#### **Modifier une colonne**
```sql
-- Changer le type
ALTER TABLE table_name 
ALTER COLUMN column_name TYPE new_type;

-- Ajouter une contrainte
ALTER TABLE table_name 
ALTER COLUMN column_name SET NOT NULL;
```

#### **Supprimer une colonne (avec précaution !)**
```sql
-- Toujours vérifier les dépendances avant
ALTER TABLE table_name 
DROP COLUMN IF EXISTS column_name CASCADE;
```

---

## 🔒 **Row Level Security (RLS)**

### **Fonction Helper Essentielle**

```sql
-- Fonction pour récupérer le company_id de l'utilisateur
CREATE OR REPLACE FUNCTION get_user_company_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER  -- Important pour éviter la récursion
STABLE
AS $$
BEGIN
    RETURN (SELECT company_id FROM users WHERE id = auth.uid());
END;
$$;
```

### **Patterns de Policies Courants**

#### **SELECT - Voir les données de sa company**
```sql
CREATE POLICY "policy_name"
    ON table_name FOR SELECT
    USING (company_id = get_user_company_id());
```

#### **INSERT - Créer uniquement pour sa company**
```sql
CREATE POLICY "policy_name"
    ON table_name FOR INSERT
    WITH CHECK (company_id = get_user_company_id());
```

#### **UPDATE - Modifier uniquement sa company**
```sql
CREATE POLICY "policy_name"
    ON table_name FOR UPDATE
    USING (company_id = get_user_company_id());
```

#### **DELETE - Supprimer uniquement sa company**
```sql
CREATE POLICY "policy_name"
    ON table_name FOR DELETE
    USING (company_id = get_user_company_id());
```

#### **Policy avec rôle admin**
```sql
CREATE POLICY "policy_name"
    ON table_name FOR UPDATE
    USING (
        company_id = get_user_company_id()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
```

### **Checklist RLS**

✅ Toujours activer RLS sur les nouvelles tables
```sql
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

✅ Créer des policies pour chaque opération (SELECT, INSERT, UPDATE, DELETE)

✅ Tester avec différents utilisateurs

✅ Utiliser `SECURITY DEFINER` sur les fonctions helpers

---

## ⚡ **Performance**

### **Index Essentiels**

#### **Foreign Keys**
```sql
-- TOUJOURS indexer les foreign keys
CREATE INDEX idx_table_company_id ON table_name(company_id);
CREATE INDEX idx_table_user_id ON table_name(user_id);
```

#### **Colonnes de Recherche**
```sql
-- Colonnes utilisées dans WHERE, ORDER BY
CREATE INDEX idx_clients_name ON clients(name);
CREATE INDEX idx_products_reference ON products(reference);
```

#### **Colonnes de Tri**
```sql
-- Pour les listes triées par date
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);
```

#### **Index Composites**
```sql
-- Pour les requêtes avec plusieurs conditions
CREATE INDEX idx_jobs_company_status 
ON jobs(company_id, status);
```

### **Optimisation des Requêtes**

#### **Éviter les N+1**
```sql
-- ❌ Mauvais
SELECT * FROM jobs;
-- Puis pour chaque job : SELECT * FROM clients WHERE id = job.client_id

-- ✅ Bon
SELECT 
    jobs.*,
    clients.name as client_name
FROM jobs
LEFT JOIN clients ON jobs.client_id = clients.id;
```

#### **Limiter les résultats**
```sql
-- Toujours paginer les grandes listes
SELECT * FROM jobs 
ORDER BY created_at DESC 
LIMIT 50 OFFSET 0;
```

---

## 🛡️ **Sécurité**

### **Checklist Sécurité**

✅ **RLS activé sur toutes les tables**
```sql
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

✅ **Policies strictes**
- Jamais de `USING (true)` en production
- Toujours vérifier le `company_id`

✅ **Validation des données**
```sql
-- Contraintes CHECK
ALTER TABLE products 
ADD CONSTRAINT check_price_positive 
CHECK (unit_price >= 0);
```

✅ **Secrets jamais en dur**
- Utiliser les variables d'environnement
- `.env` dans `.gitignore`

✅ **Logs et monitoring**
- Activer les logs Supabase
- Surveiller les requêtes lentes

---

## 🐛 **Debugging**

### **Vérifier le Cache**

Si tu as des erreurs `PGRST204` (colonne non trouvée) :

```sql
-- Forcer le rechargement
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
```

**OU** redémarrer le projet Supabase :
1. Project Settings > General
2. Pause project
3. Attendre 1 minute
4. Resume project

### **Vérifier les RLS Policies**

```sql
-- Lister toutes les policies
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public';
```

### **Tester une Query en tant qu'utilisateur**

```sql
-- Simuler un utilisateur spécifique
SET request.jwt.claim.sub = 'user-uuid-here';

-- Ta requête de test
SELECT * FROM clients;

-- Réinitialiser
RESET request.jwt.claim.sub;
```

### **Vérifier les Permissions**

```sql
-- Vérifier si un utilisateur a accès
SELECT 
    auth.uid() as current_user,
    get_user_company_id() as company_id,
    (SELECT COUNT(*) FROM clients) as accessible_clients;
```

### **Health Check Régulier**

Exécute `health_check.sql` chaque semaine pour :
- Vérifier les tables
- Vérifier les RLS policies
- Vérifier les index
- Compter les données

---

## 📚 **Ressources Utiles**

### **Documentation**
- [Supabase Docs](https://supabase.com/docs)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)

### **Scripts Essentiels**
- `migrations/README.md` - Guide des migrations
- `health_check.sql` - Vérification complète
- `fix_complete.sql` - Réparation d'urgence

### **Commandes Rapides**

```sql
-- Recharger le schéma
NOTIFY pgrst, 'reload schema';

-- Lister les tables
\dt

-- Décrire une table
\d table_name

-- Voir les policies
SELECT * FROM pg_policies WHERE tablename = 'table_name';
```

---

## 🚨 **En Cas de Problème**

### **Étape 1 : Identifier**
```sql
-- Exécuter health_check.sql
-- Regarder les logs Supabase
```

### **Étape 2 : Diagnostiquer**
- Cache Supabase ? → `NOTIFY pgrst, 'reload schema'`
- RLS bloquant ? → Vérifier les policies
- Query lente ? → Vérifier les index

### **Étape 3 : Résoudre**
- Créer une migration de fix
- Tester sur un projet de staging si possible
- Appliquer en production
- Vérifier avec health_check

### **Étape 4 : Documenter**
- Noter le problème et la solution
- Mettre à jour ce document si nécessaire
- Créer un ticket si récurrent

---

## ✅ **Checklist Avant Chaque Déploiement**

- [ ] Migration testée localement
- [ ] Commentaires clairs dans le SQL
- [ ] RLS policies vérifiées
- [ ] Index créés sur les FK
- [ ] `NOTIFY pgrst, 'reload schema'` à la fin
- [ ] Documentation mise à jour
- [ ] Backup des données importantes
- [ ] Health check après déploiement

---

**📝 Dernière mise à jour : 2025-12-16**

