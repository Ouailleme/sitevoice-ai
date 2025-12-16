import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/billing_service.dart';
import '../../data/services/telemetry_service.dart';

/// One-Time Offer Modal V3 - Web Payments Edition
/// 
/// V2.3 : Stratégie Web-Only
/// - Bouton "Saisir l'offre" → Ouvre Stripe Checkout OTO
/// - Pas de RevenueCat, pas d'IAP natif
/// - Retour app : Rafraîchit automatiquement
class OneTimeOfferModalV3 extends StatefulWidget {
  final VoidCallback onOfferAccepted;
  final VoidCallback onOfferDeclined;
  
  const OneTimeOfferModalV3({
    super.key,
    required this.onOfferAccepted,
    required this.onOfferDeclined,
  });

  @override
  State<OneTimeOfferModalV3> createState() => _OneTimeOfferModalV3State();
}

class _OneTimeOfferModalV3State extends State<OneTimeOfferModalV3>
    with WidgetsBindingObserver {
  final BillingService _billingService = BillingService();
  bool _isOpening = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TelemetryService.logInfo('OTO V3 affiché');
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // V2.3 : Quand l'utilisateur revient dans l'app, vérifier son statut
    if (state == AppLifecycleState.resumed) {
      _checkSubscriptionStatus();
    }
  }
  
  Future<void> _checkSubscriptionStatus() async {
    TelemetryService.logInfo('Vérification du statut d\'abonnement au retour (OTO)');
    
    try {
      final status = await _billingService.refreshSubscriptionStatus();
      
      if (status != null && mounted) {
        final subscriptionStatus = status['subscription_status'] as String?;
        
        if (subscriptionStatus == 'active' || subscriptionStatus == 'trialing') {
          // L'utilisateur a accepté l'OTO !
          TelemetryService.logInfo('OTO acceptée, fermeture du modal');
          widget.onOfferAccepted();
        }
      }
    } catch (e) {
      TelemetryService.logError('Erreur vérification statut OTO', e);
    }
  }
  
  Future<void> _handleAcceptOffer() async {
    setState(() => _isOpening = true);
    
    try {
      TelemetryService.logInfo('Ouverture Stripe Checkout OTO (390$)');
      
      final success = await _billingService.openOTOCheckout();
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la page de paiement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      TelemetryService.logError('Erreur ouverture OTO checkout', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          widget.onOfferDeclined();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E),
                Color(0xFF0D47A1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flash_on,
                  size: 48,
                  color: Colors.white,
                ),
              ).animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 24),
              
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'OFFRE EXCLUSIVE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ).animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Économisez 45\$\nAUJOURD\'HUI !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 24),
              
              // Price
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$358',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 20,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '\$299',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '/an',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Offre valable uniquement maintenant',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ).animate(delay: 400.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 32),
              
              // Benefits
              _buildBenefit('✅', 'Rapports illimités à vie'),
              _buildBenefit('🚀', 'Accès à toutes les futures features'),
              _buildBenefit('💎', 'Support prioritaire VIP'),
              _buildBenefit('🎁', 'Économisez 45\$ vs prix normal'),
              
              const SizedBox(height: 32),
              
              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isOpening ? null : _handleAcceptOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                  child: _isOpening
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Text(
                          'Saisir l\'offre (299\$)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ).animate(delay: 600.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0)
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.3),
                  ),
              
              const SizedBox(height: 16),
              
              // Skip button
              TextButton(
                onPressed: widget.onOfferDeclined,
                child: Text(
                  'Non merci, je préfère payer plus cher',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ).animate(delay: 700.ms)
                  .fadeIn(duration: 400.ms),
              
              const SizedBox(height: 8),
              
              // Security
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Paiement sécurisé par Stripe',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBenefit(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



