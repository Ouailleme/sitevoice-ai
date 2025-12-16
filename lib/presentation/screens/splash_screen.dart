import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/routes/app_router.dart';
import '../../core/constants/theme_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Attendre 2 secondes pour l'animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Vérifier si l'utilisateur est connecté
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

    if (isAuthenticated) {
      context.go(AppRouter.home);
    } else {
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: ThemeConstants.strongShadow,
              ),
              child: const Icon(
                Icons.mic,
                size: 64,
                color: ThemeConstants.primaryColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Titre
            const Text(
              'SiteVoice AI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Sous-titre
            const Text(
              'Arrêtez de taper. Parlez.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}


