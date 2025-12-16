-- =====================================================
-- FIX: Politiques RLS pour la table users
-- =====================================================

-- Supprimer l'ancienne politique de lecture trop restrictive
DROP POLICY IF EXISTS "Users can view own company users" ON users;

-- Nouvelle politique : les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (id = auth.uid());

-- Nouvelle politique : les utilisateurs peuvent voir les profils de leur entreprise
CREATE POLICY "Users can view company users"
    ON users FOR SELECT
    USING (company_id IN (
        SELECT company_id FROM users WHERE id = auth.uid()
    ));

-- Nouvelle politique : permettre l'insertion lors de l'inscription
CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (id = auth.uid());

-- Politique de mise à jour (déjà existante, mais on la recrée pour être sûr)
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());


