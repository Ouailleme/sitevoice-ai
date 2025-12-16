import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'telemetry_service.dart';

/// Service de gestion du programme de parrainage (Viral Loop)
class ReferralService {
  final SupabaseClient _supabase;
  final TelemetryService _telemetry;

  ReferralService({
    required SupabaseClient supabase,
    required TelemetryService telemetry,
  })  : _supabase = supabase,
        _telemetry = telemetry;

  // =====================================================
  // REFERRAL CODE
  // =====================================================

  /// Recupere le code de parrainage de l'utilisateur connecte
  Future<String?> getMyReferralCode() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('users')
          .select('referral_code')
          .eq('id', userId)
          .single();

      return response['referral_code'] as String?;
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get referral code',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Applique un code de parrainage lors de l'inscription
  Future<bool> applyReferralCode(String code) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Chercher le parrain via son code
      final referrer = await _supabase
          .from('users')
          .select('id')
          .eq('referral_code', code.toUpperCase())
          .single();

      if (referrer == null) {
        return false;
      }

      final referrerId = referrer['id'] as String;

      // Ne pas pouvoir se parrainer soi-meme
      if (referrerId == userId) {
        return false;
      }

      // Appliquer le referred_by
      await _supabase.from('users').update({
        'referred_by': referrerId,
      }).eq('id', userId);

      await _telemetry.logEvent('referral_code_applied', {
        'code': code,
        'referrer_id': referrerId,
      });

      return true;
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to apply referral code',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // =====================================================
  // PARTAGE (VIRAL LOOP)
  // =====================================================

  /// Genere le message de partage avec le lien unique
  Future<String> generateShareMessage() async {
    final code = await getMyReferralCode();
    if (code == null) {
      return _getDefaultShareMessage();
    }

    // TODO: Remplacer par votre vrai deep link
    final appLink = 'https://sitevoice.app/r/$code';

    return '''
🎁 Rejoignez-moi sur SiteVoice AI !

L'app qui transforme mes rapports d'intervention en factures automatiquement.

✅ Dictée vocale intelligente
✅ Facturation automatique
✅ Gain de temps énorme

Utilisez mon code de parrainage pour obtenir 1 MOIS GRATUIT :

$code

Téléchargez l'app : $appLink

On gagne tous les deux 1 mois offert ! 🚀
''';
  }

  String _getDefaultShareMessage() {
    return '''
🎁 Découvrez SiteVoice AI !

L'app qui transforme vos rapports d'intervention en factures automatiquement.

✅ Dictée vocale
✅ Facturation automatique
✅ Gain de temps

Téléchargez maintenant : https://sitevoice.app
''';
  }

  /// Partage le code de parrainage (WhatsApp, SMS, etc.)
  Future<void> shareReferralCode() async {
    try {
      final message = await generateShareMessage();

      await Share.share(
        message,
        subject: 'Rejoignez-moi sur SiteVoice AI - 1 mois gratuit !',
      );

      await _telemetry.logEvent('referral_shared', {
        'method': 'native_share',
      });
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to share referral',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Partage via WhatsApp specifiquement
  Future<void> shareViaWhatsApp() async {
    try {
      final message = await generateShareMessage();
      final encodedMessage = Uri.encodeComponent(message);

      // WhatsApp URL scheme
      final whatsappUrl = 'whatsapp://send?text=$encodedMessage';

      await Share.shareUri(Uri.parse(whatsappUrl));

      await _telemetry.logEvent('referral_shared', {
        'method': 'whatsapp',
      });
    } catch (e, stackTrace) {
      // Fallback sur le partage natif si WhatsApp n'est pas installe
      await shareReferralCode();
    }
  }

  // =====================================================
  // STATISTIQUES
  // =====================================================

  /// Recupere les stats de parrainage de l'utilisateur
  Future<ReferralStats> getMyReferralStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return ReferralStats.empty();
      }

      // Compter les referrals
      final referrals = await _supabase
          .from('referrals')
          .select('status')
          .eq('referrer_id', userId);

      final total = (referrals as List).length;
      final pending = referrals.where((r) => r['status'] == 'pending').length;
      final converted = referrals.where((r) => r['status'] == 'converted' || r['status'] == 'rewarded').length;

      // Recuperer le balance
      final user = await _supabase
          .from('users')
          .select('referral_balance')
          .eq('id', userId)
          .single();

      final balance = user['referral_balance'] as int? ?? 0;

      return ReferralStats(
        totalReferrals: total,
        pendingReferrals: pending,
        convertedReferrals: converted,
        monthsEarned: balance,
      );
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get referral stats',
        error: e,
        stackTrace: stackTrace,
      );
      return ReferralStats.empty();
    }
  }

  /// Liste des personnes parrainées
  Future<List<ReferralInfo>> getMyReferrals() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('referrals')
          .select('''
            *,
            referee:referee_id (
              full_name,
              email
            )
          ''')
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReferralInfo.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get referrals list',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // =====================================================
  // REWARDS
  // =====================================================

  /// Applique les recompenses quand un filleul paye
  /// (Normalement appele par l'Edge Function Stripe)
  Future<void> applyRewards(String refereeId) async {
    try {
      await _supabase.rpc('apply_referral_rewards', params: {
        'p_referee_id': refereeId,
      });

      await _telemetry.logEvent('referral_rewards_applied', {
        'referee_id': refereeId,
      });
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to apply referral rewards',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

// =====================================================
// DATA CLASSES
// =====================================================

class ReferralStats {
  final int totalReferrals;
  final int pendingReferrals;
  final int convertedReferrals;
  final int monthsEarned;

  ReferralStats({
    required this.totalReferrals,
    required this.pendingReferrals,
    required this.convertedReferrals,
    required this.monthsEarned,
  });

  factory ReferralStats.empty() {
    return ReferralStats(
      totalReferrals: 0,
      pendingReferrals: 0,
      convertedReferrals: 0,
      monthsEarned: 0,
    );
  }

  double get conversionRate {
    if (totalReferrals == 0) return 0.0;
    return (convertedReferrals / totalReferrals) * 100;
  }
}

class ReferralInfo {
  final String id;
  final String referralCode;
  final String status;
  final DateTime referredAt;
  final DateTime? convertedAt;
  final String? refereeName;
  final String? refereeEmail;

  ReferralInfo({
    required this.id,
    required this.referralCode,
    required this.status,
    required this.referredAt,
    this.convertedAt,
    this.refereeName,
    this.refereeEmail,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      id: json['id'],
      referralCode: json['referral_code'],
      status: json['status'],
      referredAt: DateTime.parse(json['referred_at']),
      convertedAt: json['converted_at'] != null
          ? DateTime.parse(json['converted_at'])
          : null,
      refereeName: json['referee']?['full_name'],
      refereeEmail: json['referee']?['email'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isConverted => status == 'converted' || status == 'rewarded';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'converted':
        return 'Converti';
      case 'rewarded':
        return 'Récompensé';
      default:
        return status;
    }
  }
}




