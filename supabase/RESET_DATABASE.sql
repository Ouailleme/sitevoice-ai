-- =====================================================
-- 🔄 RESET COMPLET DE LA BASE DE DONNÉES
-- =====================================================
-- Ce script recrée TOUTES les tables avec le schéma exact
-- attendu par le code Flutter de SiteVoice AI
--
-- ⚠️ ATTENTION : Ce script supprime toutes les données !
-- Exécute-le dans Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1️⃣ SUPPRESSION DES TABLES EXISTANTES
-- =====================================================

DROP TABLE IF EXISTS job_items CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

-- =====================================================
-- 2️⃣ TABLE COMPANIES
-- =====================================================

CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    siret TEXT,
    address TEXT,
    postal_code TEXT,
    city TEXT,
    country TEXT DEFAULT 'France',
    phone TEXT,
    email TEXT,
    logo_url TEXT,
    
    -- Abonnement (pour web app uniquement)
    subscription_status TEXT DEFAULT 'trial', -- 'trial', 'active', 'canceled', 'expired'
    subscription_tier TEXT, -- 'monthly', 'annual'
    subscription_started_at TIMESTAMPTZ,
    subscription_expires_at TIMESTAMPTZ,
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_companies_subscription ON companies(subscription_status);
CREATE INDEX idx_companies_stripe ON companies(stripe_customer_id);

-- =====================================================
-- 3️⃣ TABLE USERS
-- =====================================================

CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    role TEXT NOT NULL DEFAULT 'tech', -- 'admin' ou 'tech'
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    avatar_url TEXT,
    phone TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Abonnement mobile (ONE-TIME OFFER)
    subscription_status TEXT, -- 'free', 'active', 'trialing', 'canceled'
    subscription_tier TEXT, -- 'monthly', 'annual', 'oto'
    subscription_expires_at TIMESTAMPTZ,
    stripe_customer_id TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_users_company ON users(company_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- =====================================================
-- 4️⃣ TABLE CLIENTS
-- =====================================================

CREATE TABLE clients (
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
CREATE INDEX idx_clients_company ON clients(company_id);
CREATE INDEX idx_clients_name ON clients(name);

-- =====================================================
-- 5️⃣ TABLE PRODUCTS
-- =====================================================

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    reference TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    unit_price NUMERIC(10, 2) NOT NULL DEFAULT 0,
    unit TEXT DEFAULT 'unité', -- 'm2', 'ml', 'unité', 'forfait', 'heure'
    category TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(company_id, reference)
);

-- Index
CREATE INDEX idx_products_company ON products(company_id);
CREATE INDEX idx_products_reference ON products(reference);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_active ON products(is_active);

-- =====================================================
-- 6️⃣ TABLE JOBS
-- =====================================================

CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id),
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    
    status TEXT NOT NULL DEFAULT 'pending_audio', -- 'pending_audio', 'processing', 'review_needed', 'validated', 'invoiced'
    
    -- Audio
    audio_url TEXT,
    audio_duration_seconds INTEGER,
    transcription_text TEXT,
    
    -- Photos
    photo_urls TEXT[], -- Array de URLs
    
    -- GPS
    gps_latitude NUMERIC(10, 8),
    gps_longitude NUMERIC(11, 8),
    gps_captured_at TIMESTAMPTZ,
    
    -- Signature
    signature_url TEXT,
    signature_captured_at TIMESTAMPTZ,
    
    -- IA (Whisper + GPT-4)
    ai_confidence_score NUMERIC(5, 2), -- 0 à 100
    ai_extracted_data JSONB, -- Données extraites par GPT-4
    ai_processing_error TEXT,
    ai_requires_clarification BOOLEAN DEFAULT FALSE,
    
    -- Intervention
    intervention_date TIMESTAMPTZ,
    intervention_duration_hours NUMERIC(5, 2),
    
    -- Financier
    total_ht NUMERIC(10, 2),
    total_ttc NUMERIC(10, 2),
    
    -- Divers
    notes TEXT,
    synced_at TIMESTAMPTZ, -- Pour offline-first sync
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_jobs_company ON jobs(company_id);
CREATE INDEX idx_jobs_created_by ON jobs(created_by);
CREATE INDEX idx_jobs_client ON jobs(client_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_intervention_date ON jobs(intervention_date);
CREATE INDEX idx_jobs_created_at ON jobs(created_at);

-- =====================================================
-- 7️⃣ TABLE JOB_ITEMS (Lignes de chantier)
-- =====================================================

CREATE TABLE job_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    
    product_name TEXT NOT NULL, -- Dénormalisé pour historique
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
CREATE INDEX idx_job_items_job ON job_items(job_id);
CREATE INDEX idx_job_items_product ON job_items(product_id);

-- =====================================================
-- 8️⃣ TRIGGERS UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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
-- 9️⃣ TRIGGER AUTO-CREATE PROFILE AFTER SIGNUP
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_company_id UUID;
BEGIN
    -- Créer une company pour le nouvel utilisateur
    INSERT INTO public.companies (name, subscription_status)
    VALUES (
        COALESCE(NEW.raw_user_meta_data->>'company_name', 'Nouvelle Société'),
        'trial'
    )
    RETURNING id INTO v_company_id;
    
    -- Créer le profil user
    INSERT INTO public.users (id, email, full_name, role, company_id)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
        'admin', -- Premier user = admin
        v_company_id
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer le trigger s'il existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Créer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 🔒 10️⃣ ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_items ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- FONCTION HELPER : get_user_company_id
-- =====================================================

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
-- POLICIES : COMPANIES
-- =====================================================

CREATE POLICY "Users can view own company"
    ON companies FOR SELECT
    USING (id = get_user_company_id());

CREATE POLICY "Admins can update own company"
    ON companies FOR UPDATE
    USING (
        id = get_user_company_id() AND
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- =====================================================
-- POLICIES : USERS
-- =====================================================

CREATE POLICY "Users can view company members"
    ON users FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());

CREATE POLICY "Admins can insert users in their company"
    ON users FOR INSERT
    WITH CHECK (
        company_id = get_user_company_id() AND
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- =====================================================
-- POLICIES : CLIENTS
-- =====================================================

CREATE POLICY "Users can view company clients"
    ON clients FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Users can insert company clients"
    ON clients FOR INSERT
    WITH CHECK (company_id = get_user_company_id());

CREATE POLICY "Users can update company clients"
    ON clients FOR UPDATE
    USING (company_id = get_user_company_id());

CREATE POLICY "Admins can delete company clients"
    ON clients FOR DELETE
    USING (
        company_id = get_user_company_id() AND
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- =====================================================
-- POLICIES : PRODUCTS
-- =====================================================

CREATE POLICY "Users can view company products"
    ON products FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Users can insert company products"
    ON products FOR INSERT
    WITH CHECK (company_id = get_user_company_id());

CREATE POLICY "Users can update company products"
    ON products FOR UPDATE
    USING (company_id = get_user_company_id());

CREATE POLICY "Admins can delete company products"
    ON products FOR DELETE
    USING (
        company_id = get_user_company_id() AND
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- =====================================================
-- POLICIES : JOBS
-- =====================================================

CREATE POLICY "Users can view company jobs"
    ON jobs FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Users can insert company jobs"
    ON jobs FOR INSERT
    WITH CHECK (
        company_id = get_user_company_id() AND
        created_by = auth.uid()
    );

CREATE POLICY "Users can update own jobs"
    ON jobs FOR UPDATE
    USING (
        company_id = get_user_company_id() AND
        (created_by = auth.uid() OR EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        ))
    );

CREATE POLICY "Admins can delete company jobs"
    ON jobs FOR DELETE
    USING (
        company_id = get_user_company_id() AND
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- =====================================================
-- POLICIES : JOB_ITEMS
-- =====================================================

CREATE POLICY "Users can view job items from their company"
    ON job_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM jobs
            WHERE jobs.id = job_items.job_id
            AND jobs.company_id = get_user_company_id()
        )
    );

CREATE POLICY "Users can insert job items"
    ON job_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM jobs
            WHERE jobs.id = job_items.job_id
            AND jobs.company_id = get_user_company_id()
        )
    );

CREATE POLICY "Users can update job items"
    ON job_items FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM jobs
            WHERE jobs.id = job_items.job_id
            AND jobs.company_id = get_user_company_id()
        )
    );

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
-- ✅ 11️⃣ SUCCÈS !
-- =====================================================

-- Vérifier que tout est OK
SELECT 
    'companies' as table_name,
    COUNT(*) as row_count
FROM companies
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'clients', COUNT(*) FROM clients
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'jobs', COUNT(*) FROM jobs
UNION ALL
SELECT 'job_items', COUNT(*) FROM job_items;

-- Message de succès
DO $$
BEGIN
    RAISE NOTICE '✅ Base de données réinitialisée avec succès !';
    RAISE NOTICE '📋 Toutes les tables ont été créées';
    RAISE NOTICE '🔒 RLS activé avec policies correctes';
    RAISE NOTICE '🤖 Trigger auto-create profile activé';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 PROCHAINES ÉTAPES :';
    RAISE NOTICE '1. Teste l''inscription dans l''app Flutter';
    RAISE NOTICE '2. Le profil sera créé automatiquement';
    RAISE NOTICE '3. Tu pourras te connecter !';
END $$;

