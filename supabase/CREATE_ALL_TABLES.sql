-- =====================================================
-- 📋 CRÉER TOUTES LES TABLES NÉCESSAIRES
-- =====================================================
-- À exécuter dans Supabase SQL Editor
-- Ce script crée UNIQUEMENT les tables manquantes
-- (ne supprime pas users et companies existantes)
-- =====================================================

-- =====================================================
-- 1️⃣ TABLE CLIENTS
-- =====================================================

CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    name TEXT NOT NULL,
    address TEXT,
    postal_code TEXT,
    city TEXT,
    phone TEXT,
    email TEXT,
    notes TEXT,
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_clients_company ON clients(company_id);
CREATE INDEX IF NOT EXISTS idx_clients_name ON clients(name);

-- =====================================================
-- 2️⃣ TABLE PRODUCTS
-- =====================================================

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    reference TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    unit_price NUMERIC(10, 2) NOT NULL DEFAULT 0,
    unit TEXT DEFAULT 'unité',
    category TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(company_id, reference)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_products_company ON products(company_id);
CREATE INDEX IF NOT EXISTS idx_products_reference ON products(reference);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);

-- =====================================================
-- 3️⃣ TABLE JOBS
-- =====================================================

CREATE TABLE IF NOT EXISTS jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id),
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    
    status TEXT NOT NULL DEFAULT 'pending_audio',
    
    -- Audio
    audio_url TEXT,
    audio_duration_seconds INTEGER,
    transcription_text TEXT,
    
    -- Photos
    photo_urls TEXT[],
    
    -- GPS
    gps_latitude NUMERIC(10, 8),
    gps_longitude NUMERIC(11, 8),
    gps_captured_at TIMESTAMPTZ,
    
    -- Signature
    signature_url TEXT,
    signature_captured_at TIMESTAMPTZ,
    
    -- IA
    ai_confidence_score NUMERIC(5, 2),
    ai_extracted_data JSONB,
    ai_processing_error TEXT,
    ai_requires_clarification BOOLEAN DEFAULT FALSE,
    
    -- Intervention
    intervention_date TIMESTAMPTZ,
    intervention_duration_hours NUMERIC(5, 2),
    
    -- Financier
    total_ht NUMERIC(10, 2),
    total_ttc NUMERIC(10, 2),
    
    notes TEXT,
    synced_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs(company_id);
CREATE INDEX IF NOT EXISTS idx_jobs_created_by ON jobs(created_by);
CREATE INDEX IF NOT EXISTS idx_jobs_client ON jobs(client_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);

-- =====================================================
-- 4️⃣ TABLE JOB_ITEMS
-- =====================================================

