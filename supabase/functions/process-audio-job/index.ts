// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ProcessJobRequest {
  jobId: string
}

interface WhisperResponse {
  text: string
}

interface GPTExtractionResponse {
  choices: Array<{
    message: {
      content: string
    }
  }>
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { jobId } = await req.json() as ProcessJobRequest

    if (!jobId) {
      throw new Error('jobId is required')
    }

    console.log(`Processing job: ${jobId}`)

    // Initialiser Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 1. Récupérer le job depuis la DB
    const { data: job, error: jobError } = await supabase
      .from('jobs')
      .select('*')
      .eq('id', jobId)
      .single()

    if (jobError || !job) {
      throw new Error(`Job not found: ${jobId}`)
    }

    // Vérifier si déjà traité
    if (job.transcription_text && job.ai_extracted_data) {
      console.log(`Job ${jobId} already processed`)
      return new Response(
        JSON.stringify({ message: 'Job already processed', jobId }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Télécharger le fichier audio depuis Storage
    const audioPath = job.audio_file_path
    if (!audioPath) {
      throw new Error('No audio file path found')
    }

    console.log(`Downloading audio from: ${audioPath}`)

    const { data: audioData, error: downloadError } = await supabase
      .storage
      .from('audio-recordings')
      .download(audioPath)

    if (downloadError) {
      throw new Error(`Error downloading audio: ${downloadError.message}`)
    }

    // 3. Transcrire avec Whisper
    console.log('Transcribing with Whisper...')

    const formData = new FormData()
    formData.append('file', audioData, 'audio.m4a')
    formData.append('model', 'whisper-1')
    formData.append('language', 'fr')
    formData.append('response_format', 'json')
    formData.append('temperature', '0.2')

    const whisperResponse = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
      },
      body: formData,
    })

    if (!whisperResponse.ok) {
      const error = await whisperResponse.text()
      throw new Error(`Whisper API error: ${error}`)
    }

    const whisperData = await whisperResponse.json() as WhisperResponse
    const transcription = whisperData.text

    console.log(`Transcription: ${transcription.substring(0, 100)}...`)

    // 4. Récupérer les clients et produits existants
    const { data: clients } = await supabase
      .from('clients')
      .select('name')
      .eq('company_id', job.company_id)

    const { data: products } = await supabase
      .from('products')
      .select('name')
      .eq('company_id', job.company_id)

    const existingClients = clients?.map(c => c.name) || []
    const existingProducts = products?.map(p => p.name) || []

    // 5. Extraire les données avec GPT-4
    console.log('Extracting data with GPT-4...')

    const prompt = buildExtractionPrompt(transcription, existingClients, existingProducts)

    const gptResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'system',
            content: 'Tu es un assistant expert en extraction de données depuis des rapports vocaux de techniciens BTP. Tu dois extraire les informations de manière structurée et précise.',
          },
          { role: 'user', content: prompt }
        ],
        response_format: { type: 'json_object' },
        temperature: 0.2,
      }),
    })

    if (!gptResponse.ok) {
      const error = await gptResponse.text()
      throw new Error(`GPT-4 API error: ${error}`)
    }

    const gptData = await gptResponse.json() as GPTExtractionResponse
    const extractedDataStr = gptData.choices[0].message.content
    const extractedData = JSON.parse(extractedDataStr)

    console.log(`Extracted data:`, extractedData)

    // 6. Mettre à jour le job
    const { error: updateError } = await supabase
      .from('jobs')
      .update({
        transcription_text: transcription,
        ai_extracted_data: extractedData,
        ai_confidence_score: extractedData.confiance,
        status: 'review_needed',
        updated_at: new Date().toISOString(),
      })
      .eq('id', jobId)

    if (updateError) {
      throw new Error(`Error updating job: ${updateError.message}`)
    }

    console.log(`Job ${jobId} processed successfully`)

    return new Response(
      JSON.stringify({
        message: 'Job processed successfully',
        jobId,
        transcription,
        extractedData,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})

function buildExtractionPrompt(
  transcription: string,
  existingClients: string[],
  existingProducts: string[]
): string {
  return `
CONTEXTE :
Tu analyses un rapport vocal d'un technicien BTP qui décrit son intervention.

CLIENTS EXISTANTS (utilise ces noms SI le client est reconnu) :
${existingClients.length > 0 ? existingClients.join(', ') : 'Aucun client existant'}

PRODUITS/SERVICES EXISTANTS (utilise ces noms SI le produit est reconnu) :
${existingProducts.length > 0 ? existingProducts.join(', ') : 'Aucun produit existant'}

TRANSCRIPTION DU RAPPORT VOCAL :
"${transcription}"

TÂCHE :
Extrais les informations suivantes au format JSON STRICT :

{
  "client": "nom du client (utilise CLIENTS EXISTANTS si possible, sinon le nom mentionné)",
  "client_nouveau": true ou false (true si le client n'est pas dans CLIENTS EXISTANTS),
  "adresse_intervention": "adresse complète de l'intervention (rue, code postal, ville)",
  "produits": [
    {
      "nom": "nom du produit/service (utilise PRODUITS EXISTANTS si possible)",
      "quantite": nombre (obligatoire),
      "unite": "unité (m2, ml, unité, forfait, heure, etc.)",
      "prix_unitaire": nombre ou null si pas mentionné,
      "produit_nouveau": true ou false (true si pas dans PRODUITS EXISTANTS)
    }
  ],
  "notes": "observations, détails supplémentaires, état des lieux, etc.",
  "confiance": score de 0 à 100 (qualité de l'extraction, précision des informations)
}

RÈGLES IMPORTANTES :
1. Si un client existant est proche du nom mentionné, utilise-le (ex: "Dupont" = "M. Dupont")
2. Si un produit existant correspond, utilise exactement le même nom
3. Toujours inclure la quantité et l'unité pour chaque produit
4. Le score de confiance doit refléter l'ambiguïté et la clarté de la transcription
5. Si l'adresse n'est pas mentionnée, mets une chaîne vide
6. Les notes doivent contenir TOUS les détails non structurés

Réponds UNIQUEMENT avec le JSON, rien d'autre.
`
}

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/process-audio-job' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"jobId":"YOUR_JOB_ID"}'

*/

