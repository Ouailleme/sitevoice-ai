// =====================================================
// SITEVOICE AI - EDGE FUNCTION : CREATE SUBSCRIPTION
// =====================================================
// Description : Crée un PaymentIntent Stripe pour l'abonnement
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import Stripe from "https://esm.sh/stripe@14.5.0?target=deno";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req: Request) => {
  // CORS
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
    const { company_id, price_in_cents } = await req.json();

    if (!company_id || !price_in_cents) {
      throw new Error("Missing required parameters");
    }

    console.log(`Creating subscription for company: ${company_id}`);

    // Récupérer les infos de l'entreprise
    const { data: company, error: companyError } = await supabase
      .from("companies")
      .select("*")
      .eq("id", company_id)
      .single();

    if (companyError) throw companyError;

    // Créer ou récupérer le customer Stripe
    let customerId = company.stripe_customer_id;

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: company.email,
        name: company.name,
        metadata: {
          company_id: company_id,
        },
      });

      customerId = customer.id;

      // Sauvegarder le customer ID
      await supabase
        .from("companies")
        .update({ stripe_customer_id: customerId })
        .eq("id", company_id);
    }

    // Créer le PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: price_in_cents,
      currency: "eur",
      customer: customerId,
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: {
        company_id: company_id,
        type: "subscription",
      },
    });

    console.log(`PaymentIntent created: ${paymentIntent.id}`);

    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Error:", error);

    return new Response(
      JSON.stringify({
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


