-- =====================================================
-- FORCER LE RECHARGEMENT DU CACHE SUPABASE
-- =====================================================
-- Méthode agressive qui force PostgREST à recharger le schéma

-- Étape 1 : Ajouter une colonne temporaire (force la détection)
ALTER TABLE clients ADD COLUMN IF NOT EXISTS temp_reload_trigger BOOLEAN DEFAULT NULL;
ALTER TABLE products ADD COLUMN IF NOT EXISTS temp_reload_trigger BOOLEAN DEFAULT NULL;

-- Étape 2 : Supprimer la colonne temporaire
ALTER TABLE clients DROP COLUMN IF EXISTS temp_reload_trigger;
ALTER TABLE products DROP COLUMN IF EXISTS temp_reload_trigger;

-- Étape 3 : Mettre à jour les commentaires (force la détection)
COMMENT ON TABLE clients IS 'Table clients - Force reload ' || NOW()::text;
COMMENT ON TABLE products IS 'Table products - Force reload ' || NOW()::text;

-- Étape 4 : Envoyer des notifications
SELECT pg_notify('pgrst', 'reload schema');
SELECT pg_notify('pgrst', 'reload config');

-- Étape 5 : Vérifier que les colonnes existent
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN ('clients', 'products')
    AND column_name = 'company_id';

-- Si company_id n'apparaît pas ci-dessus, il y a un VRAI problème de schéma

