-- =====================================================
-- FIX SUPABASE SCHEMA CACHE
-- =====================================================
-- Ce script force Supabase à recharger son cache de schéma

-- Méthode 1 : Signal NOTIFY (force le rechargement)
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- Méthode 2 : Ajouter un commentaire aux tables (force une mise à jour)
COMMENT ON TABLE clients IS 'Carnet d''adresses clients - Updated cache';
COMMENT ON TABLE products IS 'Catalogue produits/services - Updated cache';

-- Méthode 3 : Re-créer les vues matérialisées si nécessaire
-- (Pas nécessaire ici, mais peut aider dans certains cas)

-- Vérification : Liste les colonnes de la table clients
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clients'
ORDER BY ordinal_position;

-- Vérification : Liste les colonnes de la table products
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;

