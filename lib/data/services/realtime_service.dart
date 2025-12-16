import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/job_model.dart';
import 'auth_service.dart';
import 'telemetry_service.dart';

/// Service de gestion des mises à jour temps réel (Supabase Realtime)
class RealtimeService {
  final AuthService _authService;
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _jobsChannel;
  final _jobUpdatesController = StreamController<JobModel>.broadcast();

  /// Stream des mises à jour de jobs en temps réel
  Stream<JobModel> get jobUpdates => _jobUpdatesController.stream;

  RealtimeService({required AuthService authService})
      : _authService = authService;

  // =====================================================
  // ÉCOUTE DES JOBS
  // =====================================================

  /// Démarrer l'écoute des changements de jobs pour l'utilisateur actuel
  Future<void> startListening() async {
    try {
      if (!_authService.isAuthenticated) {
        throw AppAuthException(message: 'Utilisateur non authentifié');
      }

      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      TelemetryService.logInfo('Démarrage écoute Realtime jobs');

      // Créer le canal Realtime
      _jobsChannel = _supabase.channel('jobs_changes')
        ..on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'UPDATE',
            schema: 'public',
            table: 'jobs',
            filter: 'company_id=eq.${userProfile!.companyId}',
          ),
          (payload, [ref]) {
            try {
              final jobData = payload['new'] as Map<String, dynamic>;
              final job = JobModel.fromJson(jobData);
              
              TelemetryService.logInfo(
                'Job mis à jour via Realtime: ${job.id} - Status: ${job.status}',
              );
              
              _jobUpdatesController.add(job);
            } catch (e) {
              TelemetryService.logError('Erreur parsing job Realtime', e);
            }
          },
        )
        ..subscribe();

      TelemetryService.logInfo('Écoute Realtime active');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur démarrage Realtime', e, stackTrace);
      throw NetworkException(
        message: 'Impossible de démarrer l\'écoute temps réel',
        originalError: e,
      );
    }
  }

  /// Arrêter l'écoute
  Future<void> stopListening() async {
    try {
      if (_jobsChannel != null) {
        await _supabase.removeChannel(_jobsChannel!);
        _jobsChannel = null;
        TelemetryService.logInfo('Écoute Realtime arrêtée');
      }
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur arrêt Realtime', e, stackTrace);
    }
  }

  // =====================================================
  // ÉCOUTE D'UN JOB SPÉCIFIQUE
  // =====================================================

  /// Écouter les changements d'un job spécifique
  /// Retourne un Stream qui émet le job à chaque mise à jour
  Stream<JobModel> listenToJob(String jobId) async* {
    final controller = StreamController<JobModel>();

    RealtimeChannel? channel;

    try {
      TelemetryService.logInfo('Écoute job spécifique: $jobId');

      channel = _supabase.channel('job_$jobId')
        ..on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'UPDATE',
            schema: 'public',
            table: 'jobs',
            filter: 'id=eq.$jobId',
          ),
          (payload, [ref]) {
            try {
              final jobData = payload['new'] as Map<String, dynamic>;
              final job = JobModel.fromJson(jobData);
              
              TelemetryService.logInfo('Job $jobId mis à jour: ${job.status}');
              
              if (!controller.isClosed) {
                controller.add(job);
              }
            } catch (e) {
              TelemetryService.logError('Erreur parsing job', e);
            }
          },
        )
        ..subscribe();

      // Émettre les updates
      await for (final job in controller.stream) {
        yield job;
      }
    } finally {
      if (channel != null) {
        await _supabase.removeChannel(channel);
      }
      await controller.close();
    }
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  void dispose() {
    stopListening();
    _jobUpdatesController.close();
  }
}


