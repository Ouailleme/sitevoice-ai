-- =====================================================
-- 🔍 DIAGNOSTIC COMPLET - À exécuter dans SQL Editor
-- =====================================================

-- =====================================================
-- 1️⃣ VÉRIFIER SI LES TABLES EXISTENT
-- =====================================================

SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('companies', 'users', 'clients', 'products', 'jobs', 'job_items') 
        THEN '✅ Existe'
        ELSE '⏳ Attendue'
    END as status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('companies', 'users', 'clients', 'products', 'jobs', 'job_items')
ORDER BY table_name;

-- =====================================================
-- 2️⃣ VÉRIFIER LES USERS AUTH
-- =====================================================

SELECT 
    'Users auth' as type,
    COUNT(*) as count
FROM auth.users;

-- =====================================================
-- 3️⃣ VÉRIFIER LES PROFILS
-- =====================================================

SELECT 
    'Profils users' as type,
    COUNT(*) as count
FROM users;

-- =====================================================
-- 4️⃣ VÉRIFIER LE TRIGGER
-- =====================================================

SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation,
    CASE 
        WHEN trigger_name = 'on_auth_user_created' THEN '✅ Trigger OK'
        ELSE '⚠️ Autre trigger'
    END as status
FROM information_schema.triggers
WHERE event_object_schema = 'auth'
  AND event_object_table = 'users';

-- =====================================================
-- 5️⃣ VÉRIFIER LA FONCTION DU TRIGGER
-- =====================================================

SELECT 
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name = 'handle_new_user' THEN '✅ Fonction OK'
        ELSE '⏳ Autre fonction'
    END as status
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'handle_new_user';

-- =====================================================
-- 6️⃣ RÉSUMÉ
-- =====================================================

DO $$
DECLARE
    v_tables_count INT;
    v_trigger_exists BOOLEAN;
    v_function_exists BOOLEAN;
BEGIN
    -- Compter les tables
    SELECT COUNT(*) INTO v_tables_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('companies', 'users', 'clients', 'products', 'jobs', 'job_items');
    
    -- Vérifier le trigger
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers
        WHERE trigger_name = 'on_auth_user_created'
    ) INTO v_trigger_exists;
    
    -- Vérifier la fonction
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_name = 'handle_new_user'
    ) INTO v_function_exists;
    
    RAISE NOTICE '';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '📊 DIAGNOSTIC COMPLET';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '📋 Tables créées : %/6', v_tables_count;
    RAISE NOTICE '🤖 Trigger auto-profile : %', CASE WHEN v_trigger_exists THEN '✅ Existe' ELSE '❌ Manquant' END;
    RAISE NOTICE '⚙️ Fonction handle_new_user : %', CASE WHEN v_function_exists THEN '✅ Existe' ELSE '❌ Manquante' END;
    RAISE NOTICE '';
    
    IF v_tables_count = 0 THEN
        RAISE NOTICE '❌ AUCUNE TABLE N''EXISTE !';
        RAISE NOTICE '👉 Tu dois exécuter RESET_DATABASE.sql d''abord';
    ELSIF v_tables_count < 6 THEN
        RAISE NOTICE '⚠️ CERTAINES TABLES MANQUENT';
        RAISE NOTICE '👉 Exécute RESET_DATABASE.sql pour tout recréer';
    ELSIF NOT v_trigger_exists THEN
        RAISE NOTICE '⚠️ TRIGGER MANQUANT';
        RAISE NOTICE '👉 Exécute RESET_DATABASE.sql pour créer le trigger';
    ELSE
        RAISE NOTICE '✅ TOUT EST PRÊT !';
        RAISE NOTICE '👉 Tu peux tester l''inscription dans l''app';
    END IF;
    
    RAISE NOTICE '=====================================================';
END $$;

