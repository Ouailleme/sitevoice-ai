import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'data/services/auth_service.dart';
import 'data/services/audio_service.dart';
import 'data/services/sync_service.dart';
import 'data/services/telemetry_service.dart';
import 'data/services/affiliate_service.dart';
import 'core/services/billing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de l'orientation (Portrait uniquement)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialisation de Hive (Local Storage)
  await Hive.initFlutter();

  // Initialisation de Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialisation du service de Telemetry (Sentry)
  await TelemetryService.initialize();
  
  // Initialisation de l'AffiliateService (Deep Links)
  final affiliateService = AffiliateService();
  await affiliateService.initialize();
  
  // V2.3 : Billing Service (Stripe Web-Only, pas de RevenueCat)
  final billingService = BillingService(affiliateService: affiliateService);

  runApp(SiteVoiceApp(
    affiliateService: affiliateService,
    billingService: billingService,
  ));
}

class SiteVoiceApp extends StatelessWidget {
  final AffiliateService affiliateService;
  final BillingService billingService;
  
  const SiteVoiceApp({
    super.key,
    required this.affiliateService,
    required this.billingService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services (Singleton)
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<AudioService>(
          create: (_) => AudioService(),
        ),
        Provider<SyncService>(
          create: (context) => SyncService(
            authService: context.read<AuthService>(),
          ),
        ),
        // V2.1 - Growth Services
        Provider<AffiliateService>.value(
          value: affiliateService,
        ),
        Provider<BillingService>.value(
          value: billingService,
        ),
        
        // ViewModels seront ajoutés au fur et à mesure
      ],
      child: MaterialApp.router(
        title: 'SiteVoice AI',
        debugShowCheckedModeBanner: false,
        
        // Thème Material 3
        theme: AppTheme.lightTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
        ),
        
        // Router
        routerConfig: AppRouter.router,
      ),
    );
  }
}


