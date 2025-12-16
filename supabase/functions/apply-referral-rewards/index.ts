// =====================================================
// EDGE FUNCTION: Apply Referral Rewards
// =====================================================
// Description: Applique les recompenses de parrainage
//              quand un filleul convertit (paye)
// Trigger: Webhook Stripe ou manuel
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

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
    const { referee_id } = await req.json();

    if (!referee_id) {
      throw new Error("referee_id is required");
    }

    console.log(`🎁 Processing referral rewards for referee: ${referee_id}`);

    // Call the SQL function
    const { data, error } = await supabase.rpc("apply_referral_rewards", {
      p_referee_id: referee_id,
    });

    if (error) {
      throw new Error(`Failed to apply rewards: ${error.message}`);
    }

    console.log(`✅ Rewards applied successfully for referee: ${referee_id}`);

    return new Response(
      JSON.stringify({
        success: true,
        referee_id,
        message: "Rewards applied successfully",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Error applying referral rewards:", error);
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
// CORS HEADERS
// =====================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};




