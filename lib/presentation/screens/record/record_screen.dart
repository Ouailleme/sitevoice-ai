import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/sync_service.dart';
import '../../view_models/record_view_model.dart';
import '../../widgets/audio_wave_animation.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecordViewModel(
        audioService: context.read<AudioService>(),
        authService: context.read<AuthService>(),
        syncService: context.read<SyncService>(),
      ),
      child: const _RecordScreenContent(),
    );
  }
}

class _RecordScreenContent extends StatelessWidget {
  const _RecordScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Nouvel Enregistrement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<RecordViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorDialog(context, viewModel.errorMessage ?? 'Erreur');
            });
          }

          if (viewModel.isCompleted && viewModel.currentJobId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCompletionDialog(context, viewModel.currentJobId!);
            });
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Instructions
                  _buildInstructions(viewModel),
                  
                  const SizedBox(height: 40),
                  
                  // Timer
                  _buildTimer(viewModel),
                  
                  const SizedBox(height: 24),
                  
                  // Animation onde sonore
                  AudioWaveAnimation(
                    isRecording: viewModel.isRecording,
                    color: ThemeConstants.recordingActiveColor,
                    height: 80,
                  ),
                  
                  const Spacer(),
                  
                  // Bouton principal d'enregistrement
                  _buildRecordButton(context, viewModel),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons secondaires
                  _buildSecondaryButtons(context, viewModel),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructions(RecordViewModel viewModel) {
    String text;
    
    if (viewModel.isIdle) {
      text = 'Appuyez sur le micro pour démarrer votre rapport d\'intervention';
    } else if (viewModel.isRecording) {
      text = 'Décrivez votre intervention (client, produits utilisés, durée...)';
    } else if (viewModel.isPaused) {
      text = 'Enregistrement en pause';
    } else if (viewModel.isProcessing) {
      text = 'Traitement en cours...';
    } else {
      text = '';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeConstants.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConstants.infoColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: ThemeConstants.infoColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: ThemeConstants.bodyTextSecondary.copyWith(
                color: ThemeConstants.infoColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(RecordViewModel viewModel) {
    return Column(
      children: [
        Text(
          viewModel.formattedDuration,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: ThemeConstants.textPrimaryColor,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          viewModel.isRecording ? 'Enregistrement en cours...' : 
          viewModel.isPaused ? 'En pause' : '',
          style: ThemeConstants.bodyTextSecondary,
        ),
      ],
    );
  }

  Widget _buildRecordButton(BuildContext context, RecordViewModel viewModel) {
    final isActive = viewModel.isRecording;
    final isPaused = viewModel.isPaused;
    final isProcessing = viewModel.isProcessing;

    if (isProcessing) {
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ThemeConstants.primaryColor.withOpacity(0.1),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        if (viewModel.isIdle) {
          await viewModel.startRecording();
        } else if (isPaused) {
          await viewModel.resumeRecording();
        } else if (isActive) {
          await viewModel.pauseRecording();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? ThemeConstants.recordingActiveColor
              : ThemeConstants.recordButtonColor,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: ThemeConstants.recordingActiveColor.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ]
              : ThemeConstants.strongShadow,
        ),
        child: Icon(
          isPaused
              ? Icons.play_arrow
              : isActive
                  ? Icons.pause
                  : Icons.mic,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSecondaryButtons(BuildContext context, RecordViewModel viewModel) {
    if (viewModel.isIdle || viewModel.isProcessing) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton Annuler
        _buildSecondaryButton(
          icon: Icons.close,
          label: 'Annuler',
          color: ThemeConstants.errorColor,
          onTap: () async {
            final confirm = await _showConfirmDialog(
              context,
              'Annuler l\'enregistrement ?',
              'L\'enregistrement sera supprimé définitivement.',
            );
            
            if (confirm == true) {
              await viewModel.cancelRecording();
              if (context.mounted) {
                context.pop();
              }
            }
          },
        ),
        
        // Bouton Terminer
        _buildSecondaryButton(
          icon: Icons.check,
          label: 'Terminer',
          color: ThemeConstants.successColor,
          onTap: () async {
            await viewModel.stopAndSaveRecording();
          },
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<RecordViewModel>().resetForNewRecording();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, String jobId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: ThemeConstants.successColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text('Enregistré !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre rapport vocal a été enregistré avec succès.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeConstants.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    color: ThemeConstants.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Le rapport sera synchronisé et traité par l\'IA dès que possible.',
                      style: TextStyle(
                        color: ThemeConstants.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<RecordViewModel>().resetForNewRecording();
            },
            child: const Text('Nouvel enregistrement'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(AppRouter.home);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.successColor,
            ),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }
}

