// import 'package:flutter_stripe/flutter_stripe.dart';  // Temporairement désactivé
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import 'auth_service.dart';
import 'telemetry_service.dart';

/// Statut d'abonnement
enum SubscriptionStatus {
  trial,
  active,
  cancelled,
  expired,
}

/// Informations d'abonnement
class SubscriptionInfo {
  final SubscriptionStatus status;
  final DateTime? endsAt;
  final String? stripeSubscriptionId;
  final int daysRemaining;

  SubscriptionInfo({
    required this.status,
    this.endsAt,
    this.stripeSubscriptionId,
    required this.daysRemaining,
  });

  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.trial;
  bool get isTrial => status == SubscriptionStatus.trial;
  bool get needsPayment => status == SubscriptionStatus.expired || status == SubscriptionStatus.cancelled;
}

/// Service de gestion des paiements et abonnements
class PaymentService {
  final AuthService _authService;
  final SupabaseClient _supabase = Supabase.instance.client;

  PaymentService({required AuthService authService}) : _authService = authService;

  // =====================================================
  // INITIALISATION
  // =====================================================

  /// Initialiser Stripe
  static Future<void> initialize() async {
    // Stripe temporairement désactivé pour résoudre problèmes de compilation
    TelemetryService.logInfo('Stripe désactivé temporairement');
  }

  // =====================================================
  // INFORMATIONS ABONNEMENT
  // =====================================================

  /// Récupérer les informations d'abonnement de l'entreprise
  Future<SubscriptionInfo> getSubscriptionInfo() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      final companyData = await _supabase
          .from('companies')
          .select('subscription_status, subscription_ends_at, subscription_stripe_id')
          .eq('id', userProfile!.companyId!)
          .single();

      final statusStr = companyData['subscription_status'] as String?;
      final endsAtStr = companyData['subscription_ends_at'] as String?;
      final stripeId = companyData['subscription_stripe_id'] as String?;

      SubscriptionStatus status;
      switch (statusStr) {
        case 'trial':
          status = SubscriptionStatus.trial;
          break;
        case 'active':
          status = SubscriptionStatus.active;
          break;
        case 'cancelled':
          status = SubscriptionStatus.cancelled;
          break;
        case 'expired':
          status = SubscriptionStatus.expired;
          break;
        default:
          status = SubscriptionStatus.trial;
      }

      DateTime? endsAt;
      int daysRemaining = 0;
      
      if (endsAtStr != null) {
        endsAt = DateTime.parse(endsAtStr);
        daysRemaining = endsAt.difference(DateTime.now()).inDays;
        
        if (daysRemaining < 0) {
          daysRemaining = 0;
        }
      }

      return SubscriptionInfo(
        status: status,
        endsAt: endsAt,
        stripeSubscriptionId: stripeId,
        daysRemaining: daysRemaining,
      );
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur récupération abonnement', e, stackTrace);
      
      // En cas d'erreur, retourner un état par défaut
      return SubscriptionInfo(
        status: SubscriptionStatus.trial,
        daysRemaining: 0,
      );
    }
  }

  // =====================================================
  // CRÉATION ABONNEMENT
  // =====================================================

  /// Créer un abonnement Stripe
  Future<bool> createSubscription() async {
    try {
      TelemetryService.logInfo('Création abonnement Stripe');

      final userProfile = await _authService.getCurrentUserProfile();
      
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      // Appeler l'Edge Function pour créer le PaymentIntent
      final response = await _supabase.functions.invoke(
        'create-subscription',
        body: {
          'company_id': userProfile!.companyId,
          'price_in_cents': AppConstants.subscriptionPriceInCents,
        },
      );

      if (response.status != 200) {
        throw ServerException(
          message: 'Erreur lors de la création de l\'abonnement',
        );
      }

      // Stripe temporairement désactivé
      throw ServerException(
        message: 'Fonctionnalité de paiement désactivée temporairement. Utilisez le dashboard web.',
      );
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      
      TelemetryService.logError('Erreur création abonnement', e, stackTrace);
      throw ServerException(
        message: 'Impossible de créer l\'abonnement',
        originalError: e,
      );
    }
  }

  // =====================================================
  // GESTION ABONNEMENT
  // =====================================================

  /// Annuler l'abonnement
  Future<void> cancelSubscription() async {
    try {
      TelemetryService.logInfo('Annulation abonnement');

      final userProfile = await _authService.getCurrentUserProfile();
      
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      // Appeler l'Edge Function pour annuler
      final response = await _supabase.functions.invoke(
        'cancel-subscription',
        body: {
          'company_id': userProfile!.companyId,
        },
      );

      if (response.status != 200) {
        throw ServerException(
          message: 'Erreur lors de l\'annulation de l\'abonnement',
        );
      }

      TelemetryService.logInfo('Abonnement annulé');

      // Rafraîchir les infos
      await _refreshSubscriptionStatus();
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      
      TelemetryService.logError('Erreur annulation abonnement', e, stackTrace);
      throw ServerException(
        message: 'Impossible d\'annuler l\'abonnement',
        originalError: e,
      );
    }
  }

  /// Réactiver l'abonnement
  Future<void> reactivateSubscription() async {
    try {
      TelemetryService.logInfo('Réactivation abonnement');

      final userProfile = await _authService.getCurrentUserProfile();
      
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      // Appeler l'Edge Function pour réactiver
      final response = await _supabase.functions.invoke(
        'reactivate-subscription',
        body: {
          'company_id': userProfile!.companyId,
        },
      );

      if (response.status != 200) {
        throw ServerException(
          message: 'Erreur lors de la réactivation de l\'abonnement',
        );
      }

      TelemetryService.logInfo('Abonnement réactivé');

      // Rafraîchir les infos
      await _refreshSubscriptionStatus();
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      
      TelemetryService.logError('Erreur réactivation abonnement', e, stackTrace);
      throw ServerException(
        message: 'Impossible de réactiver l\'abonnement',
        originalError: e,
      );
    }
  }

  // =====================================================
  // HELPERS
  // =====================================================

  /// Rafraîchir le statut d'abonnement depuis la base
  Future<void> _refreshSubscriptionStatus() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      
      if (userProfile?.companyId == null) {
        return;
      }

      // Les webhooks Stripe mettront à jour automatiquement
      // On attend juste un peu pour laisser le temps
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      // Ignorer les erreurs de rafraîchissement
    }
  }

  /// Vérifier si l'abonnement est valide
  Future<bool> hasValidSubscription() async {
    try {
      final info = await getSubscriptionInfo();
      return info.isActive;
    } catch (e) {
      return false;
    }
  }
}


