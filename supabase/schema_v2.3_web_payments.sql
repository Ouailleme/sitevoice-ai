-- ============================================
-- SCHEMA V2.3 - WEB PAYMENTS (STRIPE WEB-ONLY)
-- ============================================

-- Ajouter les colonnes de subscription aux users
ALTER TABLE users
ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_tier TEXT, -- 'monthly', 'annual', 'oto'
ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT;

-- Index pour les requêtes rapides
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON users(subscription_status);
CREATE INDEX IF NOT EXISTS idx_users_stripe_customer_id ON users(stripe_customer_id);

-- Contrainte : subscription_status doit être dans une liste définie
ALTER TABLE users
ADD CONSTRAINT check_subscription_status
CHECK (subscription_status IN (
  'free',          -- Utilisateur gratuit (freemium)
  'active',        -- Abonnement actif
  'trialing',      -- Période d'essai
  'past_due',      -- Paiement échoué (donner quelques jours)
  'canceled',      -- Abonnement annulé
  'paused'         -- Abonnement en pause (feature Stripe)
));

-- ============================================
-- FONCTION : Vérifier si un utilisateur est premium
-- ============================================

CREATE OR REPLACE FUNCTION is_user_premium(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_status TEXT;
BEGIN
  SELECT subscription_status INTO v_status
  FROM users
  WHERE id = p_user_id;
  
  RETURN v_status IN ('active', 'trialing');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FONCTION : Obtenir les users avec abonnement expiré
-- ============================================

CREATE OR REPLACE FUNCTION get_expired_subscriptions()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  subscription_tier TEXT,
  expired_since INTERVAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id AS user_id,
    u.email,
    u.subscription_tier,
    NOW() - u.subscription_expires_at AS expired_since
  FROM users u
  WHERE
    u.subscription_status = 'active'
    AND u.subscription_expires_at IS NOT NULL
    AND u.subscription_expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER : Auto-update subscription_status si expiré
-- ============================================

CREATE OR REPLACE FUNCTION check_subscription_expiry()
RETURNS TRIGGER AS $$
BEGIN
  -- Si l'abonnement est marqué comme actif mais la date d'expiration est passée
  IF NEW.subscription_status = 'active'
     AND NEW.subscription_expires_at IS NOT NULL
     AND NEW.subscription_expires_at < NOW() THEN
    
    -- Marquer comme expiré
    NEW.subscription_status = 'canceled';
    
    -- Logger
    RAISE NOTICE 'Abonnement expiré automatiquement: user_id=%', NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_subscription_expiry
  BEFORE UPDATE ON users
  FOR EACH ROW
  WHEN (OLD.subscription_expires_at IS DISTINCT FROM NEW.subscription_expires_at)
  EXECUTE FUNCTION check_subscription_expiry();

-- ============================================
-- TABLE : stripe_events (Log des webhooks)
-- ============================================

CREATE TABLE IF NOT EXISTS stripe_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id TEXT NOT NULL UNIQUE, -- Stripe Event ID
  event_type TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  customer_id TEXT,
  subscription_id TEXT,
  amount NUMERIC(10, 2),
  currency TEXT,
  status TEXT NOT NULL, -- 'processed', 'failed', 'ignored'
  error_message TEXT,
  raw_event JSONB, -- Événement Stripe complet (pour debug)
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stripe_events_event_id ON stripe_events(event_id);
CREATE INDEX IF NOT EXISTS idx_stripe_events_user_id ON stripe_events(user_id);
CREATE INDEX IF NOT EXISTS idx_stripe_events_event_type ON stripe_events(event_type);
CREATE INDEX IF NOT EXISTS idx_stripe_events_created_at ON stripe_events(created_at);

-- ============================================
-- RLS : stripe_events (Admin only)
-- ============================================

ALTER TABLE stripe_events ENABLE ROW LEVEL SECURITY;

-- Pas de policy publique, admin only

-- ============================================
-- VUE : users_premium (Utilisateurs premium actifs)
-- ============================================

CREATE OR REPLACE VIEW users_premium AS
SELECT
  u.id,
  u.email,
  u.subscription_status,
  u.subscription_tier,
  u.subscription_expires_at,
  u.stripe_customer_id,
  CASE
    WHEN u.subscription_tier = 'annual' THEN 299.00
    WHEN u.subscription_tier = 'monthly' THEN 29.00
    WHEN u.subscription_tier = 'oto' THEN 390.00
    ELSE 0
  END AS monthly_revenue_contribution
FROM users u
WHERE u.subscription_status IN ('active', 'trialing');

-- ============================================
-- VUE : mrr (Monthly Recurring Revenue)
-- ============================================

CREATE OR REPLACE VIEW mrr AS
SELECT
  COUNT(*) AS total_premium_users,
  COUNT(*) FILTER (WHERE subscription_tier = 'monthly') AS monthly_users,
  COUNT(*) FILTER (WHERE subscription_tier = 'annual') AS annual_users,
  COUNT(*) FILTER (WHERE subscription_tier = 'oto') AS oto_users,
  SUM(monthly_revenue_contribution) AS total_mrr
FROM users_premium;

-- ============================================
-- FONCTION : Créer un lien de portail Stripe
-- ============================================

-- Note : Cette fonction sera appelée par une Edge Function
-- car elle nécessite l'API Stripe (pas disponible en SQL)

-- ============================================
-- DONNÉES DE TEST (À SUPPRIMER EN PROD)
-- ============================================

-- Exemple : Créer un utilisateur premium de test
-- UPDATE users
-- SET
--   subscription_status = 'active',
--   subscription_tier = 'annual',
--   subscription_expires_at = NOW() + INTERVAL '1 year',
--   stripe_customer_id = 'cus_test_123'
-- WHERE email = 'test@example.com';

-- ============================================
-- COMMENTAIRES
-- ============================================

COMMENT ON COLUMN users.subscription_status IS 'Statut de l''abonnement : free, active, trialing, past_due, canceled, paused';
COMMENT ON COLUMN users.subscription_tier IS 'Type d''abonnement : monthly, annual, oto';
COMMENT ON COLUMN users.subscription_expires_at IS 'Date d''expiration de l''abonnement (null si jamais expiré)';
COMMENT ON COLUMN users.stripe_customer_id IS 'ID du client Stripe (pour portail client)';
COMMENT ON COLUMN users.stripe_subscription_id IS 'ID de l''abonnement Stripe (pour webhooks)';

COMMENT ON TABLE stripe_events IS 'Log de tous les événements Stripe reçus via webhook';
COMMENT ON FUNCTION is_user_premium(UUID) IS 'Vérifie si un utilisateur a un abonnement premium actif';
COMMENT ON FUNCTION get_expired_subscriptions() IS 'Retourne la liste des abonnements expirés (pour relance)';

-- ============================================
-- MIGRATION : Utilisateurs existants
-- ============================================

-- Si vous avez déjà des utilisateurs, mettez-les tous en 'free' par défaut
-- UPDATE users SET subscription_status = 'free' WHERE subscription_status IS NULL;




