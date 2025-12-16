// =====================================================
// EDGE FUNCTION: Generate Embeddings
// =====================================================
// Description: Genere les embeddings OpenAI pour semantic search
// Trigger: Appele apres completion d'un job ou ajout client
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// =====================================================
// TYPES
// =====================================================

interface GenerateEmbeddingRequest {
  type: "job" | "client";
  id: string;
  text?: string; // Optionnel, sinon on le genere
}

// =====================================================
// CONFIGURATION
// =====================================================

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const EMBEDDING_MODEL = "text-embedding-3-small"; // 1536 dimensions
const EMBEDDING_DIMENSIONS = 1536;

// =====================================================
// MAIN HANDLER
// =====================================================

serve(async (req) => {
  try {
    // CORS
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    // Auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing Authorization header");
    }

    // Supabase Client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get request body
    const body: GenerateEmbeddingRequest = await req.json();
    const { type, id, text } = body;

    console.log(`🔮 Generating embedding for ${type}: ${id}`);

    // Step 1: Generer ou recuperer le texte source
    const sourceText = text || (await generateSourceText(type, id, supabase));

    if (!sourceText || sourceText.trim().length === 0) {
      throw new Error(`No text found for ${type} ${id}`);
    }

    console.log(`📝 Source text (${sourceText.length} chars): ${sourceText.substring(0, 100)}...`);

    // Step 2: Generer l'embedding via OpenAI
    const embedding = await generateEmbedding(sourceText);

    console.log(`✨ Generated embedding (${embedding.length} dimensions)`);

    // Step 3: Sauvegarder l'embedding dans la DB
    await saveEmbedding(type, id, embedding, sourceText, supabase);

    console.log(`✅ Embedding saved for ${type} ${id}`);

    return new Response(
      JSON.stringify({
        success: true,
        type,
        id,
        embedding_dimensions: embedding.length,
        source_text_length: sourceText.length,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Error generating embedding:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// =====================================================
// HELPER FUNCTIONS
// =====================================================

async function generateSourceText(
  type: string,
  id: string,
  supabase: any
): Promise<string> {
  if (type === "job") {
    // Utiliser la fonction SQL qui genere le texte
    const { data, error } = await supabase.rpc("generate_job_embedding_text", {
      p_job_id: id,
    });

    if (error) {
      throw new Error(`Failed to generate job text: ${error.message}`);
    }

    return data || "";
  } else if (type === "client") {
    const { data, error } = await supabase.rpc(
      "generate_client_embedding_text",
      {
        p_client_id: id,
      }
    );

    if (error) {
      throw new Error(`Failed to generate client text: ${error.message}`);
    }

    return data || "";
  } else {
    throw new Error(`Unknown type: ${type}`);
  }
}

async function generateEmbedding(text: string): Promise<number[]> {
  if (!OPENAI_API_KEY) {
    throw new Error("OPENAI_API_KEY is not configured");
  }

  // Truncate text si trop long (OpenAI limit: 8191 tokens ~= 30K chars)
  const truncatedText = text.substring(0, 30000);

  const response = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: EMBEDDING_MODEL,
      input: truncatedText,
      dimensions: EMBEDDING_DIMENSIONS,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`OpenAI API error: ${error}`);
  }

  const data = await response.json();

  if (!data.data || data.data.length === 0) {
    throw new Error("No embedding returned from OpenAI");
  }

  return data.data[0].embedding;
}

async function saveEmbedding(
  type: string,
  id: string,
  embedding: number[],
  sourceText: string,
  supabase: any
): Promise<void> {
  const tableName =
    type === "job" ? "job_embeddings" : "client_embeddings";
  const idColumn = type === "job" ? "job_id" : "client_id";

  // Verifier si un embedding existe deja
  const { data: existing } = await supabase
    .from(tableName)
    .select("id")
    .eq(idColumn, id)
    .single();

  if (existing) {
    // Update
    const { error } = await supabase
      .from(tableName)
      .update({
        embedding,
        source_text: sourceText,
        updated_at: new Date().toISOString(),
      })
      .eq(idColumn, id);

    if (error) {
      throw new Error(`Failed to update embedding: ${error.message}`);
    }
  } else {
    // Insert
    const { error } = await supabase.from(tableName).insert({
      [idColumn]: id,
      embedding,
      source_text: sourceText,
    });

    if (error) {
      throw new Error(`Failed to insert embedding: ${error.message}`);
    }
  }
}

// =====================================================
// BATCH GENERATION (Bonus)
// =====================================================

// Fonction pour generer tous les embeddings manquants
async function generateAllMissingEmbeddings(supabase: any) {
  console.log("🔄 Generating all missing embeddings...");

  // Jobs sans embeddings
  const { data: jobsWithoutEmbeddings } = await supabase
    .from("jobs")
    .select("id")
    .eq("status", "completed")
    .not("id", "in", "(SELECT job_id FROM job_embeddings)");

  console.log(`Found ${jobsWithoutEmbeddings?.length || 0} jobs without embeddings`);

  for (const job of jobsWithoutEmbeddings || []) {
    try {
      const text = await generateSourceText("job", job.id, supabase);
      const embedding = await generateEmbedding(text);
      await saveEmbedding("job", job.id, embedding, text, supabase);
      console.log(`✅ Generated embedding for job ${job.id}`);
    } catch (e) {
      console.error(`❌ Failed for job ${job.id}:`, e);
    }
  }

  // Clients sans embeddings
  const { data: clientsWithoutEmbeddings } = await supabase
    .from("clients")
    .select("id")
    .not("id", "in", "(SELECT client_id FROM client_embeddings)");

  console.log(`Found ${clientsWithoutEmbeddings?.length || 0} clients without embeddings`);

  for (const client of clientsWithoutEmbeddings || []) {
    try {
      const text = await generateSourceText("client", client.id, supabase);
      const embedding = await generateEmbedding(text);
      await saveEmbedding("client", client.id, embedding, text, supabase);
      console.log(`✅ Generated embedding for client ${client.id}`);
    } catch (e) {
      console.error(`❌ Failed for client ${client.id}:`, e);
    }
  }

  console.log("🎉 Batch generation completed");
}

// =====================================================
// CORS HEADERS
// =====================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};




