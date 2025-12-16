import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'telemetry_service.dart';

/// Service de gestion de l'attribution et de l'affiliation
/// 
/// Gère :
/// - Deep links entrants (sitevoice://signup?ref=YOUTUBER_ID)
/// - Attribution des affiliés lors de l'inscription
/// - Tracking des conversions
/// - Webhooks vers Stripe/Rewardful pour commissions
/// 
/// Règles :
/// - Stocker affiliate_id dans user_metadata Supabase
/// - Générer des événements pour les commissions
/// - Support campagnes multi-sources (YouTube, Twitter, Blog, etc.)
class AffiliateService {
  final _supabase = Supabase.instance.client;
  final _appLinks = AppLinks();
  
  // Stream pour écouter les deep links
  StreamSubscription<Uri>? _linkSubscription;
  
  // Dernier affilié capturé (avant connexion)
  String? _pendingAffiliateId;
  
  /// Initialise l'écoute des deep links
  /// 
  /// À appeler au démarrage de l'app (dans main.dart)
  Future<void> initialize() async {
    try {
      // Récupérer le lien initial (si l'app a été lancée via deep link)
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }
      
      // Écouter les nouveaux liens (si l'app est déjà ouverte)
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri link) {
          _handleDeepLink(link);
        },
        onError: (err) {
          TelemetryService.logError(
            'Erreur lors de l\'écoute des deep links',
            err,
          );
        },
      );
      
      TelemetryService.logInfo('AffiliateService initialisé avec succès');
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Erreur lors de l\'initialisation de l\'AffiliateService',
        e,
        stackTrace,
      );
    }
  }
  
  /// Gère un deep link entrant
  /// 
  /// Formats supportés :
  /// - sitevoice://signup?ref=YOUTUBER_ID
  /// - sitevoice://signup?ref=YOUTUBER_ID&campaign=LAUNCH2024
  /// - https://app.sitevoice.ai/signup?ref=YOUTUBER_ID
  Future<void> _handleDeepLink(Uri link) async {
    try {
      TelemetryService.logInfo('Deep link reçu: ${link.toString()}');
      
      // Extraire le paramètre ref
      final affiliateId = link.queryParameters['ref'];
      final campaign = link.queryParameters['campaign'];
      
      if (affiliateId != null && affiliateId.isNotEmpty) {
        // Si l'utilisateur est connecté, on attribue immédiatement
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _attributeAffiliate(user.id, affiliateId, campaign);
        } else {
          // Sinon, on stocke pour l'attribution après l'inscription
          _pendingAffiliateId = affiliateId;
          TelemetryService.logInfo('Affiliate ID en attente: $affiliateId');
        }
      }
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Erreur lors du traitement du deep link',
        e,
        stackTrace,
      );
    }
  }
  
  /// Attribue un affilié à un utilisateur
  /// 
  /// Stocke les infos dans user_metadata ET dans une table dédiée
  Future<void> _attributeAffiliate(
    String userId,
    String affiliateId,
    String? campaign,
  ) async {
    try {
      // 1. Mise à jour des métadonnées utilisateur
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'affiliate_id': affiliateId,
            'campaign': campaign,
            'attributed_at': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // 2. Insertion dans la table d'attribution (pour analytics)
      await _supabase.from('user_attributions').insert({
        'user_id': userId,
        'affiliate_id': affiliateId,
        'campaign': campaign,
        'attributed_at': DateTime.now().toIso8601String(),
        'source': 'deep_link',
      });
      
      TelemetryService.logInfo(
        'Attribution réussie: User=$userId, Affiliate=$affiliateId, Campaign=$campaign',
      );
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Erreur lors de l\'attribution de l\'affilié',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
  
  /// Associe l'affilié en attente à l'utilisateur nouvellement inscrit
  /// 
  /// À appeler juste après la création du compte
  Future<void> attributePendingAffiliate(String userId) async {
    if (_pendingAffiliateId != null) {
      await _attributeAffiliate(userId, _pendingAffiliateId!, null);
      _pendingAffiliateId = null;
    }
  }
  
  /// Récupère l'affiliate_id de l'utilisateur actuel
  Future<String?> getCurrentAffiliateId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      return user.userMetadata?['affiliate_id'] as String?;
    } catch (e) {
      TelemetryService.logError(
        'Erreur lors de la récupération de l\'affiliate_id',
        e,
      );
      return null;
    }
  }
  
  /// Génère un lien d'affiliation pour un utilisateur (pour le partage)
  /// 
  /// Format: sitevoice://signup?ref=USER_CODE
  String generateAffiliateLink(String userCode) {
    return 'sitevoice://signup?ref=$userCode';
  }
  
  /// Génère un lien Web d'affiliation (pour partager sur réseaux sociaux)
  /// 
  /// Format: https://app.sitevoice.ai/signup?ref=USER_CODE
  String generateWebAffiliateLink(String userCode) {
    return 'https://app.sitevoice.ai/signup?ref=$userCode';
  }
  
  /// Envoie un événement de conversion pour déclencher une commission
  /// 
  /// À appeler lors du premier paiement d'un utilisateur
  Future<void> trackConversion({
    required String userId,
    required double amount,
    required String currency,
    required String subscriptionType, // 'monthly' ou 'annual'
  }) async {
    try {
      final affiliateId = await getCurrentAffiliateId();
      
      if (affiliateId != null) {
        // Insertion dans la table de conversions
        await _supabase.from('affiliate_conversions').insert({
          'user_id': userId,
          'affiliate_id': affiliateId,
          'amount': amount,
          'currency': currency,
          'subscription_type': subscriptionType,
          'converted_at': DateTime.now().toIso8601String(),
        });
        
        TelemetryService.logInfo(
          'Conversion trackée: User=$userId, Affiliate=$affiliateId, Amount=$amount $currency',
        );
        
        // Trigger d'un Edge Function pour webhook Stripe/Rewardful
        await _supabase.functions.invoke('track-affiliate-conversion', body: {
          'user_id': userId,
          'affiliate_id': affiliateId,
          'amount': amount,
          'currency': currency,
          'subscription_type': subscriptionType,
        });
      }
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Erreur lors du tracking de la conversion',
        e,
        stackTrace,
      );
    }
  }
  
  /// Nettoie les ressources
  void dispose() {
    _linkSubscription?.cancel();
  }
}



