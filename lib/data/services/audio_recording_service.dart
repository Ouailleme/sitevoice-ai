import 'dart:async';
import 'dart:io';
// import 'package:flutter_sound/flutter_sound.dart';  // TEMPORAIREMENT DÉSACTIVÉ
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/errors/app_exception.dart';

/// Service pour gérer l'enregistrement audio
/// TEMPORAIREMENT DÉSACTIVÉ - En attente solution problème jlink.exe
class AudioRecordingService {
  // final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  String? _currentRecordingPath;
  Timer? _amplitudeTimer;
  final _amplitudeController = StreamController<double>.broadcast();
  StreamSubscription? _recorderSubscription;

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

  /// Initialiser le recorder
  Future<void> _initRecorder() async {
    throw AudioException(
      message: 'Enregistrement audio temporairement désactivé',
      code: 'AUDIO_DISABLED',
    );
  }

  /// Démarrer l'enregistrement audio
  /// 
  /// Retourne `true` si l'enregistrement a démarré avec succès
  /// Lance une [AudioException] en cas d'erreur
  Future<bool> startRecording() async {
    try {
      // Initialiser le recorder si nécessaire
      if (!_isRecorderInitialized) {
        await _initRecorder();
      }

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

      // Démarrer l'enregistrement
      // TEMPORAIREMENT DÉSACTIVÉ
      throw AudioException(
        message: 'Enregistrement audio temporairement désactivé',
        code: 'AUDIO_DISABLED',
      );

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
      await _recorderSubscription?.cancel();
      _recorderSubscription = null;
      _amplitudeController.add(0.0);
      
      // await _recorder.stopRecorder();

      final path = _currentRecordingPath;
      
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
    throw AudioException(
      message: 'Enregistrement audio temporairement désactivé',
      code: 'AUDIO_DISABLED',
    );
  }

  /// Reprendre l'enregistrement
  Future<void> resumeRecording() async {
    throw AudioException(
      message: 'Enregistrement audio temporairement désactivé',
      code: 'AUDIO_DISABLED',
    );
  }

  /// Vérifier si un enregistrement est en cours
  Future<bool> isRecording() async {
    return false;
  }

  /// Vérifier si l'enregistrement est en pause
  Future<bool> isPaused() async {
    return false;
  }

  /// Annuler l'enregistrement et supprimer le fichier
  Future<void> cancelRecording() async {
    try {
      await _recorderSubscription?.cancel();
      _recorderSubscription = null;
      _amplitudeController.add(0.0);
      
      // await _recorder.stopRecorder();

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

  /// Nettoyer les ressources
  void dispose() async {
    await _recorderSubscription?.cancel();
    _recorderSubscription = null;
    _amplitudeController.close();
    
    // if (_isRecorderInitialized) {
    //   await _recorder.closeRecorder();
    //   _isRecorderInitialized = false;
    // }
  }
}

