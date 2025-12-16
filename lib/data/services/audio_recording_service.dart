import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/errors/app_exception.dart';

/// Service pour gérer l'enregistrement audio
/// Utilise le package `record` avec gestion complète des permissions
class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  Timer? _amplitudeTimer;
  final _amplitudeController = StreamController<double>.broadcast();

  /// Stream pour l'amplitude en temps réel (pour animation)
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Demander la permission d'accès au microphone
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Vérifier si la permission est accordée
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Démarrer l'enregistrement audio
  /// 
  /// Retourne `true` si l'enregistrement a démarré avec succès
  /// Lance une [AppException] en cas d'erreur
  Future<bool> startRecording() async {
    try {
      // Vérifier la permission
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          throw AudioException(
            message: 'Permission microphone refusée',
            code: 'PERMISSION_DENIED',
          );
        }
      }

      // Créer le chemin du fichier
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';

      // Vérifier que le recorder est disponible
      if (!await _audioRecorder.hasPermission()) {
        throw AudioException(
          message: 'Permission microphone non disponible',
          code: 'PERMISSION_NOT_AVAILABLE',
        );
      }

      // Démarrer l'enregistrement
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );

      // Démarrer le monitoring de l'amplitude
      _startAmplitudeMonitoring();

      return true;
    } catch (e) {
      throw AudioException(
        message: 'Erreur lors du démarrage de l\'enregistrement: $e',
        code: 'RECORDING_START_ERROR',
      );
    }
  }

  /// Arrêter l'enregistrement et retourner le chemin du fichier
  /// 
  /// Retourne le chemin du fichier audio enregistré
  /// Retourne `null` si aucun enregistrement n'est en cours
  Future<String?> stopRecording() async {
    try {
      _stopAmplitudeMonitoring();
      
      final path = await _audioRecorder.stop();
      
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final size = await file.length();
          if (size == 0) {
            throw AudioException(
              message: 'Le fichier audio est vide',
              code: 'EMPTY_AUDIO_FILE',
            );
          }
        }
      }
      
      return path;
    } catch (e) {
      throw AudioException(
        message: 'Erreur lors de l\'arrêt de l\'enregistrement: $e',
        code: 'RECORDING_STOP_ERROR',
      );
    }
  }

  /// Mettre en pause l'enregistrement
  Future<void> pauseRecording() async {
    try {
      await _audioRecorder.pause();
      _stopAmplitudeMonitoring();
    } catch (e) {
      throw AudioException(
        message: 'Erreur lors de la mise en pause: $e',
        code: 'RECORDING_PAUSE_ERROR',
      );
    }
  }

  /// Reprendre l'enregistrement
  Future<void> resumeRecording() async {
    try {
      await _audioRecorder.resume();
      _startAmplitudeMonitoring();
    } catch (e) {
      throw AudioException(
        message: 'Erreur lors de la reprise: $e',
        code: 'RECORDING_RESUME_ERROR',
      );
    }
  }

  /// Vérifier si un enregistrement est en cours
  Future<bool> isRecording() async {
    try {
      return await _audioRecorder.isRecording();
    } catch (e) {
      return false;
    }
  }

  /// Vérifier si l'enregistrement est en pause
  Future<bool> isPaused() async {
    try {
      return await _audioRecorder.isPaused();
    } catch (e) {
      return false;
    }
  }

  /// Annuler l'enregistrement et supprimer le fichier
  Future<void> cancelRecording() async {
    try {
      _stopAmplitudeMonitoring();
      await _audioRecorder.stop();

      // Supprimer le fichier si il existe
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      throw AudioException(
        message: 'Erreur lors de l\'annulation: $e',
        code: 'RECORDING_CANCEL_ERROR',
      );
    }
  }

  /// Démarrer le monitoring de l'amplitude pour l'animation
  void _startAmplitudeMonitoring() {
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) async {
        try {
          final amplitude = await _audioRecorder.getAmplitude();
          _amplitudeController.add(amplitude.current);
        } catch (e) {
          // Ignorer les erreurs de lecture d'amplitude
        }
      },
    );
  }

  /// Arrêter le monitoring de l'amplitude
  void _stopAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _amplitudeController.add(0.0);
  }

  /// Nettoyer les ressources
  void dispose() {
    _stopAmplitudeMonitoring();
    _amplitudeController.close();
    _audioRecorder.dispose();
  }
}

