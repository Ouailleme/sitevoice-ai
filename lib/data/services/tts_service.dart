import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import 'telemetry_service.dart';

/// Voix disponibles pour TTS
enum Voice {
  alloy, // Neutre
  echo, // Masculin
  fable, // Féminin britannique
  onyx, // Masculin profond
  nova, // Féminin jeune
  shimmer, // Féminin professionnel
}

extension VoiceExtension on Voice {
  String get value => name;
}

/// Service de Text-to-Speech (OpenAI + Flutter TTS fallback)
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // =====================================================
  // INITIALISATION
  // =====================================================

  /// Initialiser le service TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      TelemetryService.logInfo('Initialisation TtsService');

      // Configuration Flutter TTS (fallback)
      await _flutterTts.setLanguage('fr-FR');
      await _flutterTts.setSpeechRate(0.9); // Légèrement plus lent
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        TelemetryService.logError('Erreur TTS', msg);
      });

      _isInitialized = true;
      TelemetryService.logInfo('TtsService initialisé');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur init TTS', e, stackTrace);
    }
  }

  // =====================================================
  // SPEECH SYNTHESIS (OPENAI TTS)
  // =====================================================

  /// Synthétiser du texte avec OpenAI TTS (haute qualité)
  /// Retourne le chemin du fichier audio généré
  Future<String?> synthesizeWithOpenAI({
    required String text,
    Voice voice = Voice.shimmer,
    String model = 'tts-1', // 'tts-1' ou 'tts-1-hd'
  }) async {
    try {
      TelemetryService.logInfo('Synthèse OpenAI TTS: $text');

      const apiKey = String.fromEnvironment('OPENAI_API_KEY');
      if (apiKey.isEmpty) {
        throw ValidationException(message: 'OpenAI API Key manquante');
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/audio/speech'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'input': text,
          'voice': voice.value,
          'response_format': 'mp3',
          'speed': 0.9, // Légèrement plus lent pour clarté
        }),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Erreur OpenAI TTS: ${response.statusCode}',
        );
      }

      // TODO: Sauvegarder le fichier audio et le jouer
      // Pour l'instant on utilise le fallback Flutter TTS
      TelemetryService.logWarning('OpenAI TTS non implémenté, fallback Flutter TTS');
      
      return null;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur OpenAI TTS', e, stackTrace);
      return null;
    }
  }

  // =====================================================
  // SPEECH SYNTHESIS (FLUTTER TTS - FALLBACK)
  // =====================================================

  /// Parler avec Flutter TTS (fallback local)
  Future<void> speak(String text) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      TelemetryService.logInfo('TTS speak: $text');

      // Arrêter si déjà en train de parler
      if (_isSpeaking) {
        await stop();
      }

      await _flutterTts.speak(text);
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur TTS speak', e, stackTrace);
      throw AudioException(
        message: 'Impossible de synthétiser la parole',
        originalError: e,
      );
    }
  }

  /// Arrêter la synthèse vocale
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur TTS stop', e, stackTrace);
    }
  }

  /// Mettre en pause
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      TelemetryService.logError('Erreur TTS pause', e);
    }
  }

  // =====================================================
  // MODE CONVERSATIONNEL
  // =====================================================

  /// Poser une question vocalement (mode conversationnel)
  /// Utilisé quand requires_clarification = true
  Future<void> askClarificationQuestion(String question) async {
    try {
      TelemetryService.logInfo('Question de clarification: $question');

      // Préfixer pour contexte
      final fullText = 'Juste une question : $question';

      // Essayer OpenAI TTS d'abord
      final audioPath = await synthesizeWithOpenAI(
        text: fullText,
        voice: Voice.shimmer, // Voix féminine professionnelle
      );

      // Fallback Flutter TTS si OpenAI échoue
      if (audioPath == null) {
        await speak(fullText);
      }
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur question clarification', e, stackTrace);
      // Fallback
      await speak(question);
    }
  }

  /// Poser plusieurs questions en séquence
  Future<void> askMultipleQuestions(List<String> questions) async {
    for (final question in questions) {
      await askClarificationQuestion(question);
      
      // Attendre que la synthèse soit terminée
      while (_isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Pause entre les questions
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Confirmer une action vocalement
  Future<void> confirm(String message) async {
    await speak(message);
  }

  // =====================================================
  // TEMPLATES DE QUESTIONS
  // =====================================================

  /// Générer des questions de clarification depuis les raisons
  List<String> generateQuestionsFromReasons(List<String> reasons) {
    final questions = <String>[];

    for (final reason in reasons) {
      if (reason.contains('produit') || reason.contains('product')) {
        questions.add('Pouvez-vous préciser la référence du produit ?');
      } else if (reason.contains('client')) {
        questions.add('Quel est le nom exact du client ?');
      } else if (reason.contains('quantité') || reason.contains('quantity')) {
        questions.add('Combien exactement ?');
      } else if (reason.contains('prix') || reason.contains('price')) {
        questions.add('Quel est le prix unitaire ?');
      } else {
        questions.add('Pouvez-vous préciser : $reason ?');
      }
    }

    return questions;
  }

  // =====================================================
  // GETTERS
  // =====================================================

  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  // =====================================================
  // DISPOSE
  // =====================================================

  void dispose() {
    _flutterTts.stop();
  }
}


