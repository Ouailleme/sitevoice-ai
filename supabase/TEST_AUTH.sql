-- =====================================================
-- 🧪 TESTER L'AUTHENTIFICATION
-- =====================================================
-- Exécute ces requêtes APRÈS avoir fait un signup/login
-- dans l'app Flutter pour vérifier que tout fonctionne
-- =====================================================

-- =====================================================
-- 1️⃣ VOIR TOUS LES USERS AUTH
-- =====================================================

SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN '✅ Confirmé'
        ELSE '⏳ En attente'
    END as email_status
FROM auth.users
ORDER BY created_at DESC;

-- =====================================================
-- 2️⃣ VÉRIFIER LES PROFILS USERS
-- =====================================================

SELECT 
    u.id,
    u.email,
    u.full_name,
    u.role,
    c.name as company_name,
    c.subscription_status,
    u.created_at
FROM users u
JOIN companies c ON c.id = u.company_id
ORDER BY u.created_at DESC;

-- =====================================================
-- 3️⃣ DIAGNOSTIC COMPLET
-- =====================================================

SELECT 
    au.id as auth_id,
    au.email,
    au.email_confirmed_at,
    u.id as profile_id,
    u.full_name,
    u.role,
    u.company_id,
    c.name as company_name,
    c.subscription_status,
    CASE 
        WHEN u.id IS NULL THEN '❌ PROFIL MANQUANT'
        WHEN u.company_id IS NULL THEN '❌ COMPANY_ID NULL'
        WHEN c.id IS NULL THEN '❌ COMPANY MANQUANTE'
        ELSE '✅ TOUT OK'
    END as status
FROM auth.users au
LEFT JOIN users u ON u.id = au.id
LEFT JOIN companies c ON c.id = u.company_id
ORDER BY au.created_at DESC;

-- =====================================================
-- 4️⃣ VÉRIFIER LES POLICIES RLS
-- =====================================================

SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN '👁️ Vue'
        WHEN cmd = 'INSERT' THEN '➕ Création'
        WHEN cmd = 'UPDATE' THEN '✏️ Modification'
        WHEN cmd = 'DELETE' THEN '🗑️ Suppression'
        ELSE cmd
    END as operation
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('users', 'companies', 'clients', 'products', 'jobs', 'job_items')
ORDER BY tablename, cmd, policyname;

-- =====================================================
-- 5️⃣ TESTER get_user_company_id()
-- =====================================================

-- Note : Cette fonction retourne le company_id de l'utilisateur connecté
-- Elle sera NULL si exécutée en SQL Editor (pas de auth.uid())

SELECT get_user_company_id() as my_company_id;

-- Pour tester avec un user spécifique :
SELECT 
    id as user_id,
    email,
    company_id,
    (SELECT name FROM companies WHERE id = users.company_id) as company_name
FROM users
LIMIT 1;

-- =====================================================
-- 6️⃣ COMPTER LES DONNÉES
-- =====================================================

SELECT 
    'companies' as table_name,
    COUNT(*) as count,
    CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '❌' END as status
FROM companies
UNION ALL
SELECT 'users', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '❌' END FROM users
UNION ALL
SELECT 'clients', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⏳' END FROM clients
UNION ALL
SELECT 'products', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⏳' END FROM products
UNION ALL
SELECT 'jobs', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⏳' END FROM jobs
ORDER BY table_name;

-- =====================================================
-- 7️⃣ VOIR LES DERNIÈRES ACTIVITÉS
-- =====================================================

SELECT 
    'Dernier signup' as event,
    email,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================
-- 8️⃣ TESTER LE TRIGGER AUTO-CREATE
-- =====================================================

-- Vérifie que le trigger existe
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- =====================================================
-- 9️⃣ SI UN USER N'A PAS DE PROFIL, LE CRÉER MANUELLEMENT
-- =====================================================

-- Remplace 'USER_ID_ICI' et 'email@example.com' par les vraies valeurs

/*
DO $$
DECLARE
    v_user_id UUID := 'USER_ID_ICI'; -- Copie l'ID depuis la requête 1
    v_email TEXT := 'email@example.com'; -- Email du user
    v_company_id UUID;
BEGIN
    -- Créer une company
    INSERT INTO companies (name, subscription_status)
    VALUES ('Ma Société', 'trial')
    RETURNING id INTO v_company_id;
    
    -- Créer le profil
    INSERT INTO users (id, email, full_name, role, company_id)
    VALUES (
        v_user_id,
        v_email,
        'Mon Nom',
        'admin',
        v_company_id
    )
    ON CONFLICT (id) DO NOTHING;
    
    RAISE NOTICE '✅ Profil créé pour user %', v_user_id;
END $$;
*/

-- =====================================================
-- 🔟 RÉSUMÉ FINAL
-- =====================================================

DO $$
DECLARE
    v_auth_users_count INT;
    v_profile_users_count INT;
    v_companies_count INT;
BEGIN
    SELECT COUNT(*) INTO v_auth_users_count FROM auth.users;
    SELECT COUNT(*) INTO v_profile_users_count FROM users;
    SELECT COUNT(*) INTO v_companies_count FROM companies;
    
    RAISE NOTICE '';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '📊 RÉSUMÉ DE LA BASE DE DONNÉES';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '👥 Users auth : %', v_auth_users_count;
    RAISE NOTICE '👤 Profils users : %', v_profile_users_count;
    RAISE NOTICE '🏢 Companies : %', v_companies_count;
    RAISE NOTICE '';
    
    IF v_auth_users_count = 0 THEN
        RAISE NOTICE '⚠️ Aucun utilisateur. Crée un compte dans l''app !';
    ELSIF v_profile_users_count < v_auth_users_count THEN
        RAISE NOTICE '⚠️ Certains users auth n''ont pas de profil !';
        RAISE NOTICE '👉 Exécute la requête 9 pour créer les profils manquants';
    ELSE
        RAISE NOTICE '✅ Tous les users ont un profil !';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '=====================================================';
END $$;

