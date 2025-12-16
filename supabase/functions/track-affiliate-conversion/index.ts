// ============================================
// EDGE FUNCTION : Track Affiliate Conversion
// ============================================
//
// Déclenche un webhook vers Stripe/Rewardful quand
// un utilisateur attributé effectue son premier paiement
//
// Input :
// - user_id: ID de l'utilisateur
// - affiliate_id: Code de l'affilié
// - amount: Montant du paiement
// - currency: Devise (USD)
// - subscription_type: 'monthly' ou 'annual'

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const STRIPE_WEBHOOK_URL = Deno.env.get('STRIPE_WEBHOOK_URL') || '';
const REWARDFUL_API_KEY = Deno.env.get('REWARDFUL_API_KEY') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

interface ConversionPayload {
  user_id: string;
  affiliate_id: string;
  amount: number;
  currency: string;
  subscription_type: string;
}

serve(async (req: Request) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    // Parse le payload
    const payload: ConversionPayload = await req.json();
    const { user_id, affiliate_id, amount, currency, subscription_type } = payload;

    console.log('📊 Tracking conversion:', {
      user_id,
      affiliate_id,
      amount,
      currency,
      subscription_type,
    });

    // 1. Récupérer les infos de l'attribution
    const { data: attribution, error: attrError } = await supabase
      .from('user_attributions')
      .select('*')
      .eq('user_id', user_id)
      .single();

    if (attrError || !attribution) {
      console.error('❌ Attribution non trouvée:', attrError);
      return new Response(
        JSON.stringify({ error: 'Attribution not found' }),
        { status: 404 },
      );
    }

    // 2. Récupérer l'email de l'utilisateur
    const { data: user, error: userError } = await supabase.auth.admin.getUserById(
      user_id,
    );

    if (userError || !user) {
      console.error('❌ Utilisateur non trouvé:', userError);
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404 },
      );
    }

    const userEmail = user.user.email;

    // 3. Calculer la commission (20% par défaut)
    const commissionRate = 0.20;
    const commissionAmount = amount * commissionRate;

    console.log('💰 Commission calculée:', {
      amount,
      rate: commissionRate,
      commission: commissionAmount,
    });

    // 4. Envoyer webhook à Stripe (si configuré)
    if (STRIPE_WEBHOOK_URL) {
      try {
        await sendStripeWebhook({
          user_id,
          user_email: userEmail!,
          affiliate_id,
          amount,
          currency,
          subscription_type,
          commission: commissionAmount,
          campaign: attribution.campaign,
        });
        console.log('✅ Webhook Stripe envoyé');
      } catch (error) {
        console.error('❌ Erreur webhook Stripe:', error);
      }
    }

    // 5. Envoyer à Rewardful (si configuré)
    if (REWARDFUL_API_KEY) {
      try {
        await sendRewardfulConversion({
          user_id,
          user_email: userEmail!,
          affiliate_id,
          amount,
          currency,
          subscription_type,
        });
        console.log('✅ Conversion Rewardful envoyée');
      } catch (error) {
        console.error('❌ Erreur Rewardful:', error);
      }
    }

    // 6. Logger l'événement
    console.log('🎉 Conversion trackée avec succès pour:', affiliate_id);

    return new Response(
      JSON.stringify({
        success: true,
        user_id,
        affiliate_id,
        commission: commissionAmount,
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      },
    );
  } catch (error) {
    console.error('❌ Erreur globale:', error);

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Internal server error',
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      },
    );
  }
});

/**
 * Envoie un webhook à Stripe avec les détails de la conversion
 */
async function sendStripeWebhook(data: {
  user_id: string;
  user_email: string;
  affiliate_id: string;
  amount: number;
  currency: string;
  subscription_type: string;
  commission: number;
  campaign?: string;
}) {
  const response = await fetch(STRIPE_WEBHOOK_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      event: 'affiliate.conversion',
      data: {
        user_id: data.user_id,
        user_email: data.user_email,
        affiliate_id: data.affiliate_id,
        amount: data.amount,
        currency: data.currency,
        subscription_type: data.subscription_type,
        commission_amount: data.commission,
        campaign: data.campaign,
        timestamp: new Date().toISOString(),
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Stripe webhook failed: ${response.statusText}`);
  }

  return await response.json();
}

/**
 * Envoie une conversion à Rewardful
 * Docs: https://www.getrewardful.com/docs/api/conversions
 */
async function sendRewardfulConversion(data: {
  user_id: string;
  user_email: string;
  affiliate_id: string;
  amount: number;
  currency: string;
  subscription_type: string;
}) {
  const response = await fetch('https://api.getrewardful.com/v1/conversions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${REWARDFUL_API_KEY}`,
    },
    body: JSON.stringify({
      referral_code: data.affiliate_id,
      email: data.user_email,
      amount: Math.round(data.amount * 100), // En centimes
      currency: data.currency,
      external_id: data.user_id,
      metadata: {
        subscription_type: data.subscription_type,
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Rewardful API failed: ${response.statusText}`);
  }

  return await response.json();
}




