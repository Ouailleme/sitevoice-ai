-- =====================================================
-- SITEVOICE AI - SCHEMA V3.0 : SEMANTIC SEARCH
-- =====================================================
-- Description : Recherche semantique avec pgvector
-- Feature : "Le chantier avec la porte bleue" -> Trouve le job
-- =====================================================

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- =====================================================
-- TABLE: job_embeddings (Embeddings des jobs)
-- =====================================================
CREATE TABLE IF NOT EXISTS job_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Lien
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE UNIQUE,
    
    -- Embedding (OpenAI text-embedding-3-small = 1536 dimensions)
    embedding vector(1536) NOT NULL,
    
    -- Texte source (pour debug)
    source_text TEXT,
    
    -- Meta
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index HNSW pour recherche rapide
-- HNSW (Hierarchical Navigable Small World) est optimal pour les gros datasets
CREATE INDEX IF NOT EXISTS idx_job_embeddings_hnsw 
ON job_embeddings 
USING hnsw (embedding vector_cosine_ops);

-- Index standard pour fallback
CREATE INDEX IF NOT EXISTS idx_job_embeddings_ivfflat 
ON job_embeddings 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- =====================================================
-- TABLE: client_embeddings (Embeddings des clients)
-- =====================================================
CREATE TABLE IF NOT EXISTS client_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Lien
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE UNIQUE,
    
    -- Embedding
    embedding vector(1536) NOT NULL,
    
    -- Texte source
    source_text TEXT,
    
    -- Meta
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_client_embeddings_hnsw 
ON client_embeddings 
USING hnsw (embedding vector_cosine_ops);

-- =====================================================
-- TABLE: search_history (Historique des recherches)
-- =====================================================
CREATE TABLE IF NOT EXISTS search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Utilisateur
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Requete
    query TEXT NOT NULL,
    query_embedding vector(1536),
    
    -- Resultats
    results_count INT DEFAULT 0,
    top_result_id UUID, -- ID du meilleur resultat (job ou client)
    top_result_similarity FLOAT, -- Score de similarite (0-1)
    
    -- Performance
    search_duration_ms INT,
    
    -- Meta
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_search_history_user ON search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_search_history_created ON search_history(created_at DESC);

