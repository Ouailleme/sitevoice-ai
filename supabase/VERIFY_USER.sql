-- =====================================================
-- 🔍 VÉRIFIER L'ÉTAT DU USER ET LE CONFIRMER
-- =====================================================

-- =====================================================
-- 1️⃣ VOIR L'ÉTAT DU USER
-- =====================================================

SELECT 
    id,
    email,
    email_confirmed_at,
    last_sign_in_at,
    created_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN '❌ PAS CONFIRMÉ (PROBLÈME !)'
        ELSE '✅ Confirmé'
    END as confirmation_status,
    CASE 
        WHEN last_sign_in_at IS NULL THEN '⚠️ Jamais connecté'
        ELSE '✅ Déjà connecté'
    END as login_status
FROM auth.users
WHERE email = 'test@example.com'; -- Remplace par ton email si différent

-- =====================================================
-- 2️⃣ CONFIRMER LE USER (SI PAS CONFIRMÉ)
-- =====================================================

-- Si email_confirmed_at est NULL, exécute ce bloc :

UPDATE auth.users
SET 
    email_confirmed_at = NOW(),
    confirmed_at = NOW()
WHERE email = 'test@example.com' -- Remplace par ton email si différent
  AND email_confirmed_at IS NULL;

-- =====================================================
-- 3️⃣ VÉRIFIER À NOUVEAU
-- =====================================================

SELECT 
    email,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN '✅ USER CONFIRMÉ - TU PEUX TE CONNECTER !'
        ELSE '❌ PROBLÈME : User pas confirmé'
    END as status
FROM auth.users
WHERE email = 'test@example.com';

-- =====================================================
-- 4️⃣ VOIR LE PROFIL COMPLET
-- =====================================================

SELECT 
    au.email as auth_email,
    au.email_confirmed_at,
    u.full_name,
    u.role,
    c.name as company_name,
    CASE 
        WHEN au.email_confirmed_at IS NULL THEN '❌ USER PAS CONFIRMÉ'
        WHEN u.id IS NULL THEN '❌ PROFIL MANQUANT'
        WHEN c.id IS NULL THEN '❌ COMPANY MANQUANTE'
        ELSE '✅ TOUT OK'
    END as status
FROM auth.users au
LEFT JOIN users u ON u.id = au.id
LEFT JOIN companies c ON c.id = u.company_id
WHERE au.email = 'test@example.com';

