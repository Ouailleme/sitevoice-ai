// =====================================================
// SITEVOICE AI V2.0 - WEBHOOK DISPATCHER
// =====================================================
// Description : Edge Function qui traite la queue de webhooks
//               et envoie les événements aux endpoints configurés
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { createHmac } from "https://deno.land/std@0.168.0/node/crypto.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req: Request) => {
  try {
    console.log("[Webhook Dispatcher] Starting");

    // Récupérer les webhooks en attente
    const { data: pendingWebhooks, error } = await supabase
      .from("webhook_logs")
      .select(`
        *,
        webhook_config:webhook_configs(*)
      `)
      .in("status", ["pending", "retrying"])
      .order("created_at", { ascending: true })
      .limit(50); // Traiter 50 webhooks par batch

    if (error) throw error;

    console.log(`[Webhook Dispatcher] Found ${pendingWebhooks?.length || 0} pending webhooks`);

    let successCount = 0;
    let errorCount = 0;

    for (const webhook of pendingWebhooks || []) {
      try {
        // Vérifier le nombre de tentatives
        if (webhook.retry_count >= (webhook.webhook_config.max_retries || 3)) {
          console.log(`[Webhook] Max retries reached for ${webhook.id}`);
          await updateWebhookLog(webhook.id, {
            status: "failed",
            error_message: "Max retries exceeded",
          });
          errorCount++;
          continue;
        }

        // Envoyer le webhook
        const startTime = Date.now();
        const result = await sendWebhook(webhook);
        const responseTime = Date.now() - startTime;

        if (result.success) {
          await updateWebhookLog(webhook.id, {
            status: "success",
            response_status: result.statusCode,
            response_body: result.body,
            response_time_ms: responseTime,
            completed_at: new Date().toISOString(),
          });
          successCount++;
          console.log(`[Webhook] Success: ${webhook.id}`);
        } else {
          // Échec - incrémenter retry
          await updateWebhookLog(webhook.id, {
            status: "retrying",
            response_status: result.statusCode,
            error_message: result.error,
            retry_count: webhook.retry_count + 1,
          });
          errorCount++;
          console.log(`[Webhook] Failed (will retry): ${webhook.id}`);
        }
      } catch (e) {
        console.error(`[Webhook] Error processing ${webhook.id}:`, e);
        await updateWebhookLog(webhook.id, {
          status: "retrying",
          error_message: e.message,
          retry_count: webhook.retry_count + 1,
        });
        errorCount++;
      }
    }

    console.log(`[Webhook Dispatcher] Completed: ${successCount} success, ${errorCount} errors`);

    return new Response(
      JSON.stringify({
        success: true,
        processed: pendingWebhooks?.length || 0,
        successCount,
        errorCount,
      }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[Webhook Dispatcher] Error:", error);

    return new Response(
      JSON.stringify({
        error: error.message,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});

// =====================================================
// FONCTIONS UTILITAIRES
// =====================================================

async function sendWebhook(webhook: any) {
  try {
    const { request_url, request_payload, webhook_config } = webhook;

    // Construire les headers
    const headers: any = {
      "Content-Type": "application/json",
      "User-Agent": "SiteVoice-AI-Webhook/2.0",
    };

    // Ajouter signature HMAC si secret configuré
    if (webhook_config.secret_key) {
      const signature = generateSignature(
        JSON.stringify(request_payload),
        webhook_config.secret_key
      );
      headers["X-SiteVoice-Signature"] = signature;
    }

    // Envoyer la requête
    const response = await fetch(request_url, {
      method: "POST",
      headers,
      body: JSON.stringify({
        event_type: webhook.event_type,
        event_id: webhook.id,
        timestamp: new Date().toISOString(),
        data: request_payload,
      }),
    });

    const responseBody = await response.text();

    return {
      success: response.ok,
      statusCode: response.status,
      body: responseBody.substring(0, 1000), // Limiter la taille
    };
  } catch (e) {
    return {
      success: false,
      statusCode: 0,
      error: e.message,
    };
  }
}

async function updateWebhookLog(id: string, updates: any) {
  await supabase
    .from("webhook_logs")
    .update(updates)
    .eq("id", id);
}

function generateSignature(payload: string, secret: string): string {
  const hmac = createHmac("sha256", secret);
  hmac.update(payload);
  return hmac.digest("hex");
}


