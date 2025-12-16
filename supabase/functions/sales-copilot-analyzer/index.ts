// =====================================================
// EDGE FUNCTION: Sales Copilot Analyzer
// =====================================================
// Description: Analyse predictive des equipements
//              pour generer des opportunites commerciales
// Trigger: Planifie (cron daily) ou manuel
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// =====================================================
// TYPES
// =====================================================

interface Equipment {
  id: string;
  client_id: string;
  equipment_type: string;
  equipment_brand?: string;
  equipment_model?: string;
  serial_number?: string;
  installation_date?: string;
  total_interventions: number;
  total_breakdowns: number;
  last_intervention_date?: string;
  last_breakdown_date?: string;
  health_score: number;
  replacement_urgency: string;
}

interface AnalysisResult {
  equipment_id: string;
  should_create_opportunity: boolean;
  reason: string;
  confidence: number;
  estimated_value: number;
}

// =====================================================
// CONFIGURATION
// =====================================================

const URGENCY_THRESHOLDS = {
  critical: {
    min_breakdowns: 3,
    time_window_months: 3,
    confidence: 95,
  },
  high: {
    min_breakdowns: 2,
    time_window_months: 6,
    confidence: 85,
  },
  medium: {
    min_health_score: 50,
    confidence: 70,
  },
};

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

    // Get request body (optional filters)
    const body = await req.json().catch(() => ({}));
    const { company_id, force_refresh = false } = body;

    console.log("🔍 Starting Sales Copilot Analysis...");

    // Step 1: Recuperer tous les equipements a analyser
    const equipments = await getEquipmentsToAnalyze(supabase, company_id);
    console.log(`📊 Found ${equipments.length} equipments to analyze`);

    // Step 2: Analyser chaque equipement
    const analyses: AnalysisResult[] = [];
    for (const equipment of equipments) {
      const analysis = await analyzeEquipment(equipment, supabase);
      if (analysis.should_create_opportunity) {
        analyses.push(analysis);
      }
    }

    console.log(
      `💡 Generated ${analyses.length} potential opportunities`
    );

    // Step 3: Creer les opportunites
    const opportunities = [];
    for (const analysis of analyses) {
      const opportunity = await createOpportunity(
        analysis,
        supabase,
        force_refresh
      );
      if (opportunity) {
        opportunities.push(opportunity);
      }
    }

    console.log(`✅ Created ${opportunities.length} new opportunities`);

    // Step 4: Notifier les techniciens (optionnel)
    if (opportunities.length > 0) {
      await notifyTechnicians(opportunities, supabase);
    }

    return new Response(
      JSON.stringify({
        success: true,
        analyzed: equipments.length,
        opportunities_generated: opportunities.length,
        opportunities,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Error in Sales Copilot:", error);
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

async function getEquipmentsToAnalyze(
  supabase: any,
  companyId?: string
): Promise<Equipment[]> {
  let query = supabase
    .from("equipment_tracking")
    .select(
      `
      *,
      clients!inner(company_id)
    `
    )
    .gt("total_interventions", 0); // Au moins 1 intervention

  if (companyId) {
    query = query.eq("clients.company_id", companyId);
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(`Failed to fetch equipments: ${error.message}`);
  }

  return data || [];
}

async function analyzeEquipment(
  equipment: Equipment,
  supabase: any
): Promise<AnalysisResult> {
  const result: AnalysisResult = {
    equipment_id: equipment.id,
    should_create_opportunity: false,
    reason: "",
    confidence: 0,
    estimated_value: 0,
  };

  // Logique d'analyse

  // 1. Urgence critique : 3+ pannes en 3 mois
  if (equipment.replacement_urgency === "critical") {
    result.should_create_opportunity = true;
    result.reason = `Urgence critique: ${equipment.total_breakdowns} pannes détectées. Remplacement recommandé.`;
    result.confidence = 95;
    result.estimated_value = estimateReplacementValue(equipment);
    return result;
  }

  // 2. Urgence haute : 2+ pannes en 6 mois
  if (equipment.replacement_urgency === "high") {
    result.should_create_opportunity = true;
    result.reason = `Urgence élevée: ${equipment.total_breakdowns} pannes récentes. Intervention préventive conseillée.`;
    result.confidence = 85;
    result.estimated_value = estimateReplacementValue(equipment);
    return result;
  }

  // 3. Health score faible
  if (equipment.health_score < 50) {
    result.should_create_opportunity = true;
    result.reason = `Score santé faible (${equipment.health_score}/100). Équipement en fin de vie.`;
    result.confidence = 70;
    result.estimated_value = estimateReplacementValue(equipment);
    return result;
  }

  // 4. Analyse historique des interventions
  const { data: interventions } = await supabase
    .from("intervention_history")
    .select("*")
    .eq("equipment_id", equipment.id)
    .order("intervention_date", { ascending: false })
    .limit(10);

  if (interventions && interventions.length >= 3) {
    // Si 3+ interventions dans les 6 derniers mois
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const recentInterventions = interventions.filter(
      (i: any) => new Date(i.intervention_date) > sixMonthsAgo
    );

    if (recentInterventions.length >= 3) {
      result.should_create_opportunity = true;
      result.reason = `${recentInterventions.length} interventions en 6 mois. Coûts récurrents élevés.`;
      result.confidence = 75;
      result.estimated_value = estimateReplacementValue(equipment);
      return result;
    }
  }

  return result;
}

function estimateReplacementValue(equipment: Equipment): number {
  // Estimation basique selon le type d'equipement
  const baseValues: { [key: string]: number } = {
    chaudiere: 5000,
    climatisation: 3000,
    pompe: 1500,
    ballon: 800,
    radiateur: 400,
  };

  const type = equipment.equipment_type.toLowerCase();

  for (const [keyword, value] of Object.entries(baseValues)) {
    if (type.includes(keyword)) {
      return value;
    }
  }

  // Valeur par defaut
  return 2000;
}

async function createOpportunity(
  analysis: AnalysisResult,
  supabase: any,
  forceRefresh: boolean
): Promise<any> {
  // Verifier si une opportunite existe deja
  const { data: existing } = await supabase
    .from("sales_opportunities")
    .select("*")
    .eq("equipment_id", analysis.equipment_id)
    .in("status", ["pending", "accepted"])
    .single();

  if (existing && !forceRefresh) {
    console.log(
      `⏭️  Opportunity already exists for equipment ${analysis.equipment_id}`
    );
    return null;
  }

  // Recuperer l'equipement et le client
  const { data: equipment } = await supabase
    .from("equipment_tracking")
    .select(
      `
      *,
      clients!inner(id, name, company_id, users!inner(id))
    `
    )
    .eq("id", analysis.equipment_id)
    .single();

  if (!equipment) {
    console.error(`Equipment ${analysis.equipment_id} not found`);
    return null;
  }

  // Assigner au premier technicien de l'entreprise (logique simple)
  const assignedUserId = equipment.clients.users[0]?.id;

  // Creer l'opportunite
  const { data: opportunity, error } = await supabase
    .from("sales_opportunities")
    .insert({
      equipment_id: analysis.equipment_id,
      client_id: equipment.client_id,
      assigned_to_user_id: assignedUserId,
      opportunity_type: "replacement",
      confidence_score: analysis.confidence,
      estimated_value: analysis.estimated_value,
      trigger_reason: analysis.reason,
      suggested_action: `Proposer remplacement de ${equipment.equipment_type}`,
      status: "pending",
      ai_metadata: {
        equipment_type: equipment.equipment_type,
        health_score: equipment.health_score,
        total_breakdowns: equipment.total_breakdowns,
        analysis_date: new Date().toISOString(),
      },
    })
    .select()
    .single();

  if (error) {
    console.error("Failed to create opportunity:", error);
    return null;
  }

  console.log(`✅ Created opportunity ${opportunity.id}`);
  return opportunity;
}

async function notifyTechnicians(
  opportunities: any[],
  supabase: any
): Promise<void> {
  // TODO: Integration avec service de notifications
  // Pour l'instant, on log simplement
  console.log(`📢 ${opportunities.length} opportunities to notify`);

  // Grouper par technicien
  const byTechnician = opportunities.reduce((acc: any, opp: any) => {
    const userId = opp.assigned_to_user_id;
    if (!acc[userId]) {
      acc[userId] = [];
    }
    acc[userId].push(opp);
    return acc;
  }, {});

  console.log(
    `📧 Should notify ${Object.keys(byTechnician).length} technicians`
  );

  // TODO: Envoyer notifications push ou email
}

// =====================================================
// CORS HEADERS
// =====================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};




