-- =====================================================
-- SITEVOICE AI - SCHEMA V3.0 : SALES COPILOT
-- =====================================================
-- Description : Intelligence commerciale predictive
-- Feature : Analyse des pannes recurrentes -> Suggestions vente
-- =====================================================

-- =====================================================
-- TABLE: equipment_tracking (Suivi des equipements)
-- =====================================================
CREATE TABLE IF NOT EXISTS equipment_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identification
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    equipment_type VARCHAR(100) NOT NULL, -- Ex: "Chaudiere", "Pompe", etc.
    equipment_brand VARCHAR(100),
    equipment_model VARCHAR(100),
    serial_number VARCHAR(100),
    
    -- Installation
    installation_date DATE,
    installation_job_id UUID REFERENCES jobs(id),
    
    -- Localisation
    location_description TEXT, -- "Sous-sol", "Chaufferie", etc.
    
    -- Statistiques (calculees)
    total_interventions INT DEFAULT 0,
    total_breakdowns INT DEFAULT 0, -- Pannes uniquement
    last_intervention_date TIMESTAMP WITH TIME ZONE,
    last_breakdown_date TIMESTAMP WITH TIME ZONE,
    
    -- Scoring (IA)
    health_score INT DEFAULT 100, -- 0-100 (100 = neuf, 0 = mort)
    replacement_urgency VARCHAR(20) DEFAULT 'none', -- none, low, medium, high, critical
    replacement_suggested_at TIMESTAMP WITH TIME ZONE,
    
    -- Meta
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_equipment_client ON equipment_tracking(client_id);
CREATE INDEX IF NOT EXISTS idx_equipment_urgency ON equipment_tracking(replacement_urgency) WHERE replacement_urgency != 'none';

-- =====================================================
-- TABLE: sales_opportunities (Opportunites commerciales)
-- =====================================================
CREATE TABLE IF NOT EXISTS sales_opportunities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Lien
    equipment_id UUID REFERENCES equipment_tracking(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    assigned_to_user_id UUID REFERENCES users(id),
    
    -- Type
    opportunity_type VARCHAR(50) NOT NULL, -- 'replacement', 'upgrade', 'maintenance_contract'
    
    -- Scoring IA
    confidence_score DECIMAL(5,2), -- 0-100%
    estimated_value DECIMAL(10,2), -- Valeur estimee du devis
    
    -- Raison
    trigger_reason TEXT, -- "3 pannes en 2 mois", "Equipment age > 10 ans"
    suggested_action TEXT, -- "Proposer remplacement chaudiere"
    
    -- Statut
    status VARCHAR(50) DEFAULT 'pending', -- pending, accepted, declined, converted, expired
    
    -- Dates
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notified_at TIMESTAMP WITH TIME ZONE,
    responded_at TIMESTAMP WITH TIME ZONE,
    converted_at TIMESTAMP WITH TIME ZONE,
    
    -- Meta
    ai_metadata JSONB -- Contexte complet pour l'IA
);

-- Index
CREATE INDEX IF NOT EXISTS idx_opportunities_status ON sales_opportunities(status);
CREATE INDEX IF NOT EXISTS idx_opportunities_user ON sales_opportunities(assigned_to_user_id);
CREATE INDEX IF NOT EXISTS idx_opportunities_client ON sales_opportunities(client_id);

-- =====================================================
-- TABLE: intervention_history (Historique detaille)
-- =====================================================
CREATE TABLE IF NOT EXISTS intervention_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Liens
    equipment_id UUID REFERENCES equipment_tracking(id) ON DELETE CASCADE,
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    
    -- Type
    intervention_type VARCHAR(50) NOT NULL, -- 'repair', 'maintenance', 'diagnostic', 'installation'
    is_breakdown BOOLEAN DEFAULT false, -- Est-ce une panne ?
    
    -- Details
    description TEXT,
    parts_replaced TEXT[], -- Liste des pieces remplacees
    labor_hours DECIMAL(4,2),
    total_cost DECIMAL(10,2),
    
    -- Date
    intervention_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Meta
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_intervention_equipment ON intervention_history(equipment_id);
CREATE INDEX IF NOT EXISTS idx_intervention_date ON intervention_history(intervention_date DESC);

