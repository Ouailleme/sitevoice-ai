import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:record/record.dart';  // Temporairement désactivé pour compilation
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import 'telemetry_service.dart';

/// Service de gestion de l'enregistrement audio
/// 
/// ⚠️ TEMPORAIREMENT DÉSACTIVÉ
/// Le package 'record' cause des problèmes de compilation Gradle.
/// Cette fonctionnalité sera réactivée une fois le problème résolu.
class AudioService {
  final Uuid _uuid = const Uuid();

  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  int _recordingDurationSeconds = 0;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentRecordingPath => _currentRecordingPath;
  int get recordingDurationSeconds => _recordingDurationSeconds;

  Stream<int> get durationStream => Stream.value(0);

  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    throw AudioException(
      message: 'Fonctionnalité temporairement indisponible',
      code: 'AUDIO_DISABLED',
    );
  }

  Future<void> pauseRecording() async {
    throw AudioException(
      message: 'Fonctionnalité temporairement indisponible',
      code: 'AUDIO_DISABLED',
    );
  }

  Future<void> resumeRecording() async {
    throw AudioException(
      message: 'Fonctionnalité temporairement indisponible',
      code: 'AUDIO_DISABLED',
    );
  }

  Future<String?> stopRecording() async {
    throw AudioException(
      message: 'Fonctionnalité temporairement indisponible',
      code: 'AUDIO_DISABLED',
    );
  }

  Future<void> cancelRecording() async {
    _isRecording = false;
    _isPaused = false;
    _currentRecordingPath = null;
    _recordingStartTime = null;
    _recordingDurationSeconds = 0;
    _durationTimer?.cancel();
  }

  Future<bool> hasPermission() async {
    return await checkMicrophonePermission();
  }

  void dispose() {
    _durationTimer?.cancel();
  }
}
