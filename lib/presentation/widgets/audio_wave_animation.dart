import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget d'animation d'onde audio
/// Affiche une visualisation animée basée sur l'amplitude du son
class AudioWaveAnimation extends StatelessWidget {
  final Stream<double>? amplitudeStream;
  final bool? isRecording;
  final Color color;
  final double height;
  final double width;

  const AudioWaveAnimation({
    super.key,
    this.amplitudeStream,
    this.isRecording,
    this.color = const Color(0xFF3B82F6),
    this.height = 100,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    // Si on a un stream d'amplitude, l'utiliser
    if (amplitudeStream != null) {
      return StreamBuilder<double>(
        stream: amplitudeStream,
        initialData: 0.0,
        builder: (context, snapshot) {
          final amplitude = snapshot.data ?? 0.0;
          return SizedBox(
            height: height,
            width: width,
            child: CustomPaint(
              painter: WavePainter(
                amplitude: amplitude,
                color: color,
              ),
            ),
          );
        },
      );
    }

    // Sinon, afficher une animation simple basée sur isRecording
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: height,
      width: width,
      child: (isRecording == true)
          ? _buildSimpleWaveAnimation()
          : _buildIdleState(),
    );
  }

  Widget _buildSimpleWaveAnimation() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          15,
          (index) => _AnimatedBar(
            index: index,
            color: color,
            height: height,
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          15,
          (index) => Container(
            width: 4,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre animée pour l'animation simple
class _AnimatedBar extends StatefulWidget {
  final int index;
  final Color color;
  final double height;

  const _AnimatedBar({
    required this.index,
    required this.color,
    required this.height,
  });

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 20, end: widget.height * 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: _animation.value,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}

/// Painter pour dessiner l'onde audio
class WavePainter extends CustomPainter {
  final double amplitude;
  final Color color;

  WavePainter({
    required this.amplitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final path = Path();

    // Dessiner plusieurs ondes pour un effet plus réaliste
    for (var waveIndex = 0; waveIndex < 3; waveIndex++) {
      path.reset();
      path.moveTo(0, centerY);

      for (var i = 0; i <= size.width; i++) {
        final x = i.toDouble();
        
        // Calculer y avec une sinusoïde
        final frequency = 0.02 + (waveIndex * 0.01);
        final phase = waveIndex * math.pi / 3;
        final waveAmplitude = amplitude * (30 - waveIndex * 5);
        
        final y = centerY +
            waveAmplitude *
                math.sin((x * frequency) + phase + DateTime.now().millisecondsSinceEpoch / 1000);

        path.lineTo(x, y);
      }

      // Transparence décroissante pour chaque onde
      paint.color = color.withOpacity(0.8 - (waveIndex * 0.2));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude;
  }
}

/// Widget de bars d'amplitude verticales
class AudioBarsAnimation extends StatelessWidget {
  final Stream<double> amplitudeStream;
  final Color color;
  final int numberOfBars;
  final double height;

  const AudioBarsAnimation({
    super.key,
    required this.amplitudeStream,
    this.color = const Color(0xFF3B82F6),
    this.numberOfBars = 30,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: amplitudeStream,
      initialData: 0.0,
      builder: (context, snapshot) {
        final amplitude = snapshot.data ?? 0.0;
        return SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              numberOfBars,
              (index) => _buildBar(index, amplitude),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBar(int index, double amplitude) {
    // Varier la hauteur de chaque barre en fonction de l'index et de l'amplitude
    final random = math.Random(index);
    final baseHeight = 20.0;
    final maxHeight = height;
    final barHeight = baseHeight +
        (maxHeight - baseHeight) *
            amplitude *
            (0.5 + random.nextDouble() * 0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 4,
      height: barHeight,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
