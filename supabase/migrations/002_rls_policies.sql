-- =====================================================
-- MIGRATION 002: ROW LEVEL SECURITY POLICIES
-- =====================================================
-- Date: 2025-12-16
-- Description: Mise en place des politiques de sécurité RLS
-- =====================================================

-- =====================================================
-- FUNCTION: get_user_company_id()
-- =====================================================
CREATE OR REPLACE FUNCTION get_user_company_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
    RETURN (SELECT company_id FROM users WHERE id = auth.uid());
END;
$$;

-- =====================================================
-- RLS POLICIES: companies
-- =====================================================
DROP POLICY IF EXISTS "Users can view own company" ON companies;
CREATE POLICY "Users can view own company"
    ON companies FOR SELECT
    USING (id = get_user_company_id());

DROP POLICY IF EXISTS "Admins can update own company" ON companies;
CREATE POLICY "Admins can update own company"
    ON companies FOR UPDATE
    USING (
        id = get_user_company_id()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- =====================================================
-- RLS POLICIES: users
-- =====================================================
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can view company users" ON users;
CREATE POLICY "Users can view company users"
    ON users FOR SELECT
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (id = auth.uid());

-- =====================================================
-- RLS POLICIES: clients
-- =====================================================
DROP POLICY IF EXISTS "Users can view own company clients" ON clients;
CREATE POLICY "Users can view own company clients"
    ON clients FOR SELECT
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can insert own company clients" ON clients;
CREATE POLICY "Users can insert own company clients"
    ON clients FOR INSERT
    WITH CHECK (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can update own company clients" ON clients;
CREATE POLICY "Users can update own company clients"
    ON clients FOR UPDATE
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can delete own company clients" ON clients;
CREATE POLICY "Users can delete own company clients"
    ON clients FOR DELETE
    USING (company_id = get_user_company_id());

-- =====================================================
-- RLS POLICIES: products
-- =====================================================
DROP POLICY IF EXISTS "Users can view own company products" ON products;
CREATE POLICY "Users can view own company products"
    ON products FOR SELECT
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can insert own company products" ON products;
CREATE POLICY "Users can insert own company products"
    ON products FOR INSERT
    WITH CHECK (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can update own company products" ON products;
CREATE POLICY "Users can update own company products"
    ON products FOR UPDATE
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can delete own company products" ON products;
CREATE POLICY "Users can delete own company products"
    ON products FOR DELETE
    USING (company_id = get_user_company_id());

-- =====================================================
-- RLS POLICIES: jobs
-- =====================================================
DROP POLICY IF EXISTS "Users can view own company jobs" ON jobs;
CREATE POLICY "Users can view own company jobs"
    ON jobs FOR SELECT
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can insert own jobs" ON jobs;
CREATE POLICY "Users can insert own jobs"
    ON jobs FOR INSERT
    WITH CHECK (
        company_id = get_user_company_id()
        AND created_by = auth.uid()
    );

DROP POLICY IF EXISTS "Users can update own company jobs" ON jobs;
CREATE POLICY "Users can update own company jobs"
    ON jobs FOR UPDATE
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can delete own company jobs" ON jobs;
CREATE POLICY "Users can delete own company jobs"
    ON jobs FOR DELETE
    USING (company_id = get_user_company_id());

-- =====================================================
-- RLS POLICIES: job_items
-- =====================================================
DROP POLICY IF EXISTS "Users can view job items" ON job_items;
CREATE POLICY "Users can view job items"
    ON job_items FOR SELECT
    USING (
        job_id IN (
            SELECT id FROM jobs 
            WHERE company_id = get_user_company_id()
        )
    );

DROP POLICY IF EXISTS "Users can insert job items" ON job_items;
CREATE POLICY "Users can insert job items"
    ON job_items FOR INSERT
    WITH CHECK (
        job_id IN (
            SELECT id FROM jobs 
            WHERE company_id = get_user_company_id()
        )
    );

DROP POLICY IF EXISTS "Users can update job items" ON job_items;
CREATE POLICY "Users can update job items"
    ON job_items FOR UPDATE
    USING (
        job_id IN (
            SELECT id FROM jobs 
            WHERE company_id = get_user_company_id()
        )
    );

DROP POLICY IF EXISTS "Users can delete job items" ON job_items;
CREATE POLICY "Users can delete job items"
    ON job_items FOR DELETE
    USING (
        job_id IN (
            SELECT id FROM jobs 
            WHERE company_id = get_user_company_id()
        )
    );

-- Migration completed
NOTIFY pgrst, 'reload schema';

