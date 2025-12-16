import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/services/referral_service.dart';
import '../../data/services/telemetry_service.dart';

/// Bouton "Inviter" pour le système de parrainage
/// 
/// Règles V2.1 :
/// - Visible sur la Home ET dans l'écran de succès après un rapport
/// - Génère un code parrain unique (NOM-123)
/// - Partage via share_plus (SMS, WhatsApp, Email, etc.)
/// - Track les invitations envoyées
/// 
/// UI : Soit en Floating Action Button, soit en Card
class InviteButton extends StatelessWidget {
  final ReferralService referralService;
  final bool isFloating; // true = FAB, false = Card
  final VoidCallback? onInviteSent;
  
  const InviteButton({
    super.key,
    required this.referralService,
    this.isFloating = false,
    this.onInviteSent,
  });

  Future<void> _handleInvite(BuildContext context) async {
    try {
      TelemetryService.logInfo('Bouton Inviter cliqué');
      
      // Récupérer le code de parrainage de l'utilisateur
      final referralCode = await referralService.getCurrentUserReferralCode();
      
      if (referralCode == null) {
        _showError(context, 'Impossible de récupérer votre code de parrainage');
        return;
      }
      
      // Générer le message de partage
      final message = _generateInviteMessage(referralCode);
      
      // Partager via le système natif
      final result = await Share.share(
        message,
        subject: 'Rejoignez-moi sur SiteVoice AI',
      );
      
      // Track l'invitation
      if (result.status == ShareResultStatus.success) {
        TelemetryService.logInfo('Invitation partagée: Code=$referralCode');
        
        await referralService.trackInviteSent(referralCode);
        
        onInviteSent?.call();
        
        // V2.2 : Afficher un feedback visuel (confetti + toast)
        if (context.mounted) {
          _showSuccessConfetti(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.celebration, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🎉 Invitation envoyée ! Vous gagnerez 20€ si votre ami souscrit.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      TelemetryService.logError(
        'Erreur lors de l\'invitation',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (context.mounted) {
        _showError(context, 'Une erreur est survenue');
      }
    }
  }
  
  String _generateInviteMessage(String referralCode) {
    return '''
🚀 Hey ! Je t'invite à essayer SiteVoice AI

C'est l'assistant vocal IA pour les techniciens terrain.
Tu dictes ton intervention, l'IA fait tout le reste ! 🤖

✨ 3 rapports gratuits avec mon code : $referralCode

Télécharge l'app ici :
👉 https://app.sitevoice.ai/signup?ref=$referralCode

PS : Je gagne 20€ si tu souscris, et toi aussi 😉
''';
  }
  
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  /// Affiche une animation de confetti (V2.2)
  void _showSuccessConfetti(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ConfettiOverlay(),
    );
    
    overlay.insert(overlayEntry);
    
    // Retirer après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFloating) {
      return _buildFloatingButton(context);
    } else {
      return _buildCard(context);
    }
  }
  
  /// Version Floating Action Button
  Widget _buildFloatingButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _handleInvite(context),
      icon: const Icon(Icons.card_giftcard),
      label: const Text('Inviter'),
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
      elevation: 4,
    );
  }
  
  /// Version Card (pour afficher dans une liste)
  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E),
            Color(0xFF0D47A1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleInvite(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invitez un ami',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gagnez 20€ par parrainage réussi 🎁',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Variante compacte du bouton Inviter
/// Pour afficher dans la AppBar ou dans un menu
class InviteIconButton extends StatelessWidget {
  final ReferralService referralService;
  final VoidCallback? onInviteSent;
  
  const InviteIconButton({
    super.key,
    required this.referralService,
    this.onInviteSent,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.card_giftcard),
      tooltip: 'Inviter un ami',
      onPressed: () async {
        final inviteButton = InviteButton(
          referralService: referralService,
          onInviteSent: onInviteSent,
        );
        
        await inviteButton._handleInvite(context);
      },
    );
  }
}

/// Card pour afficher dans l'écran de succès après un rapport
class SuccessInviteCard extends StatelessWidget {
  final ReferralService referralService;
  
  const SuccessInviteCard({
    super.key,
    required this.referralService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.celebration,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rapport créé avec succès ! 🎉',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Gagnez 20€ en invitant un ami à essayer SiteVoice AI',
            style: TextStyle(
              color: Colors.orange[800],
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final inviteButton = InviteButton(
                  referralService: referralService,
                );
                inviteButton._handleInvite(context);
              },
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Inviter maintenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget d'animation de confetti (V2.2)
class _ConfettiOverlay extends StatefulWidget {
  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Créer 20 particules de confetti
    for (int i = 0; i < 20; i++) {
      _particles.add(_ConfettiParticle(
        emoji: ['🎉', '🎊', '✨', '⭐', '💫'][_random.nextInt(5)],
        startX: _random.nextDouble(),
        endX: _random.nextDouble(),
        rotation: _random.nextDouble() * 4 * pi,
      ));
    }
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: _particles.map((particle) {
              final progress = _controller.value;
              final x = size.width * (particle.startX + (particle.endX - particle.startX) * progress);
              final y = size.height * progress;
              
              return Positioned(
                left: x,
                top: y,
                child: Transform.rotate(
                  angle: particle.rotation * progress,
                  child: Opacity(
                    opacity: 1 - progress,
                    child: Text(
                      particle.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  final String emoji;
  final double startX;
  final double endX;
  final double rotation;
  
  _ConfettiParticle({
    required this.emoji,
    required this.startX,
    required this.endX,
    required this.rotation,
  });
}
