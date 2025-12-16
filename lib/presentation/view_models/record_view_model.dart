import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/sync_service.dart';
import '../../data/services/telemetry_service.dart';
import '../../data/repositories/job_repository.dart';

/// États possibles de l'enregistrement
enum RecordState {
  idle,
  recording,
  paused,
  processing,
  completed,
  error,
}

/// ViewModel pour l'écran d'enregistrement
class RecordViewModel extends ChangeNotifier {
  final AudioService _audioService;
  final AuthService _authService;
  final SyncService _syncService;
  final JobRepository _jobRepository = JobRepository();
  final Uuid _uuid = const Uuid();

  RecordState _state = RecordState.idle;
  int _durationSeconds = 0;
  String? _errorMessage;
  String? _currentJobId;

  RecordViewModel({
    required AudioService audioService,
    required AuthService authService,
    required SyncService syncService,
  })  : _audioService = audioService,
        _authService = authService,
        _syncService = syncService {
    // Écouter les changements de durée
    _audioService.durationStream.listen((duration) {
      _durationSeconds = duration;
      notifyListeners();
    });
  }

  // =====================================================
  // GETTERS
  // =====================================================

  RecordState get state => _state;
  bool get isIdle => _state == RecordState.idle;
  bool get isRecording => _state == RecordState.recording;
  bool get isPaused => _state == RecordState.paused;
  bool get isProcessing => _state == RecordState.processing;
  bool get isCompleted => _state == RecordState.completed;
  bool get hasError => _state == RecordState.error;
  
  int get durationSeconds => _durationSeconds;
  String? get errorMessage => _errorMessage;
  String? get currentJobId => _currentJobId;

  String get formattedDuration {
    final minutes = _durationSeconds ~/ 60;
    final seconds = _durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // =====================================================
  // ACTIONS
  // =====================================================

  /// Démarrer l'enregistrement
  Future<void> startRecording() async {
    try {
      _setState(RecordState.recording);
      _errorMessage = null;
      _durationSeconds = 0;

      await _audioService.startRecording();
      
      TelemetryService.logInfo('Enregistrement démarré');
    } catch (e) {
      _handleError(e);
    }
  }

  /// Mettre en pause l'enregistrement
  Future<void> pauseRecording() async {
    try {
      await _audioService.pauseRecording();
      _setState(RecordState.paused);
      
      TelemetryService.logInfo('Enregistrement en pause');
    } catch (e) {
      _handleError(e);
    }
  }

  /// Reprendre l'enregistrement
  Future<void> resumeRecording() async {
    try {
      await _audioService.resumeRecording();
      _setState(RecordState.recording);
      
      TelemetryService.logInfo('Enregistrement repris');
    } catch (e) {
      _handleError(e);
    }
  }

  /// Arrêter et sauvegarder l'enregistrement
  Future<String?> stopAndSaveRecording() async {
    try {
      _setState(RecordState.processing);

      // Arrêter l'enregistrement
      final audioPath = await _audioService.stopRecording();

      if (audioPath == null) {
        throw AudioException(message: 'Aucun fichier audio créé');
      }

      // Créer le job en local
      final jobId = _uuid.v4();
      _currentJobId = jobId;

      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw AppAuthException(message: 'Utilisateur non authentifié');
      }

      // Récupérer le profil pour avoir la company_id
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      final jobData = {
        'id': jobId,
        'company_id': userProfile!.companyId,
        'created_by': userId,
        'status': 'pending_sync',
        'audio_file_path': audioPath, // Chemin local pour l'instant
        'audio_duration_seconds': _durationSeconds,
        'is_synced': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Sauvegarder le job localement AVANT de l'ajouter à la queue
      await _jobRepository.saveJobLocally(jobId, jobData);
      TelemetryService.logInfo('Job sauvegardé localement: $jobId');

      // Ajouter à la queue de sync
      await _syncService.addToQueue(
        entityType: 'job',
        entityId: jobId,
        operation: 'create',
        payload: jobData,
      );

      _setState(RecordState.completed);
      TelemetryService.logInfo('Job créé et ajouté à la queue: $jobId');

      return jobId;
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// Annuler l'enregistrement
  Future<void> cancelRecording() async {
    try {
      await _audioService.cancelRecording();
      _reset();
      
      TelemetryService.logInfo('Enregistrement annulé');
    } catch (e) {
      _handleError(e);
    }
  }

  // =====================================================
  // HELPERS
  // =====================================================

  void _setState(RecordState newState) {
    _state = newState;
    notifyListeners();
  }

  void _handleError(dynamic error) {
    TelemetryService.logError('Erreur RecordViewModel', error);
    
    if (error is AppException) {
      _errorMessage = error.message;
    } else {
      _errorMessage = 'Une erreur est survenue';
    }
    
    _setState(RecordState.error);
  }

  void _reset() {
    _state = RecordState.idle;
    _durationSeconds = 0;
    _errorMessage = null;
    _currentJobId = null;
    notifyListeners();
  }

  /// Réinitialiser pour un nouvel enregistrement
  void resetForNewRecording() {
    _reset();
  }

  @override
  void dispose() {
    super.dispose();
  }
}


