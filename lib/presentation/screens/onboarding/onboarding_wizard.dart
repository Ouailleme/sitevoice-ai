import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/referral_service.dart';

/// Onboarding Wizard en 3 étapes
/// 1. Bienvenue + Nom
/// 2. Import contacts (optionnel)
/// 3. Code parrainage (optionnel)
class OnboardingWizard extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingWizard({
    Key? key,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  final _introKey = GlobalKey<IntroductionScreenState>();
  
  // Form data
  String? _userName;
  String? _referralCode;
  List<Contact>? _importedContacts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        key: _introKey,
        pages: [
          _buildWelcomePage(),
          _buildImportContactsPage(),
          _buildReferralCodePage(),
        ],
        onDone: _onOnboardingComplete,
        onSkip: _onOnboardingComplete,
        showSkipButton: true,
        skip: Text(AppLocalizations.of(context)!.skip, style: const TextStyle(fontWeight: FontWeight.w600)),
        next: const Icon(Icons.arrow_forward),
        done: Text(AppLocalizations.of(context)!.done, style: const TextStyle(fontWeight: FontWeight.w600)),
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(20.0, 10.0),
          activeColor: AppTheme.seedColor,
          color: Colors.grey.shade300,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // PAGE 1 : BIENVENUE
  // =====================================================

  PageViewModel _buildWelcomePage() {
    return PageViewModel(
      titleWidget: Text(
        AppLocalizations.of(context)!.welcome_title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      bodyWidget: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.engineering,
            size: 120,
            color: AppTheme.seedColor,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.welcome_subtitle,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildUserNameInput(),
        ],
      ),
      decoration: const PageDecoration(
        bodyPadding: EdgeInsets.all(24),
        imagePadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildUserNameInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.name_question,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.first_name_hint,
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                setState(() => _userName = value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.personalize_experience_hint,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PAGE 2 : IMPORT CONTACTS
  // =====================================================

  PageViewModel _buildImportContactsPage() {
    return PageViewModel(
      titleWidget: Text(
        AppLocalizations.of(context)!.import_contacts_title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      bodyWidget: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.contacts,
            size: 100,
            color: AppTheme.seedColor.withOpacity(0.8),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.import_contacts_subtitle,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.optional_later_hint,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildImportContactsButton(),
        ],
      ),
      decoration: const PageDecoration(
        bodyPadding: EdgeInsets.all(24),
        imagePadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildImportContactsButton() {
    return Card(
      child: InkWell(
        onTap: _handleImportContacts,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                  Icons.phone_android,
                  color: AppTheme.seedColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.import_my_contacts,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _importedContacts != null
                          ? '${_importedContacts!.length} ${AppLocalizations.of(context)!.contacts_imported}'
                          : AppLocalizations.of(context)!.from_your_phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: _importedContacts != null
                            ? context.successColor
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _importedContacts != null
                    ? Icons.check_circle
                    : Icons.arrow_forward_ios,
                size: 20,
                color: _importedContacts != null
                    ? context.successColor
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleImportContacts() async {
    try {
      // Demander permission
      if (await FlutterContacts.requestPermission()) {
        // Importer contacts
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
        );

        setState(() {
          _importedContacts = contacts.take(50).toList(); // Limiter a 50 max
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_importedContacts!.length} ${AppLocalizations.of(context)!.contacts_imported}'),
              backgroundColor: context.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.permission_denied),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =====================================================
  // PAGE 3 : CODE PARRAINAGE
  // =====================================================

  PageViewModel _buildReferralCodePage() {
    return PageViewModel(
      titleWidget: Text(
        AppLocalizations.of(context)!.referral_code_title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      bodyWidget: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.card_giftcard,
            size: 100,
            color: AppTheme.warningColor,
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.colleague_invited_question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.enter_referral_code_bonus,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildReferralCodeInput(),
        ],
      ),
      decoration: const PageDecoration(
        bodyPadding: EdgeInsets.all(24),
        imagePadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildReferralCodeInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.referral_code_optional,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.referral_code_example,
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                setState(() => _referralCode = value);
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: context.successColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.both_get_free_month,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // COMPLETION
  // =====================================================

  Future<void> _onOnboardingComplete() async {
    // Appliquer le code de parrainage si fourni
    if (_referralCode != null && _referralCode!.isNotEmpty) {
      final referralService = ReferralService(
        supabase: _supabase,
        telemetry: _telemetry,
      );
      
      final success = await referralService.applyReferralCode(_referralCode!);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.referral_code_applied),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    // TODO: Sauvegarder les contacts importés
    // TODO: Mettre à jour le profil utilisateur avec le nom

    // Marquer l'onboarding comme complete
    // TODO: Update user.onboarding_completed = true

    widget.onCompleted();
  }
}

