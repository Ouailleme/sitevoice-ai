-- =====================================================
-- RECREATE CLIENTS & PRODUCTS TABLES
-- =====================================================
-- ATTENTION : Cela supprimera toutes les données existantes !

-- Sauvegarder les données existantes (si nécessaire)
CREATE TEMP TABLE clients_backup AS SELECT * FROM clients;
CREATE TEMP TABLE products_backup AS SELECT * FROM products;

-- Supprimer les tables
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS products CASCADE;

-- Recréer la table clients
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

-- Recréer la table products
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

-- RLS : Activer Row Level Security
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- RLS Policies pour clients
DROP POLICY IF EXISTS "Users can view own company clients" ON clients;
CREATE POLICY "Users can view own company clients"
    ON clients FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert own company clients" ON clients;
CREATE POLICY "Users can insert own company clients"
    ON clients FOR INSERT
    WITH CHECK (
        company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update own company clients" ON clients;
CREATE POLICY "Users can update own company clients"
    ON clients FOR UPDATE
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete own company clients" ON clients;
CREATE POLICY "Users can delete own company clients"
    ON clients FOR DELETE
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    );

-- RLS Policies pour products
DROP POLICY IF EXISTS "Users can view own company products" ON products;
CREATE POLICY "Users can view own company products"
    ON products FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert own company products" ON products;
CREATE POLICY "Users can insert own company products"
    ON products FOR INSERT
    WITH CHECK (
        company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update own company products" ON products;
CREATE POLICY "Users can update own company products"
    ON products FOR UPDATE
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete own company products" ON products;
CREATE POLICY "Users can delete own company products"
    ON products FOR DELETE
    USING (
        company_id IN (
            SELECT company_id FROM users WHERE id = auth.uid()
        )
    );

-- Restaurer les données (si nécessaire)
-- INSERT INTO clients SELECT * FROM clients_backup;
-- INSERT INTO products SELECT * FROM products_backup;

-- Forcer le rechargement du schéma
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- Vérification finale
SELECT 'clients' as table_name, COUNT(*) as columns_count
FROM information_schema.columns
WHERE table_name = 'clients'
UNION ALL
SELECT 'products' as table_name, COUNT(*) as columns_count
FROM information_schema.columns
WHERE table_name = 'products';

