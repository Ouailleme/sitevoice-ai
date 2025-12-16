-- =====================================================
-- HEALTH CHECK - VÉRIFICATION DE LA BASE DE DONNÉES
-- =====================================================
-- Ce script vérifie l'état de santé de ta base de données
-- Exécute-le régulièrement pour détecter les problèmes
-- =====================================================

-- 1. VÉRIFIER LES TABLES
SELECT 
    '1. TABLES' as check_type,
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND t.table_name = table_name) as nb_columns,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name)::regclass)) as size
FROM information_schema.tables t
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. VÉRIFIER LES RLS POLICIES
SELECT 
    '2. RLS POLICIES' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 3. VÉRIFIER LES INDEX
SELECT 
    '3. INDEX' as check_type,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 4. VÉRIFIER LES FOREIGN KEYS
SELECT
    '4. FOREIGN KEYS' as check_type,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- 5. VÉRIFIER LES COLONNES CRITIQUES
SELECT 
    '5. COLONNES COMPANY_ID' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
    AND column_name = 'company_id'
ORDER BY table_name;

-- 6. COMPTER LES DONNÉES
SELECT '6. NOMBRE D''ENREGISTREMENTS' as check_type;

SELECT 'companies' as table_name, COUNT(*) as count FROM companies
UNION ALL
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'clients' as table_name, COUNT(*) as count FROM clients
UNION ALL
SELECT 'products' as table_name, COUNT(*) as count FROM products
UNION ALL
SELECT 'jobs' as table_name, COUNT(*) as count FROM jobs
UNION ALL
SELECT 'job_items' as table_name, COUNT(*) as count FROM job_items;

-- 7. VÉRIFIER TON UTILISATEUR ACTUEL
SELECT 
    '7. MON PROFIL' as check_type,
    id,
    email,
    full_name,
    role,
    company_id,
    is_active
FROM users
WHERE id = auth.uid();

-- 8. VÉRIFIER LA COMPANY
SELECT 
    '8. MA COMPANY' as check_type,
    c.id,
    c.name,
    c.subscription_status,
    COUNT(u.id) as nb_users,
    COUNT(cl.id) as nb_clients,
    COUNT(p.id) as nb_products,
    COUNT(j.id) as nb_jobs
FROM companies c
LEFT JOIN users u ON u.company_id = c.id
LEFT JOIN clients cl ON cl.company_id = c.id
LEFT JOIN products p ON p.company_id = c.id
LEFT JOIN jobs j ON j.company_id = c.id
WHERE c.id IN (SELECT company_id FROM users WHERE id = auth.uid())
GROUP BY c.id, c.name, c.subscription_status;

-- 9. VÉRIFIER LES FONCTIONS
SELECT 
    '9. FONCTIONS' as check_type,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- 10. STATUT FINAL
SELECT 
    '10. STATUT' as check_type,
    'Base de données opérationnelle ✅' as message,
    NOW() as check_time;

