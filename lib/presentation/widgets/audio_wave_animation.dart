import 'dart:math';
import 'package:flutter/material.dart';

/// Widget d'animation d'onde sonore pendant l'enregistrement
class AudioWaveAnimation extends StatefulWidget {
  final bool isRecording;
  final Color color;
  final double height;

  const AudioWaveAnimation({
    super.key,
    required this.isRecording,
    this.color = Colors.red,
    this.height = 80,
  });

  @override
  State<AudioWaveAnimation> createState() => _AudioWaveAnimationState();
}

class _AudioWaveAnimationState extends State<AudioWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _AudioWavePainter(
              animation: _controller.value,
              color: widget.color,
            ),
            size: Size(double.infinity, widget.height),
          );
        },
      ),
    );
  }
}

class _AudioWavePainter extends CustomPainter {
  final double animation;
  final Color color;

  _AudioWavePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final waveHeight = size.height;
    final waveLength = size.width;

    // Paramètres de l'onde
    final numberOfWaves = 3;
    final amplitude = waveHeight * 0.3;
    final frequency = 2 * pi / waveLength * numberOfWaves;
    final phase = animation * 2 * pi;

    // Dessiner plusieurs ondes décalées
    for (int i = 0; i < 3; i++) {
      final opacity = 1.0 - (i * 0.3);
      paint.color = color.withOpacity(opacity * 0.6);

      path.reset();
      path.moveTo(0, waveHeight / 2);

      for (double x = 0; x <= waveLength; x += 2) {
        final y = waveHeight / 2 +
            amplitude * sin(frequency * x + phase + (i * pi / 3));
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }

    // Dessiner des barres verticales aléatoires (simulant l'amplitude)
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 4;

    final random = Random(animation.hashCode);
    final barCount = 30;
    final barSpacing = waveLength / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barSpacing + barSpacing / 2;
      final barHeight = (random.nextDouble() * 0.5 + 0.5) *
          amplitude *
          (1 + 0.3 * sin(animation * 2 * pi + i));

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, waveHeight / 2),
          width: 3,
          height: barHeight * 2,
        ),
        const Radius.circular(2),
      );

      paint.color = color.withOpacity(0.4);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AudioWavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}


