import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/telemetry_service.dart';
import '../../data/services/affiliate_service.dart';

/// Service de gestion de la facturation via Stripe Web-Only
/// 
/// V2.3 - Stratégie Web Payments :
/// - Évite les 30% de frais Apple/Google
/// - Utilise Stripe Checkout (hébergé)
/// - Source of Truth : Supabase (subscription_status)
/// - Realtime : L'app écoute les changements de statut
/// 
/// Flux :
/// 1. User clique "Payer" → Ouvre Stripe Web
/// 2. User paie → Stripe Webhook → Edge Function
/// 3. Edge Function → Update Supabase
/// 4. App → Reçoit update via Realtime → Débloque UI
class BillingService {
  final _supabase = Supabase.instance.client;
  final AffiliateService? _affiliateService;
  
  // URL du Dashboard Next.js (V3.0 - Hybrid Ecosystem)
  // Le Mobile ne gère plus les paiements directement, il redirige vers le Web
  static const String webDashboardBillingUrl = 'https://app.sitevoice.ai/dashboard/billing';
  
  // Stream pour écouter les changements de statut
  StreamSubscription<List<Map<String, dynamic>>>? _subscriptionStream;
  
  BillingService({AffiliateService? affiliateService})
      : _affiliateService = affiliateService;
  
