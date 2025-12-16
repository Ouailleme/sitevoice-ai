-- =====================================================
-- SITEVOICE AI - DATABASE SCHEMA
-- =====================================================
-- Description : Schéma PostgreSQL pour application SaaS
--               de reporting vocal pour techniciens BTP
-- Version : 1.0
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: companies (Entreprises)
-- =====================================================
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    siret VARCHAR(14),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    subscription_status VARCHAR(50) DEFAULT 'trial', -- trial, active, cancelled, expired
    subscription_stripe_id VARCHAR(255),
    stripe_customer_id VARCHAR(255),
    subscription_ends_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLE: users (Utilisateurs/Techniciens)
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'tech', -- admin, tech
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    avatar_url TEXT,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLE: clients (Carnet d'adresses clients)
-- =====================================================
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

-- =====================================================
-- TABLE: products (Catalogue produits/services)
-- =====================================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    reference VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    unit_price DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(50) DEFAULT 'unité', -- unité, heure, m2, ml, etc.
    category VARCHAR(100), -- Matériel, Main d'oeuvre, Déplacement, etc.
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherche rapide
CREATE INDEX idx_products_company_id ON products(company_id);
CREATE INDEX idx_products_reference ON products(reference);
CREATE INDEX idx_products_name ON products(name);

-- =====================================================
-- TABLE: jobs (Interventions/Chantiers)
-- =====================================================
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id),
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    
    -- Status du job
    status VARCHAR(50) NOT NULL DEFAULT 'pending_audio', 
    -- pending_audio, processing, review_needed, validated, invoiced
    
    -- Audio & Transcription
    audio_url TEXT,
    audio_duration_seconds INTEGER,
    transcription_text TEXT,
    
    -- Multimodalité
    photo_urls TEXT[], -- URLs des photos jointes
    
    -- Preuve de présence (GPS)
    gps_latitude FLOAT,
    gps_longitude FLOAT,
    gps_captured_at TIMESTAMP WITH TIME ZONE,
    
    -- Signature client
    signature_url TEXT,
    signature_captured_at TIMESTAMP WITH TIME ZONE,
    
    -- IA Processing
    ai_confidence_score FLOAT, -- 0.0 à 1.0
    ai_extracted_data JSONB, -- Données brutes extraites par l'IA
    ai_processing_error TEXT,
    ai_requires_clarification BOOLEAN DEFAULT false, -- Flag si IA incertaine
    
    -- Données métier
    intervention_date DATE,
    intervention_duration_hours FLOAT,
    total_ht DECIMAL(10, 2),
    total_ttc DECIMAL(10, 2),
    notes TEXT,
    
    -- Tracking
    synced_at TIMESTAMP WITH TIME ZONE, -- NULL = pas encore sync
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX idx_jobs_company_id ON jobs(company_id);
CREATE INDEX idx_jobs_created_by ON jobs(created_by);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);
CREATE INDEX idx_jobs_synced_at ON jobs(synced_at);

-- =====================================================
-- TABLE: job_items (Lignes de facture)
-- =====================================================
CREATE TABLE job_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL, -- NULL si produit inconnu
    
    -- Données extraites
    description TEXT NOT NULL,
    quantity FLOAT NOT NULL,
    unit_price DECIMAL(10, 2),
    total_price DECIMAL(10, 2),
    
    -- Métadonnées
    is_validated BOOLEAN DEFAULT false, -- Validé par le technicien
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX idx_job_items_job_id ON job_items(job_id);
CREATE INDEX idx_job_items_product_id ON job_items(product_id);

-- =====================================================
-- TABLE: sync_queue (Queue de synchronisation offline)
-- =====================================================
CREATE TABLE sync_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL, -- job, client, product
    entity_id UUID NOT NULL,
    operation VARCHAR(20) NOT NULL, -- create, update, delete
    payload JSONB NOT NULL,
    retry_count INTEGER DEFAULT 0,
    last_error TEXT,
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_sync_queue_user_id ON sync_queue(user_id);
CREATE INDEX idx_sync_queue_status ON sync_queue(status);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS sur toutes les tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_queue ENABLE ROW LEVEL SECURITY;

