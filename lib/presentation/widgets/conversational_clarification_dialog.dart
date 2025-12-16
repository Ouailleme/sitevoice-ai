import 'package:flutter/material.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/tts_service.dart';

/// Dialog de clarification conversationnelle
/// S'affiche quand l'IA a besoin de clarification (requires_clarification = true)
class ConversationalClarificationDialog extends StatefulWidget {
  final List<String> clarificationReasons;
  final Function(Map<String, String> answers) onAnswersSubmitted;

  const ConversationalClarificationDialog({
    super.key,
    required this.clarificationReasons,
    required this.onAnswersSubmitted,
  });

  @override
  State<ConversationalClarificationDialog> createState() =>
      _ConversationalClarificationDialogState();
}

class _ConversationalClarificationDialogState
    extends State<ConversationalClarificationDialog> {
  late TtsService _ttsService;
  late AudioService _audioService;

  int _currentQuestionIndex = 0;
  final Map<String, String> _answers = {};
  bool _isListeningForAnswer = false;

  @override
  void initState() {
    super.initState();
    _ttsService = TtsService();
    _audioService = AudioService();
    _initialize();
  }

  Future<void> _initialize() async {
    await _ttsService.initialize();
    _askCurrentQuestion();
  }

  Future<void> _askCurrentQuestion() async {
    if (_currentQuestionIndex >= widget.clarificationReasons.length) {
      // Toutes les questions posées
      _finish();
      return;
    }

    final reason = widget.clarificationReasons[_currentQuestionIndex];
    final questions = _ttsService.generateQuestionsFromReasons([reason]);

    if (questions.isNotEmpty) {
      await _ttsService.askClarificationQuestion(questions[0]);
      
      // Attendre que la synthèse soit terminée
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {});
    }
  }

  Future<void> _recordAnswer() async {
    setState(() {
      _isListeningForAnswer = true;
    });

    try {
      // Enregistrer la réponse vocale (courte)
      await _audioService.startRecording();
      
      // Attendre 5 secondes max
      await Future.delayed(const Duration(seconds: 5));
      
      final audioPath = await _audioService.stopRecording();
      
      if (audioPath != null) {
        // TODO: Transcrire avec Whisper et extraire la réponse
        // Pour l'instant on permet la saisie manuelle
        _showManualInputDialog();
      }
    } catch (e) {
      // Fallback: saisie manuelle
      _showManualInputDialog();
    } finally {
      setState(() {
        _isListeningForAnswer = false;
      });
    }
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réponse'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Saisir votre réponse...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitAnswer(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _submitAnswer(String answer) {
    if (answer.trim().isEmpty) return;

    final reason = widget.clarificationReasons[_currentQuestionIndex];
    _answers[reason] = answer;

    setState(() {
      _currentQuestionIndex++;
    });

    _askCurrentQuestion();
  }

  void _finish() {
    widget.onAnswersSubmitted(_answers);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= widget.clarificationReasons.length) {
      return const SizedBox.shrink();
    }

    final currentReason = widget.clarificationReasons[_currentQuestionIndex];
    final questions = _ttsService.generateQuestionsFromReasons([currentReason]);
    final currentQuestion = questions.isNotEmpty ? questions[0] : currentReason;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône assistant vocal
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeConstants.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                _ttsService.isSpeaking ? Icons.record_voice_over : Icons.question_answer,
                size: 40,
                color: ThemeConstants.primaryColor,
              ),
            ),

            const SizedBox(height: 24),

            // Question
            Text(
              'Question ${_currentQuestionIndex + 1}/${widget.clarificationReasons.length}',
              style: ThemeConstants.bodyTextSecondary,
            ),

            const SizedBox(height: 8),

            Text(
              currentQuestion,
              style: ThemeConstants.heading3,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton vocal
                ElevatedButton.icon(
                  onPressed: _isListeningForAnswer ? null : _recordAnswer,
                  icon: Icon(
                    _isListeningForAnswer ? Icons.mic : Icons.mic_none,
                  ),
                  label: Text(_isListeningForAnswer ? 'Écoute...' : 'Répondre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primaryColor,
                  ),
                ),

                // Bouton saisie manuelle
                OutlinedButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Saisir'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bouton passer
            TextButton(
              onPressed: () {
                _submitAnswer(''); // Réponse vide = skip
              },
              child: const Text('Passer cette question'),
            ),

            const SizedBox(height: 8),

            // Progression
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.clarificationReasons.length,
              backgroundColor: ThemeConstants.borderColor,
              valueColor: AlwaysStoppedAnimation(ThemeConstants.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}


