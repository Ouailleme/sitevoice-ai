import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/freemium_service.dart';
import '../../../data/services/referral_service.dart';
import '../../../data/services/payment_service.dart';

/// Ecran de Paywall Freemium
/// Affiche quand l'utilisateur a utilise ses 3 rapports gratuits
class PaywallScreen extends StatefulWidget {
  final VoidCallback? onUpgrade;

  const PaywallScreen({
    Key? key,
    this.onUpgrade,
  }) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late final FreemiumService _freemiumService;
  late final ReferralService _referralService;
  late final PaymentService _paymentService;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _freemiumService = context.read<FreemiumService>();
    _referralService = context.read<ReferralService>();
    _paymentService = context.read<PaymentService>();

    // Log l'affichage du paywall
    _freemiumService.logPaywallEvent(eventType: 'hit_limit');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.seedColor.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
            ),
            
            // Content
            CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Spacer(flex: 1),
                        
                        // Icon
                        _buildIcon()
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.elasticOut),
                        
                        const SizedBox(height: 32),
                        
                        // Title
                        _buildTitle()
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        // Subtitle
                        _buildSubtitle()
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 48),
                        
                        // Features
                        _buildFeaturesList()
                            .animate(delay: 400.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),
                        
                        const Spacer(flex: 2),
                        
                        // CTA Buttons
                        _buildCTAButtons()
                            .animate(delay: 600.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        // Referral Option
                        _buildReferralOption()
                            .animate(delay: 800.ms)
                            .fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.lock_outline,
        size: 60,
        color: AppTheme.warningColor,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Limite gratuite atteinte !',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Vous avez utilisé vos 3 rapports d\'essai.\nPassez Premium pour continuer à gagner du temps !',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            height: 1.5,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      _Feature(
        icon: Icons.all_inclusive,
        title: 'Rapports illimités',
        description: 'Autant que vous voulez',
      ),
      _Feature(
        icon: Icons.mic,
        title: 'Transcription IA',
        description: 'Whisper + GPT-4o Vision',
      ),
      _Feature(
        icon: Icons.receipt_long,
        title: 'Facturation automatique',
        description: 'Export PDF, Webhooks',
      ),
      _Feature(
        icon: Icons.cloud_sync,
        title: 'Sync temps réel',
        description: 'Sauvegarde automatique',
      ),
      _Feature(
        icon: Icons.support_agent,
        title: 'Support prioritaire',
        description: 'Réponse < 2h',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✨ Avec Premium',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => _buildFeatureItem(feature)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(_Feature feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              feature.icon,
              size: 20,
              color: context.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  feature.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButtons() {
    return Column(
      children: [
        // Primary CTA
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _handleUpgrade,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.rocket_launch),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Text(
                    'Passer Premium',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '29€/mois - Sans engagement',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary CTA
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              _freemiumService.onPaywallDismissed();
              Navigator.of(context).pop();
            },
            child: const Text('Plus tard'),
          ),
        ),
      ],
    );
  }

  Widget _buildReferralOption() {
    return Card(
      color: AppTheme.seedColor.withOpacity(0.05),
      child: InkWell(
        onTap: _handleReferFriend,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.seedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppTheme.seedColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎁 Pas encore prêt ?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parrainez un collègue → 1 mois gratuit pour vous deux !',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    setState(() => _isLoading = true);

    try {
      await _freemiumService.onUpgradeClicked();
      
      // TODO: Integrer Stripe Payment
      // Pour l'instant, on simule
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirection vers le paiement...'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onUpgrade?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleReferFriend() async {
    await _freemiumService.onReferFriendClicked();
    await _referralService.shareReferralCode();
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;

  _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
}




