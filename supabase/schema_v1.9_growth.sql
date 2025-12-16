-- =====================================================
-- SITEVOICE AI - SCHEMA V1.9 : GROWTH EDITION
-- =====================================================
-- Description : Referral System + Freemium Paywall
-- Features : Viral Loop, Free Tier, Subscription Management
-- =====================================================

-- =====================================================
-- MODIFICATIONS TABLE: users (Ajout champs Growth)
-- =====================================================

-- Ajouter les colonnes si elles n'existent pas
DO $$ 
BEGIN
    -- Referral Code (unique pour chaque user)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='referral_code') THEN
        ALTER TABLE users ADD COLUMN referral_code VARCHAR(20) UNIQUE;
    END IF;
    
    -- Referred By (qui a parraine cet user ?)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='referred_by') THEN
        ALTER TABLE users ADD COLUMN referred_by UUID REFERENCES users(id);
    END IF;
    
    -- Referral Balance (mois gratuits accumules)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='referral_balance') THEN
        ALTER TABLE users ADD COLUMN referral_balance INT DEFAULT 0;
    END IF;
    
    -- Free Reports Count (compteur freemium)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='free_reports_used') THEN
        ALTER TABLE users ADD COLUMN free_reports_used INT DEFAULT 0;
    END IF;
    
    -- Free Tier Limit
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='free_reports_limit') THEN
        ALTER TABLE users ADD COLUMN free_reports_limit INT DEFAULT 3;
    END IF;
    
    -- Onboarding Completed
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='onboarding_completed') THEN
        ALTER TABLE users ADD COLUMN onboarding_completed BOOLEAN DEFAULT false;
    END IF;
    
    -- Onboarding Step (pour reprise)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='onboarding_step') THEN
        ALTER TABLE users ADD COLUMN onboarding_step INT DEFAULT 0;
    END IF;
END $$;

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code);
CREATE INDEX IF NOT EXISTS idx_users_referred_by ON users(referred_by);

-- =====================================================
-- TABLE: referrals (Historique des parrainages)
-- =====================================================

CREATE TABLE IF NOT EXISTS referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Acteurs
    referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- Celui qui parraine
    referee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- Celui qui est parraine
    
    -- Tracking
    referral_code VARCHAR(20) NOT NULL,
    
    -- Status
    status VARCHAR(50) DEFAULT 'pending', -- pending, converted, rewarded, cancelled
    
    -- Rewards
    referrer_reward_months INT DEFAULT 1, -- Mois offerts au parrain
    referee_reward_months INT DEFAULT 1,  -- Mois offerts au filleul
    
    -- Dates
    referred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    converted_at TIMESTAMP WITH TIME ZONE, -- Quand le filleul a paye
    rewarded_at TIMESTAMP WITH TIME ZONE,  -- Quand les rewards ont ete appliques
    
    -- Meta
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contraintes
    CONSTRAINT unique_referee UNIQUE(referee_id)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);
CREATE INDEX IF NOT EXISTS idx_referrals_converted ON referrals(converted_at) WHERE converted_at IS NOT NULL;

-- =====================================================
-- TABLE: paywall_events (Analytics Freemium)
-- =====================================================

CREATE TABLE IF NOT EXISTS paywall_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Event
    event_type VARCHAR(50) NOT NULL, -- 'hit_limit', 'dismissed', 'clicked_upgrade', 'converted'
    
    -- Context
    reports_used INT,
    reports_limit INT,
    
    -- Action
    action_taken VARCHAR(50), -- 'upgrade', 'refer_friend', 'cancel'
    
    -- Meta
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_paywall_events_user ON paywall_events(user_id);
CREATE INDEX IF NOT EXISTS idx_paywall_events_type ON paywall_events(event_type);
CREATE INDEX IF NOT EXISTS idx_paywall_events_created ON paywall_events(created_at DESC);

-- =====================================================
-- FUNCTION: generate_referral_code
-- =====================================================
-- Genere un code de parrainage unique (ex: JEAN-8392)

CREATE OR REPLACE FUNCTION generate_referral_code(p_user_id UUID)
RETURNS VARCHAR AS $$
DECLARE
    v_name VARCHAR;
    v_random_num INT;
    v_code VARCHAR;
    v_exists BOOLEAN;
BEGIN
    -- Recuperer le prenom de l'utilisateur
    SELECT UPPER(SPLIT_PART(full_name, ' ', 1)) INTO v_name
    FROM users
    WHERE id = p_user_id;
    
    -- Fallback si pas de nom
    IF v_name IS NULL OR LENGTH(v_name) = 0 THEN
        v_name := 'USER';
    END IF;
    
    -- Limiter a 8 caracteres max
    v_name := SUBSTRING(v_name, 1, 8);
    
    -- Generer un code unique
    LOOP
        v_random_num := FLOOR(1000 + RANDOM() * 9000)::INT; -- 4 digits
        v_code := v_name || '-' || v_random_num;
        
        -- Verifier unicite
        SELECT EXISTS(SELECT 1 FROM users WHERE referral_code = v_code) INTO v_exists;
        
        EXIT WHEN NOT v_exists;
    END LOOP;
    
    RETURN v_code;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: apply_referral_rewards
-- =====================================================
-- Applique les recompenses quand un filleul paye

CREATE OR REPLACE FUNCTION apply_referral_rewards(p_referee_id UUID)
RETURNS VOID AS $$
DECLARE
    v_referral RECORD;
