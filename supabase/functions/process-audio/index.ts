// =====================================================
// SITEVOICE AI - EDGE FUNCTION : PROCESS AUDIO
// =====================================================
// Description : Transcrit l'audio avec Whisper puis extrait
//               les données structurées avec GPT-4o
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// =====================================================
// INTERFACES & TYPES
// =====================================================

interface ProcessAudioRequest {
  jobId: string;
  audioUrl: string;
  companyId: string;
  photoUrls?: string[]; // URLs des photos (multimodalité)
  userLocale?: string; // Locale de l'utilisateur (ex: 'fr-FR', 'en-US', 'es-ES')
}

interface WhisperResponse {
  text: string;
}

interface ExtractedData {
  clientName?: string;
  clientAddress?: string;
  interventionDate?: string;
  duration?: number; // en heures
  items: {
    productReference?: string;
    productName?: string;
    description: string;
    quantity: number;
    estimatedPrice?: number;
    matchConfidence?: number; // Confiance du matching produit (0.0 à 1.0)
  }[];
  notes?: string;
  confidence: number; // 0.0 à 1.0
  requiresClarification: boolean; // true si IA incertaine (< 90%)
  clarificationReasons?: string[]; // Raisons de l'incertitude
}

interface GPTMessage {
  role: "system" | "user";
  content: string;
}

interface GPTResponse {
  choices: {
    message: {
      content: string;
    };
    finish_reason: string;
  }[];
  usage: {
    total_tokens: number;
  };
}

// =====================================================
// CONFIGURATION
// =====================================================

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// =====================================================
// HELPERS I18N (MULTI-LANGUES)
// =====================================================

