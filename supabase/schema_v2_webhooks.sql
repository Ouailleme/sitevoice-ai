-- =====================================================
-- SITEVOICE AI V2.0 - WEBHOOKS & INTEGRATIONS
-- =====================================================
-- Description : Tables pour les webhooks et intégrations ERP
-- =====================================================

-- =====================================================
-- TABLE: webhook_configs (Configurations de webhooks)
-- =====================================================
CREATE TABLE webhook_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    -- Type de webhook
    name VARCHAR(255) NOT NULL,
    webhook_type VARCHAR(50) NOT NULL, -- 'zapier', 'make', 'custom', 'quickbooks', 'xero', 'batigest'
    
    -- Configuration
    endpoint_url TEXT NOT NULL,
    secret_key VARCHAR(255), -- Pour sécuriser les webhooks
    
    -- Événements à écouter
    events TEXT[] NOT NULL, -- ['job.validated', 'job.invoiced', etc.]
    
    -- Options
    is_active BOOLEAN DEFAULT true,
    retry_failed BOOLEAN DEFAULT true,
    max_retries INTEGER DEFAULT 3,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(company_id, name)
);

CREATE INDEX idx_webhook_configs_company_id ON webhook_configs(company_id);
CREATE INDEX idx_webhook_configs_active ON webhook_configs(is_active) WHERE is_active = true;

-- =====================================================
-- TABLE: webhook_logs (Historique des appels webhooks)
-- =====================================================
CREATE TABLE webhook_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    webhook_config_id UUID NOT NULL REFERENCES webhook_configs(id) ON DELETE CASCADE,
    
    -- Événement
    event_type VARCHAR(100) NOT NULL,
    entity_id UUID NOT NULL, -- ID du job/client/etc
    
    -- Requête
    request_url TEXT NOT NULL,
    request_method VARCHAR(10) NOT NULL DEFAULT 'POST',
    request_payload JSONB NOT NULL,
    request_headers JSONB,
    
    -- Réponse
    response_status INTEGER,
    response_body TEXT,
    response_time_ms INTEGER,
    
    -- Statut
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, success, failed, retrying
    retry_count INTEGER DEFAULT 0,
    error_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_webhook_logs_config_id ON webhook_logs(webhook_config_id);
CREATE INDEX idx_webhook_logs_status ON webhook_logs(status);
CREATE INDEX idx_webhook_logs_created_at ON webhook_logs(created_at DESC);

-- =====================================================
-- TABLE: erp_integrations (Intégrations ERP spécifiques)
-- =====================================================
CREATE TABLE erp_integrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    -- Type d'ERP
    erp_type VARCHAR(50) NOT NULL, -- 'quickbooks', 'xero', 'batigest', 'sage'
    
    -- Authentification
    auth_type VARCHAR(50) NOT NULL, -- 'oauth2', 'api_key', 'basic_auth'
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMP WITH TIME ZONE,
    api_key TEXT,
    
    -- Configuration
    config JSONB, -- Config spécifique par ERP
    
    -- Mapping des champs
    field_mapping JSONB, -- Mapping job fields -> ERP fields
    
    -- Statut
    is_active BOOLEAN DEFAULT true,
    last_sync_at TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(50), -- 'success', 'error', 'pending'
    last_error TEXT,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(company_id, erp_type)
);

CREATE INDEX idx_erp_integrations_company_id ON erp_integrations(company_id);
CREATE INDEX idx_erp_integrations_active ON erp_integrations(is_active) WHERE is_active = true;

-- =====================================================
-- TABLE: sync_mappings (Mapping des entités synchronisées)
-- =====================================================
CREATE TABLE sync_mappings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    erp_integration_id UUID NOT NULL REFERENCES erp_integrations(id) ON DELETE CASCADE,
    
    -- Entité locale
    local_entity_type VARCHAR(50) NOT NULL, -- 'job', 'client', 'product'
    local_entity_id UUID NOT NULL,
    
    -- Entité distante (ERP)
    remote_entity_type VARCHAR(50) NOT NULL, -- 'invoice', 'customer', 'item'
    remote_entity_id VARCHAR(255) NOT NULL,
    
    -- Synchronisation
    last_synced_at TIMESTAMP WITH TIME ZONE,
    sync_direction VARCHAR(20), -- 'push', 'pull', 'bidirectional'
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(erp_integration_id, local_entity_type, local_entity_id)
);

CREATE INDEX idx_sync_mappings_integration_id ON sync_mappings(erp_integration_id);
CREATE INDEX idx_sync_mappings_local ON sync_mappings(local_entity_type, local_entity_id);

-- =====================================================
-- RLS POLICIES
-- =====================================================

ALTER TABLE webhook_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_mappings ENABLE ROW LEVEL SECURITY;

-- Webhook Configs
CREATE POLICY "Users can view own company webhook configs"
    ON webhook_configs FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Admins can manage webhook configs"
    ON webhook_configs FOR ALL
    USING (
        company_id = get_user_company_id()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Webhook Logs
CREATE POLICY "Users can view own company webhook logs"
    ON webhook_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM webhook_configs 
            WHERE id = webhook_logs.webhook_config_id 
            AND company_id = get_user_company_id()
        )
    );

-- ERP Integrations
CREATE POLICY "Users can view own company ERP integrations"
    ON erp_integrations FOR SELECT
    USING (company_id = get_user_company_id());

CREATE POLICY "Admins can manage ERP integrations"
    ON erp_integrations FOR ALL
    USING (
        company_id = get_user_company_id()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Sync Mappings
CREATE POLICY "Users can view own sync mappings"
    ON sync_mappings FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM erp_integrations 
            WHERE id = sync_mappings.erp_integration_id 
            AND company_id = get_user_company_id()
        )
    );

-- =====================================================
-- TRIGGERS
-- =====================================================

CREATE TRIGGER update_webhook_configs_updated_at BEFORE UPDATE ON webhook_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_erp_integrations_updated_at BEFORE UPDATE ON erp_integrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FONCTION: Déclencher les webhooks sur événement
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_webhooks()
RETURNS TRIGGER AS $$
DECLARE
    webhook_config RECORD;
    event_name TEXT;
BEGIN
    -- Déterminer le nom de l'événement
    event_name := TG_TABLE_NAME || '.' || LOWER(TG_OP);
    
    -- Si c'est un job validé ou facturé
    IF TG_TABLE_NAME = 'jobs' AND NEW.status IN ('validated', 'invoiced') THEN
        event_name := 'job.' || NEW.status;
        
        -- Trouver les webhooks actifs pour cet événement
        FOR webhook_config IN 
            SELECT * FROM webhook_configs 
            WHERE company_id = NEW.company_id 
            AND is_active = true
            AND event_name = ANY(events)
        LOOP
            -- Insérer un log pour traitement asynchrone
            INSERT INTO webhook_logs (
                webhook_config_id,
                event_type,
                entity_id,
                request_url,
                request_payload,
                status
            ) VALUES (
                webhook_config.id,
                event_name,
                NEW.id,
                webhook_config.endpoint_url,
                row_to_json(NEW),
                'pending'
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger sur jobs
CREATE TRIGGER jobs_webhook_trigger
    AFTER INSERT OR UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION trigger_webhooks();


