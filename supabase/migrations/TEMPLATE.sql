-- =====================================================
-- MIGRATION XXX: [TITRE DE LA MIGRATION]
-- =====================================================
-- Date: YYYY-MM-DD
-- Author: [Ton nom]
-- Description: [Description détaillée de ce que fait cette migration]
-- 
-- Changes:
-- - [Liste des changements]
-- - [Exemple : Ajout de la colonne 'notes' à la table 'clients']
-- =====================================================

-- ⚠️ MIGRATION START ⚠️

-- Exemple 1 : Ajouter une nouvelle colonne
-- ALTER TABLE table_name 
-- ADD COLUMN IF NOT EXISTS column_name TYPE DEFAULT value;

-- Exemple 2 : Créer une nouvelle table
-- CREATE TABLE IF NOT EXISTS table_name (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
--     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );

-- Exemple 3 : Créer un index
-- CREATE INDEX IF NOT EXISTS idx_table_column 
-- ON table_name(column_name);

-- Exemple 4 : Ajouter une RLS policy
-- DROP POLICY IF EXISTS "policy_name" ON table_name;
-- CREATE POLICY "policy_name"
--     ON table_name FOR SELECT
--     USING (company_id = get_user_company_id());

-- Exemple 5 : Activer RLS sur une table
-- ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- ⚠️ MIGRATION END ⚠️

-- Recharger le schéma (OBLIGATOIRE)
NOTIFY pgrst, 'reload schema';

-- Vérification (optionnel mais recommandé)
-- SELECT 'Migration XXX completed' as status;

