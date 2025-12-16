// ============================================
// EDGE FUNCTION : Stripe Webhook Handler
// ============================================
//
// Gère les événements Stripe et met à jour Supabase
//
// Événements gérés :
// - checkout.session.completed : Premier paiement réussi
// - customer.subscription.created : Abonnement créé
// - customer.subscription.updated : Abonnement modifié
// - customer.subscription.deleted : Abonnement annulé
// - invoice.paid : Paiement de facture réussi
// - invoice.payment_failed : Paiement échoué

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14.21.0';

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!;
const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req: Request) => {
  try {
    // Vérifier la signature Stripe
    const signature = req.headers.get('stripe-signature');
    if (!signature) {
      console.error('❌ Signature manquante');
      return new Response('Unauthorized', { status: 401 });
    }

    const body = await req.text();
    
    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(
        body,
        signature,
        STRIPE_WEBHOOK_SECRET,
      );
    } catch (err) {
      console.error('❌ Signature invalide:', err);
      return new Response('Invalid signature', { status: 400 });
    }

    console.log('📬 Webhook reçu:', event.type);

    // Router les événements
    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutCompleted(event.data.object as Stripe.Checkout.Session);
        break;

      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
        break;

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;

      case 'invoice.paid':
        await handleInvoicePaid(event.data.object as Stripe.Invoice);
        break;

      case 'invoice.payment_failed':
        await handleInvoicePaymentFailed(event.data.object as Stripe.Invoice);
        break;

      default:
        console.log('ℹ️ Événement non géré:', event.type);
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('❌ Erreur globale:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

/**
 * Gère la complétion d'une session de checkout
 */
async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
  const userId = session.client_reference_id;
  const customerEmail = session.customer_email;
  const affiliateId = session.metadata?.affiliate_id;

  if (!userId) {
    console.error('❌ client_reference_id manquant');
    return;
  }

  console.log('✅ Checkout complété:', { userId, customerEmail, affiliateId });

  // Déterminer le tier (monthly, annual, oto)
  const tier = session.metadata?.tier || 'monthly';

  // Mettre à jour Supabase
  await supabase
    .from('users')
    .update({
      subscription_status: 'active',
      subscription_tier: tier,
      stripe_customer_id: session.customer,
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId);

  // Si c'est le premier paiement ET qu'il y a un affiliate_id
  if (affiliateId && session.amount_total) {
    const amount = session.amount_total / 100; // Stripe utilise les centimes

    // Track la conversion pour commission
    await supabase.from('affiliate_conversions').insert({
      user_id: userId,
      affiliate_id: affiliateId,
      amount: amount,
      currency: session.currency || 'usd',
      subscription_type: tier,
      stripe_payment_id: session.payment_intent,
      converted_at: new Date().toISOString(),
    });

    console.log('💰 Conversion trackée:', { affiliateId, amount });
  }

  console.log('✅ User mis à jour:', userId);
}

/**
 * Gère la mise à jour d'un abonnement
 */
async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  const userId = subscription.metadata?.user_id;

  if (!userId) {
    console.error('❌ user_id manquant dans metadata');
    return;
  }

  const status = subscription.status;
  const tier = subscription.items.data[0]?.price.recurring?.interval === 'year'
    ? 'annual'
    : 'monthly';

  console.log('🔄 Abonnement mis à jour:', { userId, status, tier });

  await supabase
    .from('users')
    .update({
      subscription_status: status,
      subscription_tier: tier,
      subscription_expires_at: new Date(subscription.current_period_end * 1000).toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId);

  console.log('✅ Statut mis à jour:', { userId, status });
}

/**
 * Gère la suppression d'un abonnement
 */
async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  const userId = subscription.metadata?.user_id;

  if (!userId) {
    console.error('❌ user_id manquant');
    return;
  }

  console.log('🗑️ Abonnement supprimé:', userId);

  await supabase
    .from('users')
    .update({
      subscription_status: 'canceled',
      subscription_tier: null,
      subscription_expires_at: new Date(subscription.current_period_end * 1000).toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId);

  console.log('✅ Statut mis à jour: canceled');
}

/**
 * Gère un paiement de facture réussi
 */
async function handleInvoicePaid(invoice: Stripe.Invoice) {
  const userId = invoice.subscription_details?.metadata?.user_id;

  if (!userId) return;

  console.log('💳 Facture payée:', { userId, amount: invoice.amount_paid });

  // S'assurer que le statut est 'active'
  await supabase
    .from('users')
    .update({
      subscription_status: 'active',
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId);
}

/**
 * Gère un échec de paiement
 */
async function handleInvoicePaymentFailed(invoice: Stripe.Invoice) {
  const userId = invoice.subscription_details?.metadata?.user_id;

  if (!userId) return;

  console.log('❌ Paiement échoué:', userId);

  await supabase
    .from('users')
    .update({
      subscription_status: 'past_due',
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId);

  console.log('⚠️ Statut mis à jour: past_due');
}