-- =====================================================
-- FUNCTION: semantic_search_jobs
-- =====================================================
-- Recherche semantique dans les jobs
CREATE OR REPLACE FUNCTION semantic_search_jobs(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    job_id UUID,
    similarity FLOAT,
    client_name TEXT,
    description TEXT,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id as job_id,
        1 - (je.embedding <=> query_embedding) as similarity,
        c.name as client_name,
        j.description,
        j.status,
        j.created_at
    FROM job_embeddings je
    INNER JOIN jobs j ON je.job_id = j.id
    INNER JOIN clients c ON j.client_id = c.id
    WHERE 
        (p_user_id IS NULL OR j.user_id = p_user_id)
        AND (1 - (je.embedding <=> query_embedding)) > match_threshold
    ORDER BY je.embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: semantic_search_clients
-- =====================================================
-- Recherche semantique dans les clients
CREATE OR REPLACE FUNCTION semantic_search_clients(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10,
    p_company_id UUID DEFAULT NULL
)
RETURNS TABLE (
    client_id UUID,
    similarity FLOAT,
    name TEXT,
    address TEXT,
    phone TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as client_id,
        1 - (ce.embedding <=> query_embedding) as similarity,
        c.name,
        c.address,
        c.phone
    FROM client_embeddings ce
    INNER JOIN clients c ON ce.client_id = c.id
    WHERE 
        (p_company_id IS NULL OR c.company_id = p_company_id)
        AND (1 - (ce.embedding <=> query_embedding)) > match_threshold
    ORDER BY ce.embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: hybrid_search
-- =====================================================
-- Recherche hybride (keyword + semantic)
CREATE OR REPLACE FUNCTION hybrid_search(
    p_query TEXT,
    p_query_embedding vector(1536),
    p_user_id UUID,
    p_match_count INT DEFAULT 10
)
RETURNS TABLE (
    result_type TEXT, -- 'job' ou 'client'
    result_id UUID,
    result_title TEXT,
    result_description TEXT,
    similarity_score FLOAT,
    keyword_score FLOAT,
    combined_score FLOAT
) AS $$
BEGIN
    -- Recherche dans les jobs
    RETURN QUERY
    SELECT 
        'job'::TEXT as result_type,
        j.id as result_id,
        c.name as result_title,
        j.description as result_description,
        (1 - (je.embedding <=> p_query_embedding)) as similarity_score,
        ts_rank(
            to_tsvector('french', coalesce(j.description, '') || ' ' || coalesce(c.name, '')),
            plainto_tsquery('french', p_query)
        ) as keyword_score,
        -- Score combine (70% semantic, 30% keyword)
        (0.7 * (1 - (je.embedding <=> p_query_embedding))) + 
        (0.3 * ts_rank(
            to_tsvector('french', coalesce(j.description, '') || ' ' || coalesce(c.name, '')),
            plainto_tsquery('french', p_query)
        )) as combined_score
    FROM job_embeddings je
    INNER JOIN jobs j ON je.job_id = j.id
    INNER JOIN clients c ON j.client_id = c.id
    WHERE j.user_id = p_user_id
    
    UNION ALL
    
    -- Recherche dans les clients
    SELECT 
        'client'::TEXT as result_type,
        c.id as result_id,
        c.name as result_title,
        coalesce(c.address, '') as result_description,
        (1 - (ce.embedding <=> p_query_embedding)) as similarity_score,
        ts_rank(
            to_tsvector('french', coalesce(c.name, '') || ' ' || coalesce(c.address, '')),
            plainto_tsquery('french', p_query)
        ) as keyword_score,
        (0.7 * (1 - (ce.embedding <=> p_query_embedding))) + 
        (0.3 * ts_rank(
            to_tsvector('french', coalesce(c.name, '') || ' ' || coalesce(c.address, '')),
            plainto_tsquery('french', p_query)
        )) as combined_score
    FROM client_embeddings ce
    INNER JOIN clients c ON ce.client_id = c.id
    WHERE c.company_id = (SELECT company_id FROM users WHERE id = p_user_id)
    
    ORDER BY combined_score DESC
    LIMIT p_match_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: generate_job_embedding_text
-- =====================================================
-- Genere le texte source pour l'embedding d'un job
CREATE OR REPLACE FUNCTION generate_job_embedding_text(p_job_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_text TEXT;
BEGIN
    SELECT 
        format(
            'Client: %s. Adresse: %s. Intervention: %s. Description: %s. Produits: %s',
            c.name,
            coalesce(c.address, ''),
            coalesce(j.description, ''),
            coalesce(j.transcription, ''),
            (
                SELECT string_agg(ji.description, ', ')
                FROM job_items ji
                WHERE ji.job_id = j.id
            )
        )
    INTO v_text
    FROM jobs j
    INNER JOIN clients c ON j.client_id = c.id
    WHERE j.id = p_job_id;
    
    RETURN v_text;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: generate_client_embedding_text
-- =====================================================
-- Genere le texte source pour l'embedding d'un client
CREATE OR REPLACE FUNCTION generate_client_embedding_text(p_client_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_text TEXT;
BEGIN
    SELECT 
        format(
            'Nom: %s. Adresse: %s. Email: %s. Telephone: %s. Notes: %s',
            name,
            coalesce(address, ''),
            coalesce(email, ''),
            coalesce(phone, ''),
            coalesce(notes, '')
        )
    INTO v_text
    FROM clients
    WHERE id = p_client_id;
    
    RETURN v_text;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGER: Auto-update job embedding on job completion
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_update_job_embedding()
RETURNS TRIGGER AS $$
BEGIN
    -- Quand un job est complete, on marque qu'il faut generer l'embedding
    -- L'app Flutter appellera l'Edge Function pour generer l'embedding
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- On pourrait notifier ici ou simplement laisser l'app gerer
        -- Pour l'instant, on ne fait rien (l'app generera l'embedding)
        NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_job_embedding_update ON jobs;
CREATE TRIGGER trigger_job_embedding_update
    AFTER UPDATE OF status ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_job_embedding();

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Job embeddings
ALTER TABLE job_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view job embeddings of their company"
    ON job_embeddings FOR SELECT
    USING (
        job_id IN (
            SELECT id FROM jobs
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert job embeddings"
    ON job_embeddings FOR INSERT
    WITH CHECK (
        job_id IN (
            SELECT id FROM jobs
            WHERE user_id = auth.uid()
        )
    );

-- Client embeddings
ALTER TABLE client_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view client embeddings of their company"
    ON client_embeddings FOR SELECT
    USING (
        client_id IN (
            SELECT id FROM clients
            WHERE company_id = (
                SELECT company_id FROM users WHERE id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can insert client embeddings"
    ON client_embeddings FOR INSERT
    WITH CHECK (
        client_id IN (
            SELECT id FROM clients
            WHERE company_id = (
                SELECT company_id FROM users WHERE id = auth.uid()
            )
        )
    );

-- Search history
ALTER TABLE search_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own search history"
    ON search_history FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own search history"
    ON search_history FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- =====================================================
-- INDEXES SUPPLEMENTAIRES POUR FULL-TEXT SEARCH
-- =====================================================

-- Index GIN pour recherche plein texte (complementaire au semantic)
CREATE INDEX IF NOT EXISTS idx_jobs_fulltext 
ON jobs 
USING gin(to_tsvector('french', coalesce(description, '') || ' ' || coalesce(transcription, '')));

CREATE INDEX IF NOT EXISTS idx_clients_fulltext 
ON clients 
USING gin(to_tsvector('french', coalesce(name, '') || ' ' || coalesce(address, '')));

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE job_embeddings IS 'Embeddings vectoriels des jobs pour recherche semantique';
COMMENT ON TABLE client_embeddings IS 'Embeddings vectoriels des clients pour recherche semantique';
COMMENT ON TABLE search_history IS 'Historique des recherches semantiques pour analytics';
COMMENT ON FUNCTION semantic_search_jobs IS 'Recherche semantique dans les jobs via similarite cosinus';
COMMENT ON FUNCTION hybrid_search IS 'Recherche hybride combinant semantic + keyword search';




