import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/config/env_config.dart';
import 'core/routes/app_router.dart';
import 'data/repositories/job_repository.dart';
import 'data/services/telemetry_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/audio_service.dart';
import 'data/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Afficher et valider la configuration
  EnvConfig.printConfig();
  
  try {
    EnvConfig.validate();
    TelemetryService.logInfo('✅ Configuration valide');
  } catch (e) {
    TelemetryService.logError('❌ Configuration invalide', e);
    // Continue quand même pour permettre le développement
  }

  // Initialiser Hive (offline-first)
  await JobRepository.initialize();

  // Initialiser Supabase
  await Supabase.initialize(
    url: 'https://dndjtcxypqnsyjzlzbxh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRuZGp0Y3h5cHFuc3lqemx6YnhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3MzcwNzUsImV4cCI6MjA4MTMxMzA3NX0.t_WPgNs15d5bBmfoAzNBnfFdQABgoDKL_oeNaVKe0N4',
  );

  runApp(
    MultiProvider(
      providers: [
        // Services (ordre important : AuthService d'abord car SyncService en dépend)
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<AudioService>(
          create: (_) => AudioService(),
        ),
        ProxyProvider<AuthService, SyncService>(
          update: (_, authService, __) => SyncService(authService: authService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SiteVoice AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