CREATE TABLE IF NOT EXISTS job_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    
    product_name TEXT NOT NULL,
    product_reference TEXT,
    quantity NUMERIC(10, 2) NOT NULL,
    unit TEXT NOT NULL DEFAULT 'unité',
    unit_price NUMERIC(10, 2) NOT NULL,
    total_price NUMERIC(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_job_items_job ON job_items(job_id);
CREATE INDEX IF NOT EXISTS idx_job_items_product ON job_items(product_id);

-- =====================================================
-- 5️⃣ TRIGGERS UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_clients_updated_at ON clients;
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_job_items_updated_at ON job_items;
CREATE TRIGGER update_job_items_updated_at BEFORE UPDATE ON job_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 🔒 6️⃣ ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Activer RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_items ENABLE ROW LEVEL SECURITY;

-- Fonction helper
CREATE OR REPLACE FUNCTION get_user_company_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT company_id 
        FROM users 
        WHERE id = auth.uid()
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- POLICIES : CLIENTS
-- =====================================================

DROP POLICY IF EXISTS "Users can view company clients" ON clients;
CREATE POLICY "Users can view company clients"
    ON clients FOR SELECT
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can insert company clients" ON clients;
CREATE POLICY "Users can insert company clients"
    ON clients FOR INSERT
    WITH CHECK (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can update company clients" ON clients;
CREATE POLICY "Users can update company clients"
    ON clients FOR UPDATE
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can delete company clients" ON clients;
CREATE POLICY "Users can delete company clients"
    ON clients FOR DELETE
    USING (company_id = get_user_company_id());

-- =====================================================
-- POLICIES : PRODUCTS
-- =====================================================

DROP POLICY IF EXISTS "Users can view company products" ON products;
CREATE POLICY "Users can view company products"
    ON products FOR SELECT
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can insert company products" ON products;
CREATE POLICY "Users can insert company products"
    ON products FOR INSERT
    WITH CHECK (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can update company products" ON products;
CREATE POLICY "Users can update company products"
    ON products FOR UPDATE
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can delete company products" ON products;
CREATE POLICY "Users can delete company products"
    ON products FOR DELETE
    USING (company_id = get_user_company_id());

-- =====================================================
-- POLICIES : JOBS
-- =====================================================

DROP POLICY IF EXISTS "Users can view company jobs" ON jobs;
CREATE POLICY "Users can view company jobs"
    ON jobs FOR SELECT
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can insert company jobs" ON jobs;
CREATE POLICY "Users can insert company jobs"
    ON jobs FOR INSERT
    WITH CHECK (
        company_id = get_user_company_id() AND
        created_by = auth.uid()
    );

DROP POLICY IF EXISTS "Users can update company jobs" ON jobs;
CREATE POLICY "Users can update company jobs"
    ON jobs FOR UPDATE
    USING (company_id = get_user_company_id());

DROP POLICY IF EXISTS "Users can delete company jobs" ON jobs;
CREATE POLICY "Users can delete company jobs"
    ON jobs FOR DELETE
    USING (company_id = get_user_company_id());

-- =====================================================
-- POLICIES : JOB_ITEMS
-- =====================================================

DROP POLICY IF EXISTS "Users can view job items" ON job_items;
CREATE POLICY "Users can view job items"
    ON job_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM jobs
            WHERE jobs.id = job_items.job_id
            AND jobs.company_id = get_user_company_id()
        )
    );

DROP POLICY IF EXISTS "Users can insert job items" ON job_items;
CREATE POLICY "Users can insert job items"
    ON job_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM jobs
            WHERE jobs.id = job_items.job_id
            AND jobs.company_id = get_user_company_id()
        )
    );

DROP POLICY IF EXISTS "Users can update job items" ON job_items;
CREATE POLICY "Users can update job items"
    ON job_items FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM jobs
            WHERE jobs.id = job_items.job_id
            AND jobs.company_id = get_user_company_id()
        )
    );

DROP POLICY IF EXISTS "Users can delete job items" ON job_items;
CREATE POLICY "Users can delete job items"
    ON job_items FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM jobs
            WHERE jobs.id = job_items.job_id
            AND jobs.company_id = get_user_company_id()
        )
    );

-- =====================================================
-- ✅ 7️⃣ VÉRIFICATION
-- =====================================================

SELECT 
    'companies' as table_name,
    COUNT(*) as row_count,
    '✅' as status
FROM companies
UNION ALL
SELECT 'users', COUNT(*), '✅' FROM users
UNION ALL
SELECT 'clients', COUNT(*), '✅' FROM clients
UNION ALL
SELECT 'products', COUNT(*), '✅' FROM products
UNION ALL
SELECT 'jobs', COUNT(*), '✅' FROM jobs
UNION ALL
SELECT 'job_items', COUNT(*), '✅' FROM job_items
ORDER BY table_name;

-- Message de succès
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '✅ TOUTES LES TABLES SONT CRÉÉES !';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '📋 Tables : companies, users, clients, products, jobs, job_items';
    RAISE NOTICE '🔒 RLS activé avec policies';
    RAISE NOTICE '⚙️ Triggers updated_at créés';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 TU PEUX MAINTENANT :';
    RAISE NOTICE '1. Te connecter dans l''app';
    RAISE NOTICE '2. Créer des clients et produits';
    RAISE NOTICE '3. Enregistrer un audio';
    RAISE NOTICE '4. Tester l''extraction IA';
    RAISE NOTICE '=====================================================';
END $$;