BEGIN
    -- Recuperer le referral
    SELECT * INTO v_referral
    FROM referrals
    WHERE referee_id = p_referee_id
    AND status = 'converted';
    
    IF v_referral IS NULL THEN
        RETURN;
    END IF;
    
    -- Appliquer les rewards
    -- 1. Au parrain (referrer)
    UPDATE users
    SET referral_balance = referral_balance + v_referral.referrer_reward_months
    WHERE id = v_referral.referrer_id;
    
    -- 2. Au filleul (referee)
    UPDATE users
    SET referral_balance = referral_balance + v_referral.referee_reward_months
    WHERE id = v_referral.referee_id;
    
    -- 3. Marquer comme rewarded
    UPDATE referrals
    SET 
        rewarded_at = NOW(),
        status = 'rewarded'
    WHERE id = v_referral.id;
    
    -- Log l'event
    INSERT INTO paywall_events (user_id, event_type, action_taken)
    VALUES 
        (v_referral.referrer_id, 'referral_reward_applied', 'received_reward'),
        (v_referral.referee_id, 'referral_reward_applied', 'received_reward');
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: check_freemium_limit
-- =====================================================
-- Verifie si l'utilisateur a atteint la limite gratuite

CREATE OR REPLACE FUNCTION check_freemium_limit(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_used INT;
    v_limit INT;
    v_has_subscription BOOLEAN;
BEGIN
    -- Recuperer le compteur
    SELECT free_reports_used, free_reports_limit INTO v_used, v_limit
    FROM users
    WHERE id = p_user_id;
    
    -- Verifier si l'user a un abonnement actif
    SELECT EXISTS(
        SELECT 1 FROM subscriptions
        WHERE user_id = p_user_id
        AND status = 'active'
    ) INTO v_has_subscription;
    
    -- Si abonnement actif, pas de limite
    IF v_has_subscription THEN
        RETURN FALSE;
    END IF;
    
    -- Sinon, verifier la limite
    RETURN v_used >= v_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: increment_freemium_counter
-- =====================================================
-- Incremente le compteur freemium apres chaque rapport

CREATE OR REPLACE FUNCTION increment_freemium_counter()
RETURNS TRIGGER AS $$
BEGIN
    -- Incrementer le compteur quand un job est complete
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE users
        SET free_reports_used = free_reports_used + 1
        WHERE id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger sur jobs
DROP TRIGGER IF EXISTS trigger_increment_freemium ON jobs;
CREATE TRIGGER trigger_increment_freemium
    AFTER UPDATE OF status ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION increment_freemium_counter();

-- =====================================================
-- TRIGGER: Auto-generate referral code on user creation
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_generate_referral_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.referral_code IS NULL THEN
        NEW.referral_code := generate_referral_code(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_referral_code ON users;
CREATE TRIGGER trigger_auto_referral_code
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_generate_referral_code();

-- =====================================================
-- TRIGGER: Create referral record when referred_by is set
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_create_referral_record()
RETURNS TRIGGER AS $$
DECLARE
    v_referrer_code VARCHAR;
BEGIN
    IF NEW.referred_by IS NOT NULL AND OLD.referred_by IS NULL THEN
        -- Recuperer le code du parrain
        SELECT referral_code INTO v_referrer_code
        FROM users
        WHERE id = NEW.referred_by;
        
        -- Creer le record referral
        INSERT INTO referrals (referrer_id, referee_id, referral_code, status)
        VALUES (NEW.referred_by, NEW.id, v_referrer_code, 'pending');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_referral_record ON users;
CREATE TRIGGER trigger_referral_record
    AFTER UPDATE OF referred_by ON users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_referral_record();

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Referrals
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own referrals"
    ON referrals FOR SELECT
    USING (referrer_id = auth.uid() OR referee_id = auth.uid());

-- Paywall Events
ALTER TABLE paywall_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own paywall events"
    ON paywall_events FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own paywall events"
    ON paywall_events FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- =====================================================
-- VIEWS POUR ANALYTICS
-- =====================================================

-- Vue: Conversion Funnel
CREATE OR REPLACE VIEW referral_funnel AS
SELECT 
    r.referrer_id,
    u.full_name as referrer_name,
    COUNT(*) as total_referrals,
    COUNT(*) FILTER (WHERE r.status = 'converted') as conversions,
    COUNT(*) FILTER (WHERE r.status = 'rewarded') as rewarded,
    SUM(r.referrer_reward_months) FILTER (WHERE r.status = 'rewarded') as total_months_earned
FROM referrals r
INNER JOIN users u ON r.referrer_id = u.id
GROUP BY r.referrer_id, u.full_name;

-- Vue: Freemium Metrics
CREATE OR REPLACE VIEW freemium_metrics AS
SELECT 
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE free_reports_used >= free_reports_limit) as hit_paywall,
    AVG(free_reports_used) as avg_reports_used,
    COUNT(*) FILTER (
        WHERE EXISTS(
            SELECT 1 FROM subscriptions s 
            WHERE s.user_id = users.id AND s.status = 'active'
        )
    ) as paid_users
FROM users
WHERE onboarding_completed = true;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE referrals IS 'Historique des parrainages pour le viral loop';
COMMENT ON TABLE paywall_events IS 'Analytics des interactions avec le paywall freemium';
COMMENT ON FUNCTION generate_referral_code IS 'Genere un code unique type JEAN-8392';
COMMENT ON FUNCTION apply_referral_rewards IS 'Applique les recompenses quand un filleul convertit';
COMMENT ON FUNCTION check_freemium_limit IS 'Verifie si l user a atteint la limite des 3 rapports gratuits';




