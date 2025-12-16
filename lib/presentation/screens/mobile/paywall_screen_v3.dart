import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/billing_service.dart';
import '../../../data/services/telemetry_service.dart';

/// Paywall V3 - Web Payments Edition
/// 
/// V2.3 : Stratégie Web-Only (0% de frais Apple/Google)
/// - Bouton "Payer" → Ouvre Stripe Checkout (navigateur)
/// - Pas de RevenueCat, pas d'IAP natif
/// - Source of Truth : Supabase (subscription_status)
/// - Retour app : Rafraîchit le statut automatiquement
class PaywallScreenV3 extends StatefulWidget {
  final VoidCallback? onUpgradeSuccess;
  
  const PaywallScreenV3({
    super.key,
    this.onUpgradeSuccess,
  });

  @override
  State<PaywallScreenV3> createState() => _PaywallScreenV3State();
}

class _PaywallScreenV3State extends State<PaywallScreenV3> with WidgetsBindingObserver {
  final BillingService _billingService = BillingService();
  
  bool _isAnnualSelected = true; // Par défaut : Annuel (4 mois offerts)
  bool _isOpening = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TelemetryService.logInfo('Paywall V3 affiché');
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
    TelemetryService.logInfo('Vérification du statut d\'abonnement au retour');
    
    try {
      final status = await _billingService.refreshSubscriptionStatus();
      
      if (status != null && mounted) {
        final subscriptionStatus = status['subscription_status'] as String?;
        
        if (subscriptionStatus == 'active' || subscriptionStatus == 'trialing') {
          // L'utilisateur est devenu premium !
          TelemetryService.logInfo('Utilisateur devenu premium, fermeture du paywall');
          
          widget.onUpgradeSuccess?.call();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      TelemetryService.logError('Erreur vérification statut', e);
    }
  }
  
  Future<void> _handlePay() async {
    setState(() => _isOpening = true);
    
    try {
      TelemetryService.logInfo(
        'Ouverture Stripe Checkout: ${_isAnnualSelected ? "Annual" : "Monthly"}',
      );
      
      final success = _isAnnualSelected
          ? await _billingService.openAnnualCheckout()
          : await _billingService.openMonthlyCheckout();
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la page de paiement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      TelemetryService.logError('Erreur ouverture checkout', e);
      
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        size: 64,
                        color: Colors.amber,
                      ),
                    ).animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    const Text(
                      'Passez à Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ).animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    Text(
                      'Débloquez toute la puissance de l\'IA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ).animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),
                    
                    const Spacer(),
                    
                    // Plans sélection
                    _buildPlansSelection()
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    // Features
                    _buildFeatures()
                        .animate(delay: 600.ms)
                        .fadeIn(duration: 400.ms),
                    
                    const Spacer(),
                    
                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isOpening ? null : _handlePay,
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
                                'Continuer vers le paiement',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ).animate(delay: 800.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Info sécurité
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Paiement sécurisé par Stripe',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Annulation possible à tout moment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlansSelection() {
    return Column(
      children: [
        // Annual (RECOMMANDÉ)
        _buildPlanCard(
          isSelected: _isAnnualSelected,
          title: 'Annuel',
          price: '\$299',
          period: '/an',
          badge: '🏆 RECOMMANDÉ',
          discount: '4 MOIS OFFERTS',
          onTap: () => setState(() => _isAnnualSelected = true),
        ),
        
        const SizedBox(height: 12),
        
        // Monthly
        _buildPlanCard(
          isSelected: !_isAnnualSelected,
          title: 'Mensuel',
          price: '\$29',
          period: '/mois',
          onTap: () => setState(() => _isAnnualSelected = false),
        ),
      ],
    );
  }
  
  Widget _buildPlanCard({
    required bool isSelected,
    required String title,
    required String price,
    required String period,
    String? badge,
    String? discount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                color: isSelected ? Colors.amber : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (discount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      discount,
                      style: TextStyle(
                        color: isSelected ? Colors.green[700] : Colors.green[200],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black.withOpacity(0.6)
                        : Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatures() {
    return Column(
      children: [
        _buildFeature('✨', 'Rapports illimités'),
        _buildFeature('🤖', 'IA GPT-4o Vision'),
        _buildFeature('📊', 'Dashboard Analytics'),
        _buildFeature('🌍', 'Support multi-langues'),
        _buildFeature('🎁', 'Nouvelles features en priorité'),
      ],
    );
  }
  
  Widget _buildFeature(String emoji, String text) {
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
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