function buildSystemPrompt(locale: string, clientsList: string, productsList: string): string {
  const lang = locale.split('-')[0];

  const prompts: { [key: string]: string } = {
    'en': `You are an AI assistant specialized in extracting data from construction field reports.

LANGUAGE INSTRUCTION: **ALWAYS reply and generate clarification questions in English (en-US).**

From a transcribed voice recording, you must extract and structure the following information:
- Client name (if mentioned)
- Client address (if mentioned)
- Intervention date (if mentioned)
- Intervention duration in hours (if mentioned)
- Products/services used with quantities
- Additional notes

COMPANY CONTEXT (for exact matching):

EXISTING CLIENTS:
${clientsList || "No registered clients"}

PRODUCT CATALOG:
${productsList || "No registered products"}

CRITICAL RULES:
1. If a client is mentioned, try to match with the existing clients list
2. If a product is mentioned, try to match with the catalog
3. **CERTAINTY THRESHOLD: If product/client matching is < 90%, set requiresClarification: true**
4. If you're not 90%+ sure, add the reason in clarificationReasons
5. Be precise about quantities (number, meters, hours, etc.)
6. Calculate an overall confidence score (0.0 to 1.0) based on transcription clarity
7. For each item, indicate a matchConfidence (0.0 to 1.0) for the product
8. Return ONLY valid JSON, without any text before or after

OUTPUT FORMAT (strict JSON):
{
  "clientName": "string or null",
  "clientAddress": "string or null",
  "interventionDate": "YYYY-MM-DD or null",
  "duration": number or null,
  "items": [
    {
      "productReference": "string or null (exact catalog reference if found)",
      "productName": "string",
      "description": "string (what was said verbatim)",
      "quantity": number,
      "estimatedPrice": number or null,
      "matchConfidence": number (0.0 to 1.0, product matching confidence)
    }
  ],
  "notes": "string or null (any additional info)",
  "confidence": number (0.0 to 1.0),
  "requiresClarification": boolean (true if any matching < 90%),
  "clarificationReasons": ["reason 1", "reason 2"] (optional, IN ENGLISH)
}`,

    'fr': `Tu es un assistant IA spécialisé dans l'extraction de données d'interventions techniques du BTP.

INSTRUCTION LANGUE : **TOUJOURS répondre et générer les questions de clarification en Français (fr-FR).**

À partir d'un enregistrement vocal transcrit, tu dois extraire et structurer les informations suivantes :
- Le nom du client (si mentionné)
- L'adresse du client (si mentionnée)
- La date d'intervention (si mentionnée)
- La durée de l'intervention en heures (si mentionnée)
- Les produits/services utilisés avec quantités
- Les notes additionnelles

CONTEXTE ENTREPRISE (pour matching exact) :

CLIENTS EXISTANTS :
${clientsList || "Aucun client enregistré"}

PRODUITS CATALOGUE :
${productsList || "Aucun produit enregistré"}

RÈGLES CRITIQUES :
1. Si un client est mentionné, essaye de le matcher avec la liste des clients existants
2. Si un produit est mentionné, essaye de le matcher avec le catalogue
3. **SEUIL DE CERTITUDE : Si le matching d'un produit/client est < 90%, mets requiresClarification: true**
4. Si tu n'es pas sûr à 90%+, ajoute la raison dans clarificationReasons
5. Sois précis sur les quantités (nombre, mètres, heures, etc.)
6. Calcule un score de confiance global (0.0 à 1.0) basé sur la clarté de la transcription
7. Pour chaque item, indique un matchConfidence (0.0 à 1.0) pour le produit
8. Retourne UNIQUEMENT du JSON valide, sans texte avant ou après

FORMAT DE SORTIE (JSON strict) :
{
  "clientName": "string ou null",
  "clientAddress": "string ou null",
  "interventionDate": "YYYY-MM-DD ou null",
  "duration": number ou null,
  "items": [
    {
      "productReference": "string ou null (référence exacte du catalogue si trouvée)",
      "productName": "string",
      "description": "string (ce qui a été dit textuellement)",
      "quantity": number,
      "estimatedPrice": number ou null,
      "matchConfidence": number (0.0 à 1.0, confiance du matching produit)
    }
  ],
  "notes": "string ou null (toute info additionnelle)",
  "confidence": number (0.0 à 1.0),
  "requiresClarification": boolean (true si un matching < 90%),
  "clarificationReasons": ["raison 1", "raison 2"] (optionnel, EN FRANÇAIS)
}`,

    'es': `Eres un asistente de IA especializado en extraer datos de informes de campo de construcción.

INSTRUCCIÓN DE IDIOMA: **SIEMPRE responde y genera preguntas de aclaración en Español (es-ES).**

A partir de una grabación de voz transcrita, debes extraer y estructurar la siguiente información:
- Nombre del cliente (si se menciona)
- Dirección del cliente (si se menciona)
- Fecha de intervención (si se menciona)
- Duración de la intervención en horas (si se menciona)
- Productos/servicios utilizados con cantidades
- Notas adicionales

CONTEXTO DE LA EMPRESA (para coincidencia exacta):

CLIENTES EXISTENTES:
${clientsList || "No hay clientes registrados"}

CATÁLOGO DE PRODUCTOS:
${productsList || "No hay productos registrados"}

REGLAS CRÍTICAS:
1. Si se menciona un cliente, intenta hacer coincidir con la lista de clientes existentes
2. Si se menciona un producto, intenta hacer coincidir con el catálogo
3. **UMBRAL DE CERTEZA: Si la coincidencia de producto/cliente es < 90%, establece requiresClarification: true**
4. Si no estás 90%+ seguro, agrega la razón en clarificationReasons
5. Sé preciso sobre las cantidades (número, metros, horas, etc.)
6. Calcula una puntuación de confianza general (0.0 a 1.0) basada en la claridad de la transcripción
7. Para cada elemento, indica un matchConfidence (0.0 a 1.0) para el producto
8. Devuelve SOLO JSON válido, sin texto antes o después

FORMATO DE SALIDA (JSON estricto):
{
  "clientName": "string o null",
  "clientAddress": "string o null",
  "interventionDate": "YYYY-MM-DD o null",
  "duration": number o null,
  "items": [
    {
      "productReference": "string o null (referencia exacta del catálogo si se encuentra)",
      "productName": "string",
      "description": "string (lo que se dijo textualmente)",
      "quantity": number,
      "estimatedPrice": number o null,
      "matchConfidence": number (0.0 a 1.0, confianza de coincidencia del producto)
    }
  ],
  "notes": "string o null (cualquier información adicional)",
  "confidence": number (0.0 a 1.0),
  "requiresClarification": boolean (true si alguna coincidencia < 90%),
  "clarificationReasons": ["razón 1", "razón 2"] (opcional, EN ESPAÑOL)
}`,
  };

  return prompts[lang] || prompts['en']; // Fallback to English
}

function buildTranscriptionText(locale: string, transcription: string): string {
  const lang = locale.split('-')[0];
  
  const texts: { [key: string]: string } = {
    'en': `Recording transcription:\n\n"${transcription}"`,
    'fr': `Transcription de l'enregistrement :\n\n"${transcription}"`,
    'es': `Transcripción de la grabación:\n\n"${transcription}"`,
  };

  return texts[lang] || texts['en'];
}

