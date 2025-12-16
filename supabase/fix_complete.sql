-- =====================================================
-- FIX COMPLET SUPABASE - CLIENTS & PRODUCTS
-- =====================================================
-- Ce script va recréer proprement les tables et forcer le cache

-- 1. DÉSACTIVER TEMPORAIREMENT LES FOREIGN KEYS
SET session_replication_role = 'replica';

-- 2. SUPPRIMER LES TABLES EXISTANTES
DROP TABLE IF EXISTS job_items CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS clients CASCADE;

-- 3. RECRÉER LA TABLE CLIENTS
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    postal_code VARCHAR(10),
    city VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(255),
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherche rapide
CREATE INDEX idx_clients_company_id ON clients(company_id);
CREATE INDEX idx_clients_name ON clients(name);

-- 4. RECRÉER LA TABLE PRODUCTS
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    reference VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    unit_price DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(50) DEFAULT 'unité',
    category VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherche rapide
CREATE INDEX idx_products_company_id ON products(company_id);
CREATE INDEX idx_products_reference ON products(reference);
CREATE INDEX idx_products_name ON products(name);

-- 5. RECRÉER LA TABLE JOBS
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id),
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending_audio',
    audio_file_path TEXT,
    audio_duration_seconds INTEGER,
    transcription_text TEXT,
    transcription_confidence DECIMAL(5, 2),
    extracted_data JSONB,
    extraction_confidence DECIMAL(5, 2),
    human_validation JSONB,
    validated_at TIMESTAMP WITH TIME ZONE,
    validated_by UUID REFERENCES users(id),
    total_amount DECIMAL(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour jobs
CREATE INDEX idx_jobs_company_id ON jobs(company_id);
CREATE INDEX idx_jobs_created_by ON jobs(created_by);
CREATE INDEX idx_jobs_client_id ON jobs(client_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);

-- 6. RECRÉER LA TABLE JOB_ITEMS
CREATE TABLE job_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    description VARCHAR(255) NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(50) DEFAULT 'unité',
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour job_items
CREATE INDEX idx_job_items_job_id ON job_items(job_id);
CREATE INDEX idx_job_items_product_id ON job_items(product_id);

-- 7. RÉACTIVER LES FOREIGN KEYS
SET session_replication_role = 'origin';

-- 8. ACTIVER ROW LEVEL SECURITY
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_items ENABLE ROW LEVEL SECURITY;

-- 9. RLS POLICIES - CLIENTS
CREATE POLICY "Users can view own company clients"
    ON clients FOR SELECT
    USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can insert own company clients"
    ON clients FOR INSERT
    WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can update own company clients"
    ON clients FOR UPDATE
    USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can delete own company clients"
    ON clients FOR DELETE
    USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- 10. RLS POLICIES - PRODUCTS
CREATE POLICY "Users can view own company products"
    ON products FOR SELECT
    USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can insert own company products"
    ON products FOR INSERT
    WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can update own company products"
    ON products FOR UPDATE
    USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can delete own company products"
    ON products FOR DELETE
    USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- 11. RLS POLICIES - JOBS
CREATE POLICY "Users can view own company jobs"
    ON jobs FOR SELECT
    USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can insert own jobs"
    ON jobs FOR INSERT
    WITH CHECK (
        company_id IN (SELECT company_id FROM users WHERE id = auth.uid())
        AND created_by = auth.uid()
    );

CREATE POLICY "Users can update own jobs"
    ON jobs FOR UPDATE
    USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can delete own jobs"
    ON jobs FOR DELETE
    USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- 12. RLS POLICIES - JOB_ITEMS
CREATE POLICY "Users can view job items"
    ON job_items FOR SELECT
    USING (job_id IN (
        SELECT id FROM jobs WHERE company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    ));

CREATE POLICY "Users can insert job items"
    ON job_items FOR INSERT
    WITH CHECK (job_id IN (
        SELECT id FROM jobs WHERE company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    ));

CREATE POLICY "Users can update job items"
    ON job_items FOR UPDATE
    USING (job_id IN (
        SELECT id FROM jobs WHERE company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    ));

CREATE POLICY "Users can delete job items"
    ON job_items FOR DELETE
    USING (job_id IN (
        SELECT id FROM jobs WHERE company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    ));

-- 13. FORCER LE RECHARGEMENT DU CACHE
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- 14. VÉRIFICATION FINALE
SELECT 
    'TABLES CRÉÉES' as status,
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND t.table_name = table_name) as nb_columns
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_name IN ('clients', 'products', 'jobs', 'job_items')
ORDER BY table_name;

-- 15. VÉRIFIER LES COLONNES COMPANY_ID
SELECT 
    'COLONNES COMPANY_ID' as status,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name IN ('clients', 'products', 'jobs')
    AND column_name = 'company_id';

