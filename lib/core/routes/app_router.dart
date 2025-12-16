import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/main/main_navigation_screen.dart';
import '../../presentation/screens/record/record_screen.dart';
import '../../presentation/screens/jobs/job_validation_screen.dart';

/// Configuration du routing de l'application
class AppRouter {
  AppRouter._();

  // =====================================================
  // ROUTES NAMES
  // =====================================================
  
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String record = '/record';
  static const String jobValidation = '/job-validation';

  // =====================================================
  // ROUTER CONFIGURATION
  // =====================================================
  
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    
    // Redirect si non authentifié
    redirect: (context, state) {
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation == login || 
                         state.matchedLocation == signup ||
                         state.matchedLocation == splash;

      // Si non authentifié et pas sur une route d'auth, rediriger vers login
      if (!isAuthenticated && !isAuthRoute) {
        return login;
      }

      // Si authentifié et sur une route d'auth, rediriger vers home
      if (isAuthenticated && isAuthRoute && state.matchedLocation != splash) {
        return home;
      }

      return null; // Pas de redirection
    },
    
    routes: [
      // =====================================================
      // SPLASH SCREEN
      // =====================================================
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // =====================================================
      // AUTH ROUTES
      // =====================================================
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // =====================================================
      // MAIN APP ROUTES
      // =====================================================
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      // Route d'enregistrement vocal
      GoRoute(
        path: record,
        name: 'record',
        builder: (context, state) => const RecordScreen(),
      ),

      // Route de validation d'un job
      GoRoute(
        path: '$jobValidation/:jobId',
        name: 'jobValidation',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return JobValidationScreen(jobId: jobId);
        },
      ),
    ],

    // Page d'erreur
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}