function buildPhotoAnalysisText(locale: string, photoCount: number): string {
  const lang = locale.split('-')[0];
  
  const texts: { [key: string]: string } = {
    'en': `\n\nThe technician attached ${photoCount} photo(s). Analyze the images to extract additional information (serial numbers, product models, etc.).`,
    'fr': `\n\nLe technicien a joint ${photoCount} photo(s). Analyse les images pour extraire des informations additionnelles (numéros de série, modèles de produits, etc.).`,
    'es': `\n\nEl técnico adjuntó ${photoCount} foto(s). Analiza las imágenes para extraer información adicional (números de serie, modelos de productos, etc.).`,
  };

  return texts[lang] || texts['en'];
}

// =====================================================
// FONCTION PRINCIPALE
// =====================================================

serve(async (req: Request) => {
  // CORS headers
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    // Parse la requête
    const { jobId, audioUrl, companyId, photoUrls, userLocale }: ProcessAudioRequest = await req.json();

    if (!jobId || !audioUrl || !companyId) {
      throw new Error("Missing required parameters: jobId, audioUrl, companyId");
    }

    // Déterminer la locale (fallback: en-US)
    const locale = userLocale || 'en-US';
    const language = locale.split('-')[0]; // 'fr', 'en', 'es'

    console.log(`[Process Audio] Starting for job ${jobId}`);
    console.log(`[Process Audio] Language: ${locale}`);
    console.log(`[Process Audio] Multimodal: ${photoUrls ? photoUrls.length : 0} photos`);

    // Mettre à jour le status du job
    await updateJobStatus(jobId, "processing", null);

    // ÉTAPE 1 : Télécharger l'audio depuis Supabase Storage
    console.log(`[Process Audio] Downloading audio from ${audioUrl}`);
    const audioBlob = await downloadAudio(audioUrl);

    // ÉTAPE 2 : Transcrire avec Whisper
    console.log(`[Process Audio] Transcribing with Whisper`);
    const transcription = await transcribeWithWhisper(audioBlob);
    console.log(`[Process Audio] Transcription: ${transcription}`);

    // Sauvegarder la transcription
    await supabase
      .from("jobs")
      .update({ transcription_text: transcription })
      .eq("id", jobId);

    // ÉTAPE 3 : Récupérer le contexte (clients et produits de l'entreprise)
    console.log(`[Process Audio] Fetching company context`);
    const context = await getCompanyContext(companyId);

    // ÉTAPE 4 : Extraire les données avec GPT-4o (+ Vision si photos)
    console.log(`[Process Audio] Extracting data with GPT-4o`);
    const extractedData = await extractDataWithGPT(
      transcription,
      context.clients,
      context.products,
      photoUrls // Photos pour multimodalité
    );

    console.log(`[Process Audio] Extraction confidence: ${extractedData.confidence}`);
    console.log(`[Process Audio] Requires clarification: ${extractedData.requiresClarification}`);

    // ÉTAPE 5 : Déterminer le status final
    // Si requires_clarification OU confiance < 80%, demander review
    const finalStatus = extractedData.requiresClarification || extractedData.confidence < 0.8
      ? "review_needed"
      : "validated";

    // ÉTAPE 6 : Mettre à jour le job avec les données extraites
    await updateJobWithExtractedData(jobId, extractedData, finalStatus);

    // ÉTAPE 7 : Créer les job_items
    if (extractedData.items.length > 0) {
      await createJobItems(jobId, extractedData.items, context.products);
    }

    console.log(`[Process Audio] Completed successfully with status: ${finalStatus}`);

    return new Response(
      JSON.stringify({
        success: true,
        jobId,
        status: finalStatus,
        confidence: extractedData.confidence,
        transcription,
        extractedData,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("[Process Audio] Error:", error);

    // Essayer de mettre à jour le job avec l'erreur
    const body = await req.json().catch(() => ({}));
    if (body.jobId) {
      await updateJobStatus(body.jobId, "review_needed", error.message);
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});

// =====================================================
// FONCTIONS UTILITAIRES
// =====================================================

async function downloadAudio(audioUrl: string): Promise<Blob> {
  // Si c'est une URL Supabase Storage
  if (audioUrl.includes("supabase")) {
    const pathMatch = audioUrl.match(/\/storage\/v1\/object\/public\/([^\/]+)\/(.+)/);
    if (pathMatch) {
      const bucket = pathMatch[1];
      const path = pathMatch[2];
      
      const { data, error } = await supabase.storage.from(bucket).download(path);
      
      if (error) throw error;
      return data;
    }
  }
  
  // Sinon télécharger directement
  const response = await fetch(audioUrl);
  if (!response.ok) throw new Error(`Failed to download audio: ${response.statusText}`);
  return await response.blob();
}

async function transcribeWithWhisper(audioBlob: Blob): Promise<string> {
  const formData = new FormData();
  formData.append("file", audioBlob, "audio.m4a");
  formData.append("model", "whisper-1");
  formData.append("language", "fr"); // Français

  const response = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: formData,
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Whisper API error: ${error}`);
  }

  const data: WhisperResponse = await response.json();
  return data.text;
}

async function getCompanyContext(companyId: string) {
  // Récupérer les clients
  const { data: clients, error: clientsError } = await supabase
    .from("clients")
    .select("id, name, address, city")
    .eq("company_id", companyId);

  if (clientsError) throw clientsError;

  // Récupérer les produits
  const { data: products, error: productsError } = await supabase
    .from("products")
    .select("id, reference, name, unit_price, unit")
    .eq("company_id", companyId)
    .eq("is_active", true);

  if (productsError) throw productsError;

  return { clients: clients || [], products: products || [] };
}

async function extractDataWithGPT(
  transcription: string,
  clients: any[],
  products: any[],
  photoUrls?: string[]
): Promise<ExtractedData> {
  // Construire le contexte pour le RAG
  const clientsList = clients
    .map((c) => `- ${c.name} (${c.address || ""}, ${c.city || ""})`)
    .join("\n");

  const productsList = products
    .map((p) => `- ${p.reference}: ${p.name} (${p.unit_price}€/${p.unit})`)
    .join("\n");

  // Générer le prompt système dans la langue de l'utilisateur
  const systemPrompt = buildSystemPrompt(locale, clientsList, productsList);

  // Construire les messages (avec photos si présentes)
  const messages: any[] = [
    { role: "system", content: systemPrompt },
  ];

  // Message utilisateur avec texte
  const userMessage: any = {
    role: "user",
    content: [],
  };

  // Ajouter la transcription (dans la langue appropriée)
  userMessage.content.push({
    type: "text",
    text: buildTranscriptionText(locale, transcription),
  });

  // Ajouter les photos si présentes (GPT-4o Vision)
  if (photoUrls && photoUrls.length > 0) {
    userMessage.content.push({
      type: "text",
      text: buildPhotoAnalysisText(locale, photoUrls.length),
    });

    for (const photoUrl of photoUrls) {
      userMessage.content.push({
        type: "image_url",
        image_url: { url: photoUrl },
      });
    }
  }

  messages.push(userMessage);

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: "gpt-4o",
      messages,
      response_format: { type: "json_object" },
      temperature: 0.1, // Basse température pour plus de précision
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`GPT API error: ${error}`);
  }

  const data: GPTResponse = await response.json();
  const extractedData: ExtractedData = JSON.parse(
    data.choices[0].message.content
  );

  return extractedData;
}

async function updateJobStatus(
  jobId: string,
  status: string,
  error: string | null
) {
  await supabase
    .from("jobs")
    .update({
      status,
      ai_processing_error: error,
      updated_at: new Date().toISOString(),
    })
    .eq("id", jobId);
}

async function updateJobWithExtractedData(
  jobId: string,
  data: ExtractedData,
  status: string
) {
  // Essayer de trouver le client_id si un nom de client a été extrait
  let clientId = null;
  if (data.clientName) {
    const { data: matchedClient } = await supabase
      .from("clients")
      .select("id")
      .ilike("name", `%${data.clientName}%`)
      .limit(1)
      .single();

    if (matchedClient) {
      clientId = matchedClient.id;
    }
  }

  await supabase
    .from("jobs")
    .update({
      status,
      client_id: clientId,
      ai_confidence_score: data.confidence,
      ai_extracted_data: data,
      ai_requires_clarification: data.requiresClarification || false,
      intervention_date: data.interventionDate || null,
      intervention_duration_hours: data.duration || null,
      notes: data.notes || null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", jobId);
}

async function createJobItems(
  jobId: string,
  items: ExtractedData["items"],
  productsContext: any[]
) {
  const jobItems = items.map((item) => {
    // Essayer de matcher le produit
    let productId = null;
    if (item.productReference) {
      const matchedProduct = productsContext.find(
        (p) => p.reference.toLowerCase() === item.productReference?.toLowerCase()
      );
      if (matchedProduct) {
        productId = matchedProduct.id;
      }
    }

    return {
      job_id: jobId,
      product_id: productId,
      description: item.description,
      quantity: item.quantity,
      unit_price: item.estimatedPrice || null,
      total_price: item.estimatedPrice
        ? item.estimatedPrice * item.quantity
        : null,
      is_validated: false,
    };
  });

  const { error } = await supabase.from("job_items").insert(jobItems);

  if (error) {
    console.error("[Create Job Items] Error:", error);
    throw error;
  }
}

