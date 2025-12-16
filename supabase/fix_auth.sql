-- 🔧 FIX AUTHENTIFICATION - Vérifier et réparer la config

-- =====================================================
-- 1. VÉRIFIER LES UTILISATEURS EXISTANTS
-- =====================================================

SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 2. VÉRIFIER LA TABLE USERS (PROFILS)
-- =====================================================

SELECT 
    u.id,
    u.email,
    u.full_name,
    u.role,
    u.company_id,
    c.name as company_name
FROM users u
LEFT JOIN companies c ON c.id = u.company_id
ORDER BY u.created_at DESC;

-- =====================================================
-- 3. SI UN USER AUTH EXISTE MAIS PAS DE PROFIL, LE CRÉER
-- =====================================================

-- Trouver les users sans profil
SELECT 
    au.id,
    au.email,
    au.created_at
FROM auth.users au
LEFT JOIN users u ON u.id = au.id
WHERE u.id IS NULL;

-- =====================================================
-- 4. CRÉER UNE COMPANY ET UN PROFIL POUR UN USER EXISTANT
-- =====================================================

-- Remplacer 'USER_ID_ICI' et 'email@example.com' par les vraies valeurs

DO $$
DECLARE
    v_user_id UUID := 'USER_ID_ICI'; -- À remplacer
    v_email TEXT := 'email@example.com'; -- À remplacer
    v_company_id UUID;
BEGIN
    -- Créer une company si elle n'existe pas
    INSERT INTO companies (name, subscription_status)
    VALUES ('Ma Société', 'trial')
    RETURNING id INTO v_company_id;
    
    -- Créer le profil user
    INSERT INTO users (id, email, full_name, role, company_id)
    VALUES (
        v_user_id,
        v_email,
        'Utilisateur',
        'admin',
        v_company_id
    )
    ON CONFLICT (id) DO NOTHING;
    
    RAISE NOTICE 'Profil créé pour user % avec company %', v_user_id, v_company_id;
END $$;

-- =====================================================
-- 5. VÉRIFIER LES RLS POLICIES
-- =====================================================

-- Désactiver temporairement RLS pour tester (ATTENTION: à réactiver après!)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE companies DISABLE ROW LEVEL SECURITY;

-- Vérifier les policies existantes
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('users', 'companies')
ORDER BY tablename, policyname;

-- =====================================================
-- 6. FIX RAPIDE: CRÉER UN USER DE TEST
-- =====================================================

-- Créer un user de test avec email/password
-- NOTE: Fais d'abord un signUp dans l'app ou via Supabase Dashboard

-- Exemple de création manuelle (après signUp dans l'app):
/*
-- 1. Récupère l'ID du user qui vient de s'inscrire
SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 1;

-- 2. Crée la company et le profil
DO $$
DECLARE
    v_user_id UUID := 'ID_DU_USER_ICI';
    v_company_id UUID;
BEGIN
    INSERT INTO companies (name, subscription_status)
    VALUES ('Test Company', 'trial')
    RETURNING id INTO v_company_id;
    
    INSERT INTO users (id, email, full_name, role, company_id)
    SELECT 
        v_user_id,
        email,
        'Test User',
        'admin',
        v_company_id
    FROM auth.users
    WHERE id = v_user_id;
END $$;
*/

-- =====================================================
-- 7. SOLUTION TEMPORAIRE: TRIGGER AUTO-CREATE PROFILE
-- =====================================================

-- Créer un trigger qui crée automatiquement le profil après signup

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_company_id UUID;
BEGIN
    -- Créer une company pour le nouvel utilisateur
    INSERT INTO public.companies (name, subscription_status)
    VALUES ('Nouvelle Société', 'trial')
    RETURNING id INTO v_company_id;
    
    -- Créer le profil
    INSERT INTO public.users (id, email, full_name, role, company_id)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        'admin',
        v_company_id
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger (drop first si existe déjà)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 8. TEST DE CONNEXION
-- =====================================================

-- Vérifier qu'un user peut se connecter
-- (Exécute dans Supabase SQL Editor)

SELECT 
    au.id as auth_id,
    au.email,
    au.email_confirmed_at,
    u.id as profile_id,
    u.full_name,
    u.role,
    c.name as company_name,
    CASE 
        WHEN u.id IS NULL THEN '❌ PROFIL MANQUANT'
        WHEN c.id IS NULL THEN '❌ COMPANY MANQUANTE'
        ELSE '✅ OK'
    END as status
FROM auth.users au
LEFT JOIN users u ON u.id = au.id
LEFT JOIN companies c ON c.id = u.company_id
ORDER BY au.created_at DESC;