-- =====================================================
-- FUNCTION: track_equipment_from_job
-- =====================================================
-- Extrait les equipements des jobs et les track automatiquement
CREATE OR REPLACE FUNCTION track_equipment_from_job()
RETURNS TRIGGER AS $$
DECLARE
    item RECORD;
    equipment_id UUID;
BEGIN
    -- Pour chaque item du job
    FOR item IN 
        SELECT * FROM job_items WHERE job_id = NEW.id
    LOOP
        -- Si c'est un equipement (pas un consommable)
        -- Logique: si quantity = 1 et prix > 100€, c'est probablement un equipement
        IF item.quantity = 1 AND item.unit_price > 100 THEN
            
            -- Verifier si l'equipement existe deja
            SELECT id INTO equipment_id
            FROM equipment_tracking
            WHERE client_id = NEW.client_id
            AND equipment_type = item.description
            LIMIT 1;
            
            -- Si pas trouve, creer
            IF equipment_id IS NULL THEN
                INSERT INTO equipment_tracking (
                    client_id,
                    equipment_type,
                    installation_date,
                    installation_job_id
                ) VALUES (
                    NEW.client_id,
                    item.description,
                    NEW.created_at::DATE,
                    NEW.id
                ) RETURNING id INTO equipment_id;
            END IF;
            
            -- Logger l'intervention
            INSERT INTO intervention_history (
                equipment_id,
                job_id,
                intervention_type,
                description,
                intervention_date
            ) VALUES (
                equipment_id,
                NEW.id,
                'installation',
                item.description,
                NEW.created_at
            );
            
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger sur jobs
DROP TRIGGER IF EXISTS trigger_track_equipment ON jobs;
CREATE TRIGGER trigger_track_equipment
    AFTER INSERT OR UPDATE OF status ON jobs
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION track_equipment_from_job();

-- =====================================================
-- FUNCTION: update_equipment_stats
-- =====================================================
-- Met a jour les stats d'un equipement
CREATE OR REPLACE FUNCTION update_equipment_stats(p_equipment_id UUID)
RETURNS VOID AS $$
DECLARE
    v_total_interventions INT;
    v_total_breakdowns INT;
    v_last_intervention TIMESTAMP;
    v_last_breakdown TIMESTAMP;
    v_health_score INT;
    v_urgency VARCHAR(20);
BEGIN
    -- Compter les interventions
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE is_breakdown = true),
        MAX(intervention_date),
        MAX(intervention_date) FILTER (WHERE is_breakdown = true)
    INTO 
        v_total_interventions,
        v_total_breakdowns,
        v_last_intervention,
        v_last_breakdown
    FROM intervention_history
    WHERE equipment_id = p_equipment_id;
    
    -- Calculer health_score (simplifie)
    -- Score = 100 - (nombre de pannes * 10) - (anciennete en annees * 5)
    SELECT 
        GREATEST(0, 
            100 
            - (v_total_breakdowns * 10)
            - (EXTRACT(YEAR FROM AGE(NOW(), installation_date))::INT * 5)
        )
    INTO v_health_score
    FROM equipment_tracking
    WHERE id = p_equipment_id;
    
    -- Determiner urgency
    IF v_total_breakdowns >= 3 AND v_last_breakdown > NOW() - INTERVAL '3 months' THEN
        v_urgency := 'critical';
    ELSIF v_total_breakdowns >= 2 AND v_last_breakdown > NOW() - INTERVAL '6 months' THEN
        v_urgency := 'high';
    ELSIF v_health_score < 50 THEN
        v_urgency := 'medium';
    ELSIF v_health_score < 30 THEN
        v_urgency := 'high';
    ELSE
        v_urgency := 'none';
    END IF;
    
    -- Mettre a jour
    UPDATE equipment_tracking
    SET 
        total_interventions = v_total_interventions,
        total_breakdowns = v_total_breakdowns,
        last_intervention_date = v_last_intervention,
        last_breakdown_date = v_last_breakdown,
        health_score = v_health_score,
        replacement_urgency = v_urgency,
        updated_at = NOW()
    WHERE id = p_equipment_id;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: generate_sales_opportunity
