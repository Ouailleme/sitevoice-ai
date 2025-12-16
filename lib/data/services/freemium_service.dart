import 'package:supabase_flutter/supabase_flutter.dart';
import 'telemetry_service.dart';

/// Service de gestion du Paywall Freemium
/// 3 rapports gratuits puis blocage
class FreemiumService {
  final SupabaseClient _supabase;
  final TelemetryService _telemetry;

  FreemiumService({
    required SupabaseClient supabase,
    required TelemetryService telemetry,
  })  : _supabase = supabase,
        _telemetry = telemetry;

  static const int DEFAULT_FREE_LIMIT = 3;

  // =====================================================
  // COMPTEUR
  // =====================================================

  /// Recupere le nombre de rapports gratuits utilises
  Future<int> getFreeReportsUsed() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('users')
          .select('free_reports_used')
          .eq('id', userId)
          .single();

      return response['free_reports_used'] as int? ?? 0;
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get free reports used',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  /// Recupere la limite de rapports gratuits
  Future<int> getFreeReportsLimit() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return DEFAULT_FREE_LIMIT;

      final response = await _supabase
          .from('users')
          .select('free_reports_limit')
          .eq('id', userId)
          .single();

      return response['free_reports_limit'] as int? ?? DEFAULT_FREE_LIMIT;
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get free reports limit',
        error: e,
        stackTrace: stackTrace,
      );
      return DEFAULT_FREE_LIMIT;
    }
  }

  /// Verifie si l'utilisateur a atteint la limite
  Future<bool> hasHitLimit() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.rpc('check_freemium_limit', params: {
        'p_user_id': userId,
      });

      return response as bool;
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to check freemium limit',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Recupere les stats freemium (used, limit, remaining)
  Future<FreemiumStats> getFreemiumStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return FreemiumStats.empty();

      final response = await _supabase
          .from('users')
          .select('free_reports_used, free_reports_limit, referral_balance')
          .eq('id', userId)
          .single();

      final used = response['free_reports_used'] as int? ?? 0;
      final limit = response['free_reports_limit'] as int? ?? DEFAULT_FREE_LIMIT;
      final referralBalance = response['referral_balance'] as int? ?? 0;

      // Verifier si l'user a un abonnement actif
      final hasSubscription = await _hasActiveSubscription();

      return FreemiumStats(
        reportsUsed: used,
        reportsLimit: limit,
        referralBalance: referralBalance,
        hasActiveSubscription: hasSubscription,
      );
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get freemium stats',
        error: e,
        stackTrace: stackTrace,
      );
      return FreemiumStats.empty();
    }
  }

  Future<bool> _hasActiveSubscription() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('subscriptions')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // =====================================================
  // PAYWALL EVENTS
  // =====================================================

  /// Log un event paywall pour analytics
  Future<void> logPaywallEvent({
    required String eventType,
    String? actionTaken,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final stats = await getFreemiumStats();

      await _supabase.from('paywall_events').insert({
        'user_id': userId,
        'event_type': eventType,
        'reports_used': stats.reportsUsed,
        'reports_limit': stats.reportsLimit,
        'action_taken': actionTaken,
      });

      await _telemetry.logEvent('paywall_event', {
        'type': eventType,
        'action': actionTaken,
      });
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to log paywall event',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // =====================================================
  // ACTIONS UTILISATEUR
  // =====================================================

  /// L'utilisateur a clique sur "Upgrade"
  Future<void> onUpgradeClicked() async {
    await logPaywallEvent(
      eventType: 'clicked_upgrade',
      actionTaken: 'upgrade',
    );
  }

  /// L'utilisateur a ferme le paywall
  Future<void> onPaywallDismissed() async {
    await logPaywallEvent(
      eventType: 'dismissed',
      actionTaken: 'dismiss',
    );
  }

  /// L'utilisateur a choisi de parrainer
  Future<void> onReferFriendClicked() async {
    await logPaywallEvent(
      eventType: 'clicked_refer',
      actionTaken: 'refer_friend',
    );
  }

  /// L'utilisateur a converti (paye)
  Future<void> onConverted() async {
    await logPaywallEvent(
      eventType: 'converted',
      actionTaken: 'paid',
    );
  }

  // =====================================================
  // BONUS & REWARDS
  // =====================================================

  /// Ajoute des rapports bonus (ex: parrainage, promo)
  Future<void> addBonusReports(int count, String reason) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('add_bonus_reports', params: {
        'p_user_id': userId,
        'p_count': count,
      });

      await _telemetry.logEvent('bonus_reports_added', {
        'count': count,
        'reason': reason,
      });
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to add bonus reports',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

// =====================================================
// DATA CLASSES
// =====================================================

class FreemiumStats {
  final int reportsUsed;
  final int reportsLimit;
  final int referralBalance;
  final bool hasActiveSubscription;

  FreemiumStats({
    required this.reportsUsed,
    required this.reportsLimit,
    required this.referralBalance,
    required this.hasActiveSubscription,
  });

  factory FreemiumStats.empty() {
    return FreemiumStats(
      reportsUsed: 0,
      reportsLimit: FreemiumService.DEFAULT_FREE_LIMIT,
      referralBalance: 0,
      hasActiveSubscription: false,
    );
  }

  int get reportsRemaining {
    if (hasActiveSubscription) return 999; // Illimite
    return (reportsLimit - reportsUsed).clamp(0, reportsLimit);
  }

  bool get hasHitLimit => !hasActiveSubscription && reportsUsed >= reportsLimit;

  double get usagePercentage {
    if (hasActiveSubscription) return 0.0;
    return (reportsUsed / reportsLimit).clamp(0.0, 1.0);
  }

  /// Message a afficher a l'utilisateur
  String get statusMessage {
    if (hasActiveSubscription) {
      return 'Rapports illimités';
    }

    if (hasHitLimit) {
      return 'Limite atteinte - Passez Premium !';
    }

    final remaining = reportsRemaining;
    if (remaining == 1) {
      return 'Dernier rapport gratuit !';
    }

    return '$remaining rapports gratuits restants';
  }

  /// Couleur du statut
  String get statusColor {
    if (hasActiveSubscription) return 'success';
    if (hasHitLimit) return 'error';
    if (reportsRemaining == 1) return 'warning';
    return 'info';
  }
}




