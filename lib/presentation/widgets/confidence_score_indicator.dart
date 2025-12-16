import 'package:flutter/material.dart';

enum ConfidenceScoreSize { small, medium, large }

/// Widget pour afficher le score de confiance de l'extraction IA
/// 
/// - Score > 80% : Vert (fiable)
/// - Score 50-80% : Orange (à vérifier)
/// - Score < 50% : Rouge (correction nécessaire)
class ConfidenceScoreIndicator extends StatelessWidget {
  final int score;
  final ConfidenceScoreSize size;
  final bool showLabel;

  const ConfidenceScoreIndicator({
    super.key,
    required this.score,
    this.size = ConfidenceScoreSize.medium,
    this.showLabel = true,
  });

  Color _getColor(BuildContext context) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  IconData _getIcon() {
    if (score >= 80) return Icons.check_circle;
    if (score >= 50) return Icons.warning;
    return Icons.error;
  }

  String _getMessage() {
    if (score >= 80) return 'Données fiables';
    if (score >= 50) return 'Vérifiez les données';
    return 'Correction nécessaire';
  }

  double _getIconSize() {
    switch (size) {
      case ConfidenceScoreSize.small:
        return 20;
      case ConfidenceScoreSize.medium:
        return 32;
      case ConfidenceScoreSize.large:
        return 48;
    }
  }

  double _getProgressSize() {
    switch (size) {
      case ConfidenceScoreSize.small:
        return 50;
      case ConfidenceScoreSize.medium:
        return 80;
      case ConfidenceScoreSize.large:
        return 120;
    }
  }

  TextStyle? _getTitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    switch (size) {
      case ConfidenceScoreSize.small:
        return theme.textTheme.bodySmall;
      case ConfidenceScoreSize.medium:
        return theme.textTheme.titleMedium;
      case ConfidenceScoreSize.large:
        return theme.textTheme.titleLarge;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(context);
    final progressSize = _getProgressSize();
    
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Indicateur circulaire
            SizedBox(
              width: progressSize,
              height: progressSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress circulaire
                  SizedBox(
                    width: progressSize,
                    height: progressSize,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: size == ConfidenceScoreSize.large ? 8 : 6,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  // Score au centre
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score%',
                        style: _getTitleStyle(context)?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (size == ConfidenceScoreSize.large)
                        Icon(
                          _getIcon(),
                          color: color,
                          size: 24,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Texte explicatif
            if (showLabel)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getIcon(), color: color, size: _getIconSize()),
                        const SizedBox(width: 8),
                        Text(
                          'Score de confiance IA',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMessage(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (size == ConfidenceScoreSize.large) ...[
                      const SizedBox(height: 8),
                      Text(
                        score >= 80
                            ? 'Les données extraites sont très fiables. Vérifiez quand même les montants.'
                            : score >= 50
                                ? 'Certaines informations peuvent être imprécises. Relisez attentivement.'
                                : 'L\'IA a eu du mal à extraire les données. Vérifiez tout avec attention.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