-- =====================================================
-- Genere une opportunite commerciale si les conditions sont reunies
CREATE OR REPLACE FUNCTION generate_sales_opportunity(p_equipment_id UUID)
RETURNS UUID AS $$
DECLARE
    v_equipment RECORD;
    v_opportunity_id UUID;
    v_trigger_reason TEXT;
    v_confidence DECIMAL(5,2);
BEGIN
    -- Recuperer l'equipement
    SELECT * INTO v_equipment
    FROM equipment_tracking
    WHERE id = p_equipment_id;
    
    -- Si urgency est none, pas d'opportunite
    IF v_equipment.replacement_urgency = 'none' THEN
        RETURN NULL;
    END IF;
    
    -- Construire la raison
    v_trigger_reason := format(
        '%s pannes detectees en %s mois. Health score: %s/100.',
        v_equipment.total_breakdowns,
        EXTRACT(MONTH FROM AGE(NOW(), v_equipment.last_breakdown_date)),
        v_equipment.health_score
    );
    
    -- Calculer confiance (heuristique)
    v_confidence := CASE v_equipment.replacement_urgency
        WHEN 'critical' THEN 95.0
        WHEN 'high' THEN 85.0
        WHEN 'medium' THEN 70.0
        ELSE 50.0
    END;
    
    -- Creer l'opportunite (si pas deja existante)
    INSERT INTO sales_opportunities (
        equipment_id,
        client_id,
        opportunity_type,
        confidence_score,
        estimated_value,
        trigger_reason,
        suggested_action,
        status,
        ai_metadata
    )
    SELECT
        p_equipment_id,
        v_equipment.client_id,
        'replacement',
        v_confidence,
        3000.00, -- Valeur par defaut (a affiner)
        v_trigger_reason,
        format('Proposer remplacement de %s', v_equipment.equipment_type),
        'pending',
        jsonb_build_object(
            'equipment_type', v_equipment.equipment_type,
            'total_breakdowns', v_equipment.total_breakdowns,
            'health_score', v_equipment.health_score
        )
    WHERE NOT EXISTS (
        SELECT 1 FROM sales_opportunities
        WHERE equipment_id = p_equipment_id
        AND status IN ('pending', 'accepted')
    )
    RETURNING id INTO v_opportunity_id;
    
    RETURN v_opportunity_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Equipment tracking
ALTER TABLE equipment_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view equipment of their company"
    ON equipment_tracking FOR SELECT
    USING (
        client_id IN (
            SELECT id FROM clients
            WHERE company_id = (
                SELECT company_id FROM users WHERE id = auth.uid()
            )
        )
    );

-- Sales opportunities
ALTER TABLE sales_opportunities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their opportunities"
    ON sales_opportunities FOR SELECT
    USING (
        assigned_to_user_id = auth.uid()
        OR client_id IN (
            SELECT id FROM clients
            WHERE company_id = (
                SELECT company_id FROM users WHERE id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can update their opportunities"
    ON sales_opportunities FOR UPDATE
    USING (assigned_to_user_id = auth.uid());

-- Intervention history
ALTER TABLE intervention_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view intervention history of their company"
    ON intervention_history FOR SELECT
    USING (
        equipment_id IN (
            SELECT id FROM equipment_tracking
            WHERE client_id IN (
                SELECT id FROM clients
                WHERE company_id = (
                    SELECT company_id FROM users WHERE id = auth.uid()
                )
            )
        )
    );

-- =====================================================
-- INDEXES SUPPLEMENTAIRES POUR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_equipment_health ON equipment_tracking(health_score) WHERE health_score < 70;
CREATE INDEX IF NOT EXISTS idx_equipment_breakdowns ON equipment_tracking(total_breakdowns) WHERE total_breakdowns > 0;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE equipment_tracking IS 'Suivi des equipements installes chez les clients pour analyse predictive';
COMMENT ON TABLE sales_opportunities IS 'Opportunites commerciales generees automatiquement par IA';
COMMENT ON TABLE intervention_history IS 'Historique detaille de toutes les interventions sur les equipements';




