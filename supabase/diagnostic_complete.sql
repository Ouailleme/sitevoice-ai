-- =====================================================
-- DIAGNOSTIC COMPLET SUPABASE
-- =====================================================
-- Ce script va identifier le problème exact

-- 1. Vérifier ton utilisateur actuel
SELECT 
    'MON UTILISATEUR' as type,
    id,
    email,
    company_id,
    role,
    is_active
FROM users 
WHERE id = auth.uid();

-- 2. Vérifier que ta company existe
SELECT 
    'MA COMPANY' as type,
    c.id,
    c.name,
    c.subscription_status,
    COUNT(u.id) as nb_users
FROM companies c
LEFT JOIN users u ON u.company_id = c.id
WHERE c.id IN (SELECT company_id FROM users WHERE id = auth.uid())
GROUP BY c.id, c.name, c.subscription_status;

-- 3. Vérifier la structure de la table clients
SELECT 
    'COLONNES TABLE CLIENTS' as type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'clients'
ORDER BY ordinal_position;

-- 4. Vérifier la structure de la table products
SELECT 
    'COLONNES TABLE PRODUCTS' as type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- 5. Vérifier les RLS policies sur clients
SELECT 
    'RLS POLICIES CLIENTS' as type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'clients';

-- 6. Vérifier les RLS policies sur products
SELECT 
    'RLS POLICIES PRODUCTS' as type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'products';

-- 7. Test d'insertion dans clients (pour voir l'erreur exacte)
-- ATTENTION : Commente cette ligne si tu ne veux pas créer de données de test
-- INSERT INTO clients (company_id, name, email, created_by)
-- SELECT company_id, 'Test Client', 'test@test.com', id
-- FROM users WHERE id = auth.uid();

-- 8. Vérifier le cache PostgREST
SELECT 
    'CACHE POSTGREST' as type,
    pg_notify('pgrst', 'reload schema') as reload_schema,
    pg_notify('pgrst', 'reload config') as reload_config;

