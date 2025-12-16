-- ============================================
-- SCHEMA V2.1 - AFFILIATE & ATTRIBUTION SYSTEM
-- ============================================

-- Table : user_attributions
-- Stocke toutes les attributions d'affiliation
CREATE TABLE IF NOT EXISTS user_attributions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  affiliate_id TEXT NOT NULL,
  campaign TEXT,
  source TEXT NOT NULL, -- 'deep_link', 'manual', 'organic'
  attributed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Index pour les recherches rapides
  CONSTRAINT unique_user_attribution UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_attributions_user_id ON user_attributions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_attributions_affiliate_id ON user_attributions(affiliate_id);
CREATE INDEX IF NOT EXISTS idx_user_attributions_campaign ON user_attributions(campaign);
CREATE INDEX IF NOT EXISTS idx_user_attributions_attributed_at ON user_attributions(attributed_at);

-- Table : affiliate_conversions
-- Track les conversions (premiers paiements) pour les commissions
CREATE TABLE IF NOT EXISTS affiliate_conversions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  affiliate_id TEXT NOT NULL,
  amount NUMERIC(10, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  subscription_type TEXT NOT NULL, -- 'monthly' ou 'annual'
  converted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  commission_paid BOOLEAN NOT NULL DEFAULT FALSE,
  commission_paid_at TIMESTAMPTZ,
  stripe_payment_id TEXT, -- ID du paiement Stripe
  rewardful_referral_id TEXT, -- ID Rewardful si utilisé
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Index pour les recherches rapides
  CONSTRAINT unique_user_conversion UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_affiliate_conversions_user_id ON affiliate_conversions(user_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_conversions_affiliate_id ON affiliate_conversions(affiliate_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_conversions_converted_at ON affiliate_conversions(converted_at);
CREATE INDEX IF NOT EXISTS idx_affiliate_conversions_commission_paid ON affiliate_conversions(commission_paid);

-- Table : affiliate_payouts
-- Track les paiements de commissions aux affiliés
CREATE TABLE IF NOT EXISTS affiliate_payouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  affiliate_id TEXT NOT NULL,
  amount NUMERIC(10, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  conversions_count INT NOT NULL DEFAULT 0,
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'paid', 'failed'
  paid_at TIMESTAMPTZ,
  payment_method TEXT, -- 'stripe', 'paypal', 'wire_transfer'
  payment_reference TEXT, -- Numéro de transaction
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_affiliate_payouts_affiliate_id ON affiliate_payouts(affiliate_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_payouts_status ON affiliate_payouts(status);
CREATE INDEX IF NOT EXISTS idx_affiliate_payouts_period ON affiliate_payouts(period_start, period_end);

-- ====================
-- RLS POLICIES
-- ====================

-- user_attributions : Les users peuvent voir leur propre attribution
ALTER TABLE user_attributions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own attribution"
  ON user_attributions FOR SELECT
  USING (auth.uid() = user_id);

-- affiliate_conversions : Les users peuvent voir leurs propres conversions
ALTER TABLE affiliate_conversions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own conversions"
  ON affiliate_conversions FOR SELECT
  USING (auth.uid() = user_id);

-- affiliate_payouts : Accessible uniquement aux admins (via service_role)
ALTER TABLE affiliate_payouts ENABLE ROW LEVEL SECURITY;

-- Pas de policy publique, admin only

-- ====================
-- FUNCTIONS
-- ====================

-- Fonction : Calculer le total des conversions par affilié
CREATE OR REPLACE FUNCTION get_affiliate_stats(p_affiliate_id TEXT)
RETURNS TABLE (
  total_conversions BIGINT,
  total_revenue NUMERIC,
  pending_commission NUMERIC,
  paid_commission NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_conversions,
    SUM(amount) AS total_revenue,
    SUM(CASE WHEN commission_paid = FALSE THEN amount * 0.20 ELSE 0 END) AS pending_commission,
    SUM(CASE WHEN commission_paid = TRUE THEN amount * 0.20 ELSE 0 END) AS paid_commission
  FROM affiliate_conversions
  WHERE affiliate_id = p_affiliate_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction : Marquer les conversions comme payées
CREATE OR REPLACE FUNCTION mark_conversions_paid(
  p_affiliate_id TEXT,
  p_period_start TIMESTAMPTZ,
  p_period_end TIMESTAMPTZ
)
RETURNS INT AS $$
DECLARE
  updated_count INT;
BEGIN
  UPDATE affiliate_conversions
  SET
    commission_paid = TRUE,
    commission_paid_at = NOW()
  WHERE
    affiliate_id = p_affiliate_id
    AND converted_at >= p_period_start
    AND converted_at <= p_period_end
    AND commission_paid = FALSE;
  
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================
-- TRIGGERS
-- ====================

-- Trigger : Mise à jour automatique de updated_at pour affiliate_payouts
CREATE OR REPLACE FUNCTION update_affiliate_payouts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_affiliate_payouts_updated_at
  BEFORE UPDATE ON affiliate_payouts
  FOR EACH ROW
  EXECUTE FUNCTION update_affiliate_payouts_updated_at();

-- ====================
-- VUES UTILES
-- ====================

-- Vue : Top affiliés par revenue
CREATE OR REPLACE VIEW top_affiliates AS
SELECT
  affiliate_id,
  COUNT(*) AS total_conversions,
  SUM(amount) AS total_revenue,
  SUM(CASE WHEN commission_paid = FALSE THEN amount * 0.20 ELSE 0 END) AS pending_commission,
  MIN(converted_at) AS first_conversion_at,
  MAX(converted_at) AS last_conversion_at
FROM affiliate_conversions
GROUP BY affiliate_id
ORDER BY total_revenue DESC;

-- Vue : Conversions en attente de paiement
CREATE OR REPLACE VIEW pending_commissions AS
SELECT
  ac.*,
  ua.campaign,
  ua.source,
  u.email AS user_email
FROM affiliate_conversions ac
LEFT JOIN user_attributions ua ON ac.user_id = ua.user_id
LEFT JOIN auth.users u ON ac.user_id = u.id
WHERE ac.commission_paid = FALSE
ORDER BY ac.converted_at DESC;

-- ====================
-- DONNÉES DE TEST (Optionnel)
-- ====================

-- Exemple : Créer une attribution de test (à supprimer en production)
-- INSERT INTO user_attributions (user_id, affiliate_id, campaign, source)
-- VALUES (
--   (SELECT id FROM auth.users LIMIT 1),
--   'YOUTUBER_123',
--   'LAUNCH2024',
--   'deep_link'
-- );

-- ====================
-- COMMENTAIRES
-- ====================

COMMENT ON TABLE user_attributions IS 'Stocke toutes les attributions d\'affiliation';
COMMENT ON TABLE affiliate_conversions IS 'Track les conversions (premiers paiements) pour les commissions';
COMMENT ON TABLE affiliate_payouts IS 'Track les paiements de commissions aux affiliés';

COMMENT ON COLUMN user_attributions.affiliate_id IS 'Code unique de l\'affilié (ex: YOUTUBER_123)';
COMMENT ON COLUMN user_attributions.campaign IS 'Nom de la campagne (ex: LAUNCH2024)';
COMMENT ON COLUMN user_attributions.source IS 'Source de l\'attribution: deep_link, manual, organic';

COMMENT ON COLUMN affiliate_conversions.amount IS 'Montant du premier paiement (base pour la commission)';
COMMENT ON COLUMN affiliate_conversions.commission_paid IS 'Indique si la commission a été versée à l\'affilié';
COMMENT ON COLUMN affiliate_conversions.stripe_payment_id IS 'ID du paiement Stripe pour réconciliation';




