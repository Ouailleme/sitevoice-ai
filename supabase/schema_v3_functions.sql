-- ============================================
-- V3.0 - HYBRID ECOSYSTEM : POSTGRES FUNCTIONS
-- ============================================
-- Logique métier partagée entre Flutter & Next.js
-- Principe : Si une logique fait > 10 lignes, elle devient une Function

-- ============================================
-- FUNCTION : calculate_job_pricing
-- ============================================
-- Calcule le prix total d'une intervention
-- Input : job_id
-- Output : total_amount (HT et TTC)
--
-- Évite la duplication de logique entre Mobile et Web

CREATE OR REPLACE FUNCTION calculate_job_pricing(job_id_param UUID)
RETURNS TABLE(
  total_ht NUMERIC,
  total_tva NUMERIC,
  total_ttc NUMERIC
) AS $$
DECLARE
  line_items RECORD;
  sum_ht NUMERIC := 0;
  sum_tva NUMERIC := 0;
BEGIN
  -- Parcourir toutes les lignes de l'intervention
  FOR line_items IN 
    SELECT 
      jl.quantity,
      jl.unit_price,
      p.tax_rate
    FROM job_lines jl
    LEFT JOIN products p ON jl.product_id = p.id
    WHERE jl.job_id = job_id_param
  LOOP
    -- Calculer HT
    sum_ht := sum_ht + (line_items.quantity * line_items.unit_price);
    
    -- Calculer TVA
    IF line_items.tax_rate IS NOT NULL THEN
      sum_tva := sum_tva + (line_items.quantity * line_items.unit_price * line_items.tax_rate / 100);
    END IF;
  END LOOP;
  
  -- Retourner les totaux
  RETURN QUERY SELECT 
    sum_ht,
    sum_tva,
    sum_ht + sum_tva;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER : auto_update_job_pricing
-- ============================================
-- Met à jour automatiquement le total d'un job
-- quand une ligne est ajoutée/modifiée/supprimée

CREATE OR REPLACE FUNCTION trigger_update_job_pricing()
RETURNS TRIGGER AS $$
DECLARE
  pricing RECORD;
BEGIN
  -- Calculer le nouveau pricing
  SELECT * INTO pricing FROM calculate_job_pricing(
    COALESCE(NEW.job_id, OLD.job_id)
  );
  
  -- Mettre à jour la table jobs
  UPDATE jobs 
  SET 
    total_amount = pricing.total_ttc,
    updated_at = NOW()
  WHERE id = COALESCE(NEW.job_id, OLD.job_id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger sur la table job_lines
DROP TRIGGER IF EXISTS trigger_auto_update_job_pricing ON job_lines;
CREATE TRIGGER trigger_auto_update_job_pricing
AFTER INSERT OR UPDATE OR DELETE ON job_lines
FOR EACH ROW
EXECUTE FUNCTION trigger_update_job_pricing();

-- ============================================
-- FUNCTION : get_user_subscription_info
-- ============================================
-- Retourne les infos complètes d'abonnement d'un utilisateur
-- Utilisé par Mobile et Web pour afficher le statut

CREATE OR REPLACE FUNCTION get_user_subscription_info(user_id_param UUID)
RETURNS TABLE(
  subscription_status TEXT,
  subscription_tier TEXT,
  subscription_expires_at TIMESTAMP WITH TIME ZONE,
  is_premium BOOLEAN,
  free_reports_remaining INTEGER
) AS $$
BEGIN
  RETURN QUERY 
  SELECT 
    u.subscription_status,
    u.subscription_tier,
    u.subscription_expires_at,
    (u.subscription_status IN ('active', 'trialing')) AS is_premium,
    GREATEST(0, 3 - u.free_reports_used) AS free_reports_remaining
  FROM users u
  WHERE u.id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION : increment_free_report_usage
-- ============================================
-- Incrémente le compteur de rapports gratuits
-- Renvoie TRUE si l'utilisateur peut créer un rapport
-- Renvoie FALSE s'il a atteint la limite (3 rapports)

CREATE OR REPLACE FUNCTION increment_free_report_usage(user_id_param UUID)
RETURNS BOOLEAN AS $$
DECLARE
  current_user RECORD;
BEGIN
  -- Récupérer l'utilisateur
  SELECT * INTO current_user 
  FROM users 
  WHERE id = user_id_param;
  
  -- Si premium, toujours autoriser
  IF current_user.subscription_status IN ('active', 'trialing') THEN
    RETURN TRUE;
  END IF;
  
  -- Si freemium, vérifier la limite
  IF current_user.free_reports_used >= 3 THEN
    RETURN FALSE; -- Limite atteinte
  END IF;
  
  -- Incrémenter le compteur
  UPDATE users 
  SET free_reports_used = free_reports_used + 1
  WHERE id = user_id_param;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON FUNCTION calculate_job_pricing IS 'Calcule le prix total HT/TTC d''une intervention (V3.0 - Shared Logic)';
COMMENT ON FUNCTION get_user_subscription_info IS 'Retourne les infos d''abonnement d''un utilisateur (V3.0)';
COMMENT ON FUNCTION increment_free_report_usage IS 'Incrémente le compteur freemium et vérifie la limite (V3.0)';

-- ============================================
-- GRANTS
-- ============================================

GRANT EXECUTE ON FUNCTION calculate_job_pricing TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_subscription_info TO authenticated;
GRANT EXECUTE ON FUNCTION increment_free_report_usage TO authenticated;

-- ============================================
-- FIN V3.0 FUNCTIONS
-- ============================================



