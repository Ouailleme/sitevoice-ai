import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import 'telemetry_service.dart';

/// Service pour gérer l'enregistrement audio avec flutter_sound
class AudioRecordingService {
  final Uuid _uuid = const Uuid();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentRecordingPath;
  Timer? _durationTimer;
  int _recordingDurationSeconds = 0;

  final StreamController<int> _durationController = StreamController<int>.broadcast();
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  StreamSubscription? _recorderSubscription;

  AudioRecordingService() {
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      TelemetryService.logInfo('AudioRecordingService initialized');
    } catch (e, stack) {
      TelemetryService.logError('Failed to initialize recorder', e, stack);
    }
  }

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentRecordingPath => _currentRecordingPath;
  int get recordingDurationSeconds => _recordingDurationSeconds;

  Stream<int> get durationStream => _durationController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Vérifier si la permission microphone est accordée
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Demander la permission microphone
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Vérifier si on a la permission
  Future<bool> hasPermission() async {
    return await checkMicrophonePermission();
  }

  /// Démarrer l'enregistrement
  Future<void> startRecording() async {
    try {
      if (!await requestMicrophonePermission()) {
        throw PermissionException(message: 'Permission microphone refusée');
      }

      final directory = await getApplicationDocumentsDirectory();
      _currentRecordingPath = '${directory.path}/${_uuid.v4()}.aac';

      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );

      _isRecording = true;
      _isPaused = false;
      _recordingDurationSeconds = 0;

      // Timer pour la durée
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDurationSeconds++;
        _durationController.add(_recordingDurationSeconds);
      });

      // Stream pour l'amplitude (animation waveform)
      _recorderSubscription = _recorder.onProgress!.listen((e) {
        if (e.decibels != null) {
          // Normaliser entre 0 et 1
          final normalizedAmplitude = (e.decibels! + 60) / 60;
          _amplitudeController.add(normalizedAmplitude.clamp(0.0, 1.0));
        }
      });

      TelemetryService.logInfo('Recording started: $_currentRecordingPath');
    } catch (e, stack) {
      TelemetryService.logError('Error starting recording', e, stack);
      throw AudioException(
        message: 'Impossible de démarrer l\'enregistrement: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Mettre en pause l'enregistrement
  Future<void> pauseRecording() async {
    try {
      if (!_isRecording || _isPaused) {
        throw AudioException(message: 'Aucun enregistrement en cours à mettre en pause');
      }
      
      await _recorder.pauseRecorder();
      _isPaused = true;
      _durationTimer?.cancel();
      _recorderSubscription?.pause();
      _amplitudeController.add(0.0);
      
      TelemetryService.logInfo('Recording paused');
    } catch (e, stack) {
      TelemetryService.logError('Error pausing recording', e, stack);
      throw AudioException(
        message: 'Impossible de mettre en pause: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Reprendre l'enregistrement
  Future<void> resumeRecording() async {
    try {
      if (!_isPaused) {
        throw AudioException(message: 'Aucun enregistrement en pause à reprendre');
      }
      
      await _recorder.resumeRecorder();
      _isPaused = false;
      _isRecording = true;
      
      // Redémarrer le timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDurationSeconds++;
        _durationController.add(_recordingDurationSeconds);
      });
      
      _recorderSubscription?.resume();
      
      TelemetryService.logInfo('Recording resumed');
    } catch (e, stack) {
      TelemetryService.logError('Error resuming recording', e, stack);
      throw AudioException(
        message: 'Impossible de reprendre: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Arrêter l'enregistrement et retourner le chemin du fichier
  Future<String?> stopRecording() async {
    try {
      await _recorderSubscription?.cancel();
      _recorderSubscription = null;
      _amplitudeController.add(0.0);

      await _recorder.stopRecorder();

      final path = _currentRecordingPath;

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final size = await file.length();
          if (size == 0) {
            await file.delete();
            throw AudioException(
              message: 'Le fichier audio est vide',
              code: 'EMPTY_AUDIO_FILE',
            );
          }
          TelemetryService.logInfo('Recording stopped: $path (${size} bytes)');
          return path;
        }
      }
      
      throw AudioException(message: 'Aucun fichier audio enregistré');
    } catch (e, stack) {
      TelemetryService.logError('Error stopping recording', e, stack);
      throw AudioException(
        message: 'Impossible d\'arrêter l\'enregistrement: ${e.toString()}',
        originalError: e,
      );
    } finally {
      _resetState();
    }
  }

  /// Annuler l'enregistrement et supprimer le fichier
  Future<void> cancelRecording() async {
    try {
      await _recorder.stopRecorder();
      
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          TelemetryService.logInfo('Recording cancelled and deleted: $_currentRecordingPath');
        }
      }
    } catch (e, stack) {
      TelemetryService.logError('Error cancelling recording', e, stack);
    } finally {
      _resetState();
    }
  }

  /// Réinitialiser l'état
  void _resetState() {
    _isRecording = false;
    _isPaused = false;
    _currentRecordingPath = null;
    _recordingDurationSeconds = 0;
    _durationTimer?.cancel();
    _durationTimer = null;
    _durationController.add(0);
    _amplitudeController.add(0.0);
  }

  /// Nettoyer les ressources
  void dispose() {
    _durationTimer?.cancel();
    _recorderSubscription?.cancel();
    _durationController.close();
    _amplitudeController.close();
    _recorder.closeRecorder();
  }
}
