import 'dart:async';
import '../../core/errors/app_exception.dart';
import 'audio_recording_service.dart';
import 'telemetry_service.dart';

/// Service de gestion de l'enregistrement audio
/// 
/// Ce service fait le pont entre le ViewModel et le AudioRecordingService
/// Il ajoute une couche de gestion du timer et de l'état
class AudioService {
  final AudioRecordingService _recordingService = AudioRecordingService();

  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentRecordingPath;
  Timer? _durationTimer;
  int _recordingDurationSeconds = 0;

  final _durationController = StreamController<int>.broadcast();

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentRecordingPath => _currentRecordingPath;
  int get recordingDurationSeconds => _recordingDurationSeconds;

  Stream<int> get durationStream => _durationController.stream;
  Stream<double> get amplitudeStream => _recordingService.amplitudeStream;

  Future<bool> checkMicrophonePermission() async {
    return await _recordingService.hasPermission();
  }

  Future<bool> requestMicrophonePermission() async {
    return await _recordingService.requestPermission();
  }

  Future<void> startRecording() async {
    try {
      final success = await _recordingService.startRecording();
      if (!success) {
        throw AudioException(
          message: 'Impossible de démarrer l\'enregistrement',
          code: 'RECORDING_START_FAILED',
        );
      }

      _isRecording = true;
      _isPaused = false;
      _recordingDurationSeconds = 0;
      _startDurationTimer();

      TelemetryService.logInfo('Enregistrement audio démarré');
    } catch (e) {
      TelemetryService.logError('Erreur démarrage enregistrement', e);
      rethrow;
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _recordingService.pauseRecording();
      _isPaused = true;
      _stopDurationTimer();

      TelemetryService.logInfo('Enregistrement mis en pause');
    } catch (e) {
      TelemetryService.logError('Erreur pause enregistrement', e);
      rethrow;
    }
  }

  Future<void> resumeRecording() async {
    try {
      await _recordingService.resumeRecording();
      _isPaused = false;
      _startDurationTimer();

      TelemetryService.logInfo('Enregistrement repris');
    } catch (e) {
      TelemetryService.logError('Erreur reprise enregistrement', e);
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recordingService.stopRecording();
      _isRecording = false;
      _isPaused = false;
      _stopDurationTimer();
      _currentRecordingPath = path;

      TelemetryService.logInfo('Enregistrement arrêté: $path');
      return path;
    } catch (e) {
      TelemetryService.logError('Erreur arrêt enregistrement', e);
      rethrow;
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _recordingService.cancelRecording();
      _isRecording = false;
      _isPaused = false;
      _currentRecordingPath = null;
      _recordingDurationSeconds = 0;
      _stopDurationTimer();

      TelemetryService.logInfo('Enregistrement annulé');
    } catch (e) {
      TelemetryService.logError('Erreur annulation enregistrement', e);
      rethrow;
    }
  }

  Future<bool> hasPermission() async {
    return await _recordingService.hasPermission();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDurationSeconds++;
      _durationController.add(_recordingDurationSeconds);
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void dispose() {
    _stopDurationTimer();
    _durationController.close();
    _recordingService.dispose();
  }
}
