// =====================================================
// SITEVOICE AI - EDGE FUNCTION : STRIPE WEBHOOK
// =====================================================
// Description : Gère les webhooks Stripe pour mettre à jour
//               les statuts d'abonnement
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import Stripe from "https://esm.sh/stripe@14.5.0?target=deno";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req: Request) => {
  try {
    const signature = req.headers.get("stripe-signature");
    if (!signature) {
      throw new Error("No signature provided");
    }

    const body = await req.text();

    // Vérifier la signature du webhook
    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      STRIPE_WEBHOOK_SECRET
    );

    console.log(`Received webhook event: ${event.type}`);

    // Traiter l'événement
    switch (event.type) {
      case "payment_intent.succeeded":
        await handlePaymentSucceeded(event.data.object as Stripe.PaymentIntent);
        break;

      case "payment_intent.payment_failed":
        await handlePaymentFailed(event.data.object as Stripe.PaymentIntent);
        break;

      case "customer.subscription.created":
      case "customer.subscription.updated":
        await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
        break;

      case "customer.subscription.deleted":
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return new Response(
      JSON.stringify({ received: true }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Webhook error:", error);

    return new Response(
      JSON.stringify({
        error: error.message,
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});

// =====================================================
// HANDLERS
// =====================================================

async function handlePaymentSucceeded(paymentIntent: Stripe.PaymentIntent) {
  const companyId = paymentIntent.metadata.company_id;

  if (!companyId) {
    console.error("No company_id in payment metadata");
    return;
  }

  console.log(`Payment succeeded for company: ${companyId}`);

  // Mettre à jour le statut de l'abonnement
  const endsAt = new Date();
  endsAt.setMonth(endsAt.getMonth() + 1); // Abonnement mensuel

  await supabase
    .from("companies")
    .update({
      subscription_status: "active",
      subscription_ends_at: endsAt.toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq("id", companyId);

  console.log(`Subscription activated for company: ${companyId}`);
}

async function handlePaymentFailed(paymentIntent: Stripe.PaymentIntent) {
  const companyId = paymentIntent.metadata.company_id;

  if (!companyId) {
    console.error("No company_id in payment metadata");
    return;
  }

  console.log(`Payment failed for company: ${companyId}`);

  // Optionnel : Envoyer un email ou notifier l'utilisateur
}

async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  // Récupérer la company via le customer ID
  const { data: company } = await supabase
    .from("companies")
    .select("id")
    .eq("stripe_customer_id", customerId)
    .single();

  if (!company) {
    console.error(`No company found for customer: ${customerId}`);
    return;
  }

  console.log(`Subscription updated for company: ${company.id}`);

  let status = "active";
  if (subscription.status === "canceled") {
    status = "cancelled";
  } else if (subscription.status === "past_due") {
    status = "expired";
  }

  await supabase
    .from("companies")
    .update({
      subscription_status: status,
      subscription_stripe_id: subscription.id,
      subscription_ends_at: new Date(subscription.current_period_end * 1000).toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq("id", company.id);
}

async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  const { data: company } = await supabase
    .from("companies")
    .select("id")
    .eq("stripe_customer_id", customerId)
    .single();

  if (!company) {
    console.error(`No company found for customer: ${customerId}`);
    return;
  }

  console.log(`Subscription deleted for company: ${company.id}`);

  await supabase
    .from("companies")
    .update({
      subscription_status: "cancelled",
      updated_at: new Date().toISOString(),
    })
    .eq("id", company.id);
}


