import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sales_opportunity_model.dart';
import 'telemetry_service.dart';

/// Service pour la gestion du Sales Copilot (analyse predictive)
class SalesCopilotService {
  final SupabaseClient _supabase;
  final TelemetryService _telemetry;

  SalesCopilotService({
    required SupabaseClient supabase,
    required TelemetryService telemetry,
  })  : _supabase = supabase,
        _telemetry = telemetry;

  // =====================================================
  // OPPORTUNITES
  // =====================================================

  /// Recupere toutes les opportunites pour l'utilisateur connecte
  Future<List<SalesOpportunityModel>> getMyOpportunities({
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('sales_opportunities')
          .select('''
            *,
            clients!inner(name),
            equipment_tracking!inner(equipment_type)
          ''')
          .eq('assigned_to_user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;

      return (response as List)
          .map((json) => SalesOpportunityModel.fromJson({
                ...json,
                'clientName': json['clients']?['name'],
                'equipmentType': json['equipment_tracking']?['equipment_type'],
              }))
          .toList();
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to fetch opportunities',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Recupere les opportunites pending (non traitees)
  Future<List<SalesOpportunityModel>> getPendingOpportunities() async {
    return getMyOpportunities(status: 'pending');
  }

  /// Recupere le nombre d'opportunites non traitees
  Future<int> getPendingCount() async {
    try {
      final response = await _supabase
          .from('sales_opportunities')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('assigned_to_user_id', _supabase.auth.currentUser!.id)
          .eq('status', 'pending');

      return response.count ?? 0;
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to count pending opportunities',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  /// Accepte une opportunite
  Future<void> acceptOpportunity(String opportunityId) async {
    try {
      await _supabase.from('sales_opportunities').update({
        'status': 'accepted',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', opportunityId);

      await _telemetry.logEvent('opportunity_accepted', {
        'opportunity_id': opportunityId,
      });
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to accept opportunity',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Decline une opportunite
  Future<void> declineOpportunity(String opportunityId) async {
    try {
      await _supabase.from('sales_opportunities').update({
        'status': 'declined',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', opportunityId);

      await _telemetry.logEvent('opportunity_declined', {
        'opportunity_id': opportunityId,
      });
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to decline opportunity',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Marque une opportunite comme convertie (devis gagne)
  Future<void> convertOpportunity(
    String opportunityId, {
    double? actualValue,
  }) async {
    try {
      final updateData = {
        'status': 'converted',
        'converted_at': DateTime.now().toIso8601String(),
      };

      if (actualValue != null) {
        updateData['estimated_value'] = actualValue;
      }

      await _supabase
          .from('sales_opportunities')
          .update(updateData)
          .eq('id', opportunityId);

      await _telemetry.logEvent('opportunity_converted', {
        'opportunity_id': opportunityId,
        'actual_value': actualValue,
      });
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to convert opportunity',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // =====================================================
  // ANALYSE MANUELLE
  // =====================================================

  /// Declenche manuellement l'analyse Sales Copilot
  /// (appelle l'Edge Function)
  Future<Map<String, dynamic>> triggerAnalysis({
    String? companyId,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'sales-copilot-analyzer',
        body: {
          'company_id': companyId,
          'force_refresh': forceRefresh,
        },
      );

      if (response.status != 200) {
        throw Exception('Analysis failed: ${response.data}');
      }

      await _telemetry.logEvent('sales_copilot_analysis_triggered', {
        'company_id': companyId,
        'force_refresh': forceRefresh,
      });

      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to trigger sales copilot analysis',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // =====================================================
  // STREAM (Realtime)
  // =====================================================

  /// Stream des opportunites pour l'utilisateur connecte
  Stream<List<SalesOpportunityModel>> streamMyOpportunities() {
    return _supabase
        .from('sales_opportunities')
        .stream(primaryKey: ['id'])
        .eq('assigned_to_user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .map((data) => data
            .map((json) => SalesOpportunityModel.fromJson(json))
            .toList());
  }

  // =====================================================
  // STATISTIQUES
  // =====================================================

  /// Recupere les stats des opportunites (conversion rate, etc.)
  Future<Map<String, dynamic>> getOpportunityStats() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Compter par statut
      final response = await _supabase
          .from('sales_opportunities')
          .select('status')
          .eq('assigned_to_user_id', userId);

      final opportunities = response as List;
      final total = opportunities.length;

      if (total == 0) {
        return {
          'total': 0,
          'pending': 0,
          'accepted': 0,
          'converted': 0,
          'declined': 0,
          'conversion_rate': 0.0,
        };
      }

      final pending = opportunities.where((o) => o['status'] == 'pending').length;
      final accepted = opportunities.where((o) => o['status'] == 'accepted').length;
      final converted = opportunities.where((o) => o['status'] == 'converted').length;
      final declined = opportunities.where((o) => o['status'] == 'declined').length;

      final conversionRate = total > 0 ? (converted / total * 100) : 0.0;

      return {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'converted': converted,
        'declined': declined,
        'conversion_rate': conversionRate,
      };
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get opportunity stats',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'converted': 0,
        'declined': 0,
        'conversion_rate': 0.0,
      };
    }
  }

  /// Recupere la valeur totale des opportunites converties
  Future<double> getTotalConvertedValue() async {
    try {
      final response = await _supabase
          .from('sales_opportunities')
          .select('estimated_value')
          .eq('assigned_to_user_id', _supabase.auth.currentUser!.id)
          .eq('status', 'converted');

      final opportunities = response as List;
      double total = 0.0;

      for (final opp in opportunities) {
        final value = opp['estimated_value'];
        if (value != null) {
          total += (value as num).toDouble();
        }
      }

      return total;
    } catch (e, stackTrace) {
      await _telemetry.logError(
        'Failed to get total converted value',
        error: e,
        stackTrace: stackTrace,
      );
      return 0.0;
    }
  }
}




