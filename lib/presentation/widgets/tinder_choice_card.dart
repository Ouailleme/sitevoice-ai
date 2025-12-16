import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// Widget Tinder-style pour résoudre les conflits IA
/// Swipe ou Boutons pour choisir entre 2 options
class TinderChoiceCard extends StatefulWidget {
  final String title;
  final String option1Label;
  final String option2Label;
  final String? option1Subtitle;
  final String? option2Subtitle;
  final VoidCallback onOption1Selected;
  final VoidCallback onOption2Selected;
  final IconData? option1Icon;
  final IconData? option2Icon;

  const TinderChoiceCard({
    Key? key,
    required this.title,
    required this.option1Label,
    required this.option2Label,
    required this.onOption1Selected,
    required this.onOption2Selected,
    this.option1Subtitle,
    this.option2Subtitle,
    this.option1Icon,
    this.option2Icon,
  }) : super(key: key);

  @override
  State<TinderChoiceCard> createState() => _TinderChoiceCardState();
}

class _TinderChoiceCardState extends State<TinderChoiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        // Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _dragOffset += details.delta.dx;
                });
              },
              onPanEnd: (details) {
                if (_dragOffset > 100) {
                  _onOption1();
                } else if (_dragOffset < -100) {
                  _onOption2();
                } else {
                  setState(() {
                    _dragOffset = 0;
                  });
                }
              },
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Transform.rotate(
                  angle: _dragOffset / 1000,
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ),

        // Buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Option 1 Button
              _buildOptionButton(
                label: widget.option1Label,
                icon: widget.option1Icon ?? Icons.close,
                color: context.errorColor,
                onTap: _onOption1,
              ),

              // Option 2 Button
              _buildOptionButton(
                label: widget.option2Label,
                icon: widget.option2Icon ?? Icons.check,
                color: context.successColor,
                onTap: _onOption2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Option 1
            _buildOption(
              label: widget.option1Label,
              subtitle: widget.option1Subtitle,
              icon: widget.option1Icon ?? Icons.close,
              color: context.errorColor,
            ),

            const SizedBox(height: 48),

            // VS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OU',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Option 2
            _buildOption(
              label: widget.option2Label,
              subtitle: widget.option2Subtitle,
              icon: widget.option2Icon ?? Icons.check,
              color: context.successColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _onOption1() {
    setState(() {
      _dragOffset = -500;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onOption1Selected();
    });
  }

  void _onOption2() {
    setState(() {
      _dragOffset = 500;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onOption2Selected();
    });
  }
}




