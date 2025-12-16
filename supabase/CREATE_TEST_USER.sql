-- =====================================================
-- 👤 CRÉER UN UTILISATEUR DE TEST MANUELLEMENT
-- =====================================================
-- Utilise ce script pour créer un user de test
-- sans passer par l'inscription dans l'app
-- =====================================================

-- ⚠️ ATTENTION : Change l'email et le password ci-dessous !

-- =====================================================
-- ÉTAPE 1 : Crée le user dans Supabase Auth Dashboard
-- =====================================================

-- Va sur Supabase Dashboard → Authentication → Users
-- Clique sur "Add user" → "Create new user"
-- Email: test@example.com
-- Password: Test1234!
-- Clique sur "Create user"
--
-- COPIE L'ID DU USER (format UUID)
-- Exemple: 12345678-1234-1234-1234-123456789abc

-- =====================================================
-- ÉTAPE 2 : Exécute ce script en remplaçant les valeurs
-- =====================================================

DO $$
DECLARE
    -- ⚠️ REMPLACE CES VALEURS ⚠️
    v_user_id UUID := 'COLLE_TON_USER_ID_ICI'; -- ID copié depuis Auth Dashboard
    v_email TEXT := 'test@example.com'; -- Ton email
    v_full_name TEXT := 'Test User'; -- Ton nom
    v_company_name TEXT := 'Test Company'; -- Nom de ta société
    
    v_company_id UUID;
BEGIN
    -- Vérifier que l'ID n'est pas le placeholder
    IF v_user_id::TEXT = 'COLLE_TON_USER_ID_ICI' THEN
        RAISE EXCEPTION '⚠️ Tu dois remplacer v_user_id par le vrai ID !';
    END IF;
    
    -- Créer la company
    INSERT INTO companies (name, subscription_status)
    VALUES (v_company_name, 'trial')
    RETURNING id INTO v_company_id;
    
    RAISE NOTICE '✅ Company créée : % (ID: %)', v_company_name, v_company_id;
    
    -- Créer le profil user
    INSERT INTO users (id, email, full_name, role, company_id)
    VALUES (v_user_id, v_email, v_full_name, 'admin', v_company_id)
    ON CONFLICT (id) DO UPDATE
    SET 
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        company_id = EXCLUDED.company_id;
    
    RAISE NOTICE '✅ Profil créé pour : % (ID: %)', v_email, v_user_id;
    RAISE NOTICE '';
    RAISE NOTICE '🎉 USER DE TEST CRÉÉ !';
    RAISE NOTICE '📧 Email : %', v_email;
    RAISE NOTICE '🔑 Password : (celui que tu as mis dans Auth Dashboard)';
    RAISE NOTICE '';
    RAISE NOTICE '👉 Tu peux maintenant te connecter dans l''app avec ces identifiants';
END $$;

-- =====================================================
-- VÉRIFICATION
-- =====================================================

SELECT 
    u.email,
    u.full_name,
    u.role,
    c.name as company_name,
    '✅ Profil OK' as status
FROM users u
JOIN companies c ON c.id = u.company_id
ORDER BY u.created_at DESC
LIMIT 1;

