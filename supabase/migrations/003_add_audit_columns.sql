-- =====================================================
-- MIGRATION 003: AJOUT COLONNES D'AUDIT
-- =====================================================
-- Date: 2025-12-16
-- Author: SiteVoice AI Team
-- Description: Ajout de colonnes d'audit pour tracer les modifications
-- 
-- Changes:
-- - Ajout de 'last_modified_by' sur tables clients, products, jobs
-- - Ajout de trigger pour mettre à jour 'updated_at' automatiquement
-- =====================================================

-- ⚠️ MIGRATION START ⚠️

-- 1. Ajouter la colonne last_modified_by aux clients
ALTER TABLE clients 
ADD COLUMN IF NOT EXISTS last_modified_by UUID REFERENCES users(id);

COMMENT ON COLUMN clients.last_modified_by IS 'Dernier utilisateur ayant modifié cet enregistrement';

-- 2. Ajouter la colonne last_modified_by aux products
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS last_modified_by UUID REFERENCES users(id);

COMMENT ON COLUMN products.last_modified_by IS 'Dernier utilisateur ayant modifié cet enregistrement';

-- 3. Ajouter la colonne last_modified_by aux jobs
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS last_modified_by UUID REFERENCES users(id);

COMMENT ON COLUMN jobs.last_modified_by IS 'Dernier utilisateur ayant modifié cet enregistrement';

-- 4. Créer une fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.last_modified_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Créer les triggers pour clients
DROP TRIGGER IF EXISTS update_clients_updated_at ON clients;
CREATE TRIGGER update_clients_updated_at
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 6. Créer les triggers pour products
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 7. Créer les triggers pour jobs
DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
CREATE TRIGGER update_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ⚠️ MIGRATION END ⚠️

-- Recharger le schéma (OBLIGATOIRE)
NOTIFY pgrst, 'reload schema';

-- Vérification
SELECT 
    'Migration 003 completed' as status,
    NOW() as completed_at;

-- Vérifier que les colonnes ont été ajoutées
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN ('clients', 'products', 'jobs')
    AND column_name = 'last_modified_by'
ORDER BY table_name;