  /// Initialise l'écoute du statut d'abonnement
  /// 
  /// À appeler au démarrage de l'app (après authentification)
  Future<void> initialize() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        TelemetryService.logInfo('BillingService : Utilisateur non connecté');
        return;
      }
      
      // Écouter les changements sur la table users
      _subscriptionStream = _supabase
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .listen(
            (data) {
              if (data.isNotEmpty) {
                _onSubscriptionStatusChanged(data.first);
              }
            },
            onError: (error) {
              TelemetryService.logError(
                'Erreur lors de l\'écoute du statut d\'abonnement',
                error,
              );
            },
          );
      
      TelemetryService.logInfo('BillingService initialisé avec succès');
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Erreur lors de l\'initialisation du BillingService',
        e,
        stackTrace,
      );
    }
  }
  
  /// Callback quand le statut d'abonnement change
  void _onSubscriptionStatusChanged(Map<String, dynamic> userData) {
    final subscriptionStatus = userData['subscription_status'] as String?;
    final subscriptionTier = userData['subscription_tier'] as String?;
    
    TelemetryService.logInfo(
      'Statut abonnement mis à jour: status=$subscriptionStatus, tier=$subscriptionTier',
    );
    
    // Ici, on pourrait notifier l'app via un Stream ou un callback
    // Pour l'instant, les Widgets écoutent directement via Provider
  }
  
  /// V3.0 - Hybrid Ecosystem : Ouvre le dashboard Web pour gérer l'abonnement
  /// 
  /// Le Mobile ne gère plus les paiements directement.
  /// Il redirige vers le Web qui gère Stripe Checkout, les factures, etc.
  Future<bool> openWebBilling() async {
    return _openWebDashboard();
  }
  
  /// Alias pour compatibilité avec l'ancien code
  Future<bool> openMonthlyCheckout() async => openWebBilling();
  Future<bool> openAnnualCheckout() async => openWebBilling();
  Future<bool> openOTOCheckout() async => openWebBilling();
  
  /// V3.0 - Ouvre le dashboard Web (Next.js) pour la facturation
  /// 
  /// Plus simple : le Mobile ne fait que rediriger vers le Web.
  /// Le Web gère tout : Stripe, factures, abonnements, etc.
  Future<bool> _openWebDashboard() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        TelemetryService.logError('Tentative d\'ouverture billing sans authentification');
        return false;
      }
      
      TelemetryService.logInfo(
        'Ouverture du dashboard Web pour billing (user=${user.id})',
      );
      
      // Ouvrir le dashboard dans le navigateur système
      final uri = Uri.parse(webDashboardBillingUrl);
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Navigateur externe
      );
      
      if (success) {
        TelemetryService.logInfo('Dashboard Web ouvert avec succès');
      } else {
        TelemetryService.logError('Impossible d\'ouvrir le dashboard Web');
      }
      
      return success;
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Erreur lors de l\'ouverture du dashboard Web',
        e,
        stackTrace,
      );
      return false;
    }
  }
  
  /// Ouvre le portail client Stripe (gestion factures/désabonnement)
  /// 
  /// URL à récupérer via une Edge Function Supabase
  Future<bool> openCustomerPortal() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      // Appeler l'Edge Function pour générer un lien de portail
      final response = await _supabase.functions.invoke(
        'create-stripe-portal-link',
        body: {'user_id': user.id},
      );
      
      final portalUrl = response.data['url'] as String?;
      
      if (portalUrl == null) {
        TelemetryService.logError('URL portail Stripe non reçue');
        return false;
      }
      
      // Ouvrir le portail
      return await launchUrl(
        Uri.parse(portalUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Erreur lors de l\'ouverture du portail client',
        e,
        stackTrace,
      );
      return false;
    }
  }
  
  /// Rafraîchit le statut d'abonnement depuis Supabase
  /// 
  /// À appeler quand l'utilisateur revient dans l'app après un paiement
  Future<Map<String, dynamic>?> refreshSubscriptionStatus() async {
    try {
      TelemetryService.logInfo('Rafraîchissement du statut d\'abonnement');
      
      // Rafraîchir la session Supabase
      await _supabase.auth.refreshSession();
      
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      // Récupérer le statut depuis la table users
      final response = await _supabase
          .from('users')
          .select('subscription_status, subscription_tier, subscription_expires_at')
          .eq('id', user.id)
          .single();
      
      TelemetryService.logInfo(
        'Statut abonnement rafraîchi: ${response['subscription_status']}',
      );
      
      return response;
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Erreur lors du rafraîchissement du statut',
        e,
        stackTrace,
      );
      return null;
    }
  }
  
  /// Vérifie si l'utilisateur est premium (en temps réel)
  Future<bool> isPremium() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      final response = await _supabase
          .from('users')
          .select('subscription_status')
          .eq('id', user.id)
          .single();
      
      final status = response['subscription_status'] as String?;
      
      // Statuts considérés comme "premium"
      return status == 'active' || status == 'trialing';
    } catch (e) {
      TelemetryService.logError(
        'Erreur lors de la vérification du statut premium',
        e,
      );
      return false;
    }
  }
  
  /// Récupère les détails de l'abonnement
  Future<SubscriptionDetails?> getSubscriptionDetails() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      final response = await _supabase
          .from('users')
          .select('subscription_status, subscription_tier, subscription_expires_at')
          .eq('id', user.id)
          .single();
      
      return SubscriptionDetails(
        status: response['subscription_status'] as String?,
        tier: response['subscription_tier'] as String?,
        expiresAt: response['subscription_expires_at'] != null
            ? DateTime.parse(response['subscription_expires_at'] as String)
            : null,
      );
    } catch (e) {
      TelemetryService.logError(
        'Erreur lors de la récupération des détails d\'abonnement',
        e,
      );
      return null;
    }
  }
  
  /// Nettoie les ressources
  void dispose() {
    _subscriptionStream?.cancel();
  }
}

/// Détails d'un abonnement
class SubscriptionDetails {
  final String? status; // 'active', 'canceled', 'past_due', 'trialing', etc.
  final String? tier; // 'monthly', 'annual'
  final DateTime? expiresAt;
  
  const SubscriptionDetails({
    this.status,
    this.tier,
    this.expiresAt,
  });
  
  bool get isActive => status == 'active' || status == 'trialing';
  bool get isPastDue => status == 'past_due';
  bool get isCanceled => status == 'canceled';
}