-- Fonction helper pour récupérer la company de l'utilisateur
CREATE OR REPLACE FUNCTION get_user_company_id()
RETURNS UUID AS $$
    SELECT company_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- =====================================================
-- RLS POLICIES: Users
-- =====================================================
CREATE POLICY "Users can view own company users"
    ON users FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());

-- =====================================================
-- RLS POLICIES: Companies
-- =====================================================
CREATE POLICY "Users can view own company"
    ON companies FOR SELECT
    USING (id = get_user_company_id());

CREATE POLICY "Admins can update own company"
    ON companies FOR UPDATE
    USING (
        id = get_user_company_id() 
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- RLS POLICIES: Clients
-- =====================================================
CREATE POLICY "Users can view own company clients"
    ON clients FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Users can insert clients for own company"
    ON clients FOR INSERT
    WITH CHECK (company_id = get_user_company_id());

CREATE POLICY "Users can update own company clients"
    ON clients FOR UPDATE
    USING (company_id = get_user_company_id());

CREATE POLICY "Admins can delete own company clients"
    ON clients FOR DELETE
    USING (
        company_id = get_user_company_id()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- RLS POLICIES: Products
-- =====================================================
CREATE POLICY "Users can view own company products"
    ON products FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Users can insert products for own company"
    ON products FOR INSERT
    WITH CHECK (company_id = get_user_company_id());

CREATE POLICY "Users can update own company products"
    ON products FOR UPDATE
    USING (company_id = get_user_company_id());

CREATE POLICY "Admins can delete own company products"
    ON products FOR DELETE
    USING (
        company_id = get_user_company_id()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =====================================================
-- RLS POLICIES: Jobs
-- =====================================================
CREATE POLICY "Users can view own company jobs"
    ON jobs FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Users can insert jobs for own company"
    ON jobs FOR INSERT
    WITH CHECK (company_id = get_user_company_id() AND created_by = auth.uid());

CREATE POLICY "Users can update own jobs"
    ON jobs FOR UPDATE
    USING (company_id = get_user_company_id());

CREATE POLICY "Users can delete own jobs"
    ON jobs FOR DELETE
    USING (company_id = get_user_company_id() AND created_by = auth.uid());

-- =====================================================
-- RLS POLICIES: Job Items
-- =====================================================
CREATE POLICY "Users can view job items from own company"
    ON job_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM jobs 
            WHERE jobs.id = job_items.job_id 
            AND jobs.company_id = get_user_company_id()
        )
    );

CREATE POLICY "Users can insert job items for own company jobs"
    ON job_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM jobs 
            WHERE jobs.id = job_items.job_id 
            AND jobs.company_id = get_user_company_id()
        )
    );

CREATE POLICY "Users can update job items from own company"
    ON job_items FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM jobs 
            WHERE jobs.id = job_items.job_id 
            AND jobs.company_id = get_user_company_id()
        )
    );

CREATE POLICY "Users can delete job items from own company"
    ON job_items FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM jobs 
            WHERE jobs.id = job_items.job_id 
            AND jobs.company_id = get_user_company_id()
        )
    );

-- =====================================================
-- RLS POLICIES: Sync Queue
-- =====================================================
CREATE POLICY "Users can view own sync queue"
    ON sync_queue FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own sync queue items"
    ON sync_queue FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own sync queue items"
    ON sync_queue FOR UPDATE
    USING (user_id = auth.uid());

-- =====================================================
-- TRIGGERS: Updated_at auto-update
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger sur toutes les tables
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_items_updated_at BEFORE UPDATE ON job_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SEED DATA (Optionnel - Pour dev/test)
-- =====================================================
-- Exemple de company et produits de base
-- À commenter en production

-- INSERT INTO companies (id, name, subscription_status)
-- VALUES ('00000000-0000-0000-0000-000000000001', 'Demo Company', 'active');

-- Fin du schema

