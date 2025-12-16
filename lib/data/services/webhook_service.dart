import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import 'auth_service.dart';
import 'telemetry_service.dart';

/// Type de webhook
enum WebhookType {
  zapier,
  make,
  custom,
  quickbooks,
  xero,
  batigest,
}

extension WebhookTypeExtension on WebhookType {
  String get value {
    switch (this) {
      case WebhookType.zapier:
        return 'zapier';
      case WebhookType.make:
        return 'make';
      case WebhookType.custom:
        return 'custom';
      case WebhookType.quickbooks:
        return 'quickbooks';
      case WebhookType.xero:
        return 'xero';
      case WebhookType.batigest:
        return 'batigest';
    }
  }
}

/// Configuration de webhook
class WebhookConfig {
  final String id;
  final String name;
  final WebhookType type;
  final String endpointUrl;
  final String? secretKey;
  final List<String> events;
  final bool isActive;

  WebhookConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.endpointUrl,
    this.secretKey,
    required this.events,
    this.isActive = true,
  });

  factory WebhookConfig.fromJson(Map<String, dynamic> json) {
    return WebhookConfig(
      id: json['id'],
      name: json['name'],
      type: _webhookTypeFromString(json['webhook_type']),
      endpointUrl: json['endpoint_url'],
      secretKey: json['secret_key'],
      events: List<String>.from(json['events'] ?? []),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'webhook_type': type.value,
        'endpoint_url': endpointUrl,
        'secret_key': secretKey,
        'events': events,
        'is_active': isActive,
      };

  static WebhookType _webhookTypeFromString(String value) {
    switch (value) {
      case 'zapier':
        return WebhookType.zapier;
      case 'make':
        return WebhookType.make;
      case 'quickbooks':
        return WebhookType.quickbooks;
      case 'xero':
        return WebhookType.xero;
      case 'batigest':
        return WebhookType.batigest;
      default:
        return WebhookType.custom;
    }
  }
}

/// Service de gestion des webhooks
class WebhookService {
  final AuthService _authService;
  final SupabaseClient _supabase = Supabase.instance.client;

  WebhookService({required AuthService authService})
      : _authService = authService;

  // =====================================================
  // CRUD WEBHOOKS
  // =====================================================

  /// Créer un webhook
  Future<WebhookConfig> createWebhook(WebhookConfig config) async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      TelemetryService.logInfo('Création webhook: ${config.name}');

      final data = config.toJson();
      data['company_id'] = userProfile!.companyId;

      final result = await _supabase
          .from('webhook_configs')
          .insert(data)
          .select()
          .single();

      TelemetryService.logInfo('Webhook créé: ${result['id']}');

      return WebhookConfig.fromJson(result);
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur création webhook', e, stackTrace);
      throw ServerException(
        message: 'Impossible de créer le webhook',
        originalError: e,
      );
    }
  }

  /// Lister les webhooks de l'entreprise
  Future<List<WebhookConfig>> listWebhooks() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      final result = await _supabase
          .from('webhook_configs')
          .select()
          .eq('company_id', userProfile!.companyId!)
          .order('created_at', ascending: false);

      return result.map((json) => WebhookConfig.fromJson(json)).toList();
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur liste webhooks', e, stackTrace);
      return [];
    }
  }

  /// Mettre à jour un webhook
  Future<void> updateWebhook(String webhookId, WebhookConfig config) async {
    try {
      TelemetryService.logInfo('Mise à jour webhook: $webhookId');

      await _supabase
          .from('webhook_configs')
          .update(config.toJson())
          .eq('id', webhookId);

      TelemetryService.logInfo('Webhook mis à jour');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur mise à jour webhook', e, stackTrace);
      throw ServerException(
        message: 'Impossible de mettre à jour le webhook',
        originalError: e,
      );
    }
  }

  /// Supprimer un webhook
  Future<void> deleteWebhook(String webhookId) async {
    try {
      TelemetryService.logInfo('Suppression webhook: $webhookId');

      await _supabase.from('webhook_configs').delete().eq('id', webhookId);

      TelemetryService.logInfo('Webhook supprimé');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur suppression webhook', e, stackTrace);
      throw ServerException(
        message: 'Impossible de supprimer le webhook',
        originalError: e,
      );
    }
  }

  /// Activer/Désactiver un webhook
  Future<void> toggleWebhook(String webhookId, bool isActive) async {
    try {
      await _supabase
          .from('webhook_configs')
          .update({'is_active': isActive})
          .eq('id', webhookId);

      TelemetryService.logInfo('Webhook ${isActive ? 'activé' : 'désactivé'}: $webhookId');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur toggle webhook', e, stackTrace);
    }
  }

  // =====================================================
  // LOGS & MONITORING
  // =====================================================

  /// Obtenir les logs d'un webhook
  Future<List<Map<String, dynamic>>> getWebhookLogs(String webhookId,
      {int limit = 50}) async {
    try {
      final result = await _supabase
          .from('webhook_logs')
          .select()
          .eq('webhook_config_id', webhookId)
          .order('created_at', ascending: false)
          .limit(limit);

      return result;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur récupération logs', e, stackTrace);
      return [];
    }
  }

  /// Statistiques d'un webhook
  Future<Map<String, int>> getWebhookStats(String webhookId) async {
    try {
      final logs = await getWebhookLogs(webhookId, limit: 1000);

      final stats = {
        'total': logs.length,
        'success': logs.where((l) => l['status'] == 'success').length,
        'failed': logs.where((l) => l['status'] == 'failed').length,
        'pending': logs.where((l) => l['status'] == 'pending').length,
      };

      return stats;
    } catch (e) {
      return {'total': 0, 'success': 0, 'failed': 0, 'pending': 0};
    }
  }

  // =====================================================
  // TEMPLATES
  // =====================================================

  /// Obtenir les templates de webhooks prédéfinis
  List<WebhookConfig> getTemplates() {
    return [
      WebhookConfig(
        id: '',
        name: 'Zapier',
        type: WebhookType.zapier,
        endpointUrl: 'https://hooks.zapier.com/hooks/catch/YOUR_ID/',
        events: ['job.validated', 'job.invoiced'],
      ),
      WebhookConfig(
        id: '',
        name: 'Make (Integromat)',
        type: WebhookType.make,
        endpointUrl: 'https://hook.eu1.make.com/YOUR_WEBHOOK_ID',
        events: ['job.validated', 'job.invoiced'],
      ),
    ];
  }
}


