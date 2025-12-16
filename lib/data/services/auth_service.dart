import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart' hide AuthException;
import '../models/user_model.dart';
import 'telemetry_service.dart';

/// Service d'authentification utilisant Supabase Auth
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère l'utilisateur actuellement connecté
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream des changements d'état d'authentification
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Vérifie si un utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  // =====================================================
  // INSCRIPTION
  // =====================================================

  /// Inscription avec email et mot de passe
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String companyName,
  }) async {
    try {
      TelemetryService.logInfo('Tentative d\'inscription: $email');

      // Créer le compte utilisateur
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw AppAuthException(
          message: 'Erreur lors de la création du compte',
        );
      }

      final userId = authResponse.user!.id;

      // Créer l'entreprise
      final companyResponse = await _supabase
          .from('companies')
          .insert({
            'name': companyName,
            'subscription_status': 'trial',
          })
          .select()
          .single();

      final companyId = companyResponse['id'];

      // Créer le profil utilisateur
      final userProfile = await _supabase
          .from('users')
          .insert({
            'id': userId,
            'email': email,
            'full_name': fullName,
            'role': 'admin', // Premier utilisateur = admin
            'company_id': companyId,
          })
          .select()
          .single();

      TelemetryService.logInfo('Inscription réussie: $email');

      return UserModel.fromJson(userProfile);
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur inscription', e, stackTrace);
      throw AppAuthException(
        message: 'Impossible de créer le compte: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // =====================================================
  // CONNEXION
  // =====================================================

  /// Connexion avec email et mot de passe
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      TelemetryService.logInfo('Tentative de connexion: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AppAuthException(
          message: 'Identifiants incorrects',
        );
      }

      TelemetryService.logInfo('Authentification réussie, récupération du profil...');

      // Récupérer le profil utilisateur
      try {
        final userProfile = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        TelemetryService.logInfo('Connexion réussie: $email');
        return UserModel.fromJson(userProfile);
      } catch (profileError) {
        // Si le profil n'existe pas, créer un profil minimal
        TelemetryService.logError('Profil introuvable, création d\'un profil minimal', profileError);
        
        final now = DateTime.now();
        return UserModel(
          id: response.user!.id,
          email: email,
          fullName: response.user!.userMetadata?['full_name'] ?? email.split('@')[0],
          role: 'tech',
          companyId: null,
          createdAt: now,
          updatedAt: now,
        );
      }
    } on AuthException catch (e) {
      TelemetryService.logError('Erreur d\'authentification', e);
      throw AppAuthException(
        message: 'Email ou mot de passe incorrect',
        originalError: e,
      );
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur connexion', e, stackTrace);
      
      throw AppAuthException(
        message: 'Impossible de se connecter: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Connexion avec Google (OAuth)
  Future<void> signInWithGoogle() async {
    try {
      TelemetryService.logInfo('Tentative de connexion Google');

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'sitevoice://login-callback',
      );

      TelemetryService.logInfo('Connexion Google initiée');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur connexion Google', e, stackTrace);
      throw AppAuthException(
        message: 'Impossible de se connecter avec Google',
        originalError: e,
      );
    }
  }

  // =====================================================
  // RÉCUPÉRATION DE MOT DE PASSE
  // =====================================================

  /// Envoyer un email de réinitialisation de mot de passe
  Future<void> resetPassword(String email) async {
    try {
      TelemetryService.logInfo('Demande de réinitialisation: $email');

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'sitevoice://reset-password',
      );

      TelemetryService.logInfo('Email de réinitialisation envoyé: $email');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur réinitialisation', e, stackTrace);
      throw AppAuthException(
        message: 'Impossible d\'envoyer l\'email de réinitialisation',
        originalError: e,
      );
    }
  }

  /// Mettre à jour le mot de passe
  Future<void> updatePassword(String newPassword) async {
    try {
      TelemetryService.logInfo('Mise à jour du mot de passe');

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      TelemetryService.logInfo('Mot de passe mis à jour');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur mise à jour mot de passe', e, stackTrace);
      throw AppAuthException(
        message: 'Impossible de mettre à jour le mot de passe',
        originalError: e,
      );
    }
  }

  // =====================================================
  // PROFIL UTILISATEUR
  // =====================================================

  /// Récupérer le profil de l'utilisateur actuel
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) return null;

      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return UserModel.fromJson(userProfile);
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur récupération profil', e, stackTrace);
      return null;
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<UserModel> updateUserProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      if (!isAuthenticated) {
        throw AppAuthException(message: 'Utilisateur non authentifié');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) {
        throw ValidationException(message: 'Aucune donnée à mettre à jour');
      }

      updates['updated_at'] = DateTime.now().toIso8601String();

      final userProfile = await _supabase
          .from('users')
          .update(updates)
          .eq('id', currentUser!.id)
          .select()
          .single();

      TelemetryService.logInfo('Profil mis à jour');

      return UserModel.fromJson(userProfile);
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur mise à jour profil', e, stackTrace);
      throw AppAuthException(
        message: 'Impossible de mettre à jour le profil',
        originalError: e,
      );
    }
  }

  // =====================================================
  // DÉCONNEXION
  // =====================================================

  /// Déconnexion
  Future<void> signOut() async {
    try {
      TelemetryService.logInfo('Déconnexion');

      await _supabase.auth.signOut();

      TelemetryService.logInfo('Déconnexion réussie');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur déconnexion', e, stackTrace);
      throw AppAuthException(
        message: 'Impossible de se déconnecter',
        originalError: e,
      );
    }
  }

  // =====================================================
  // GESTION DE SESSION
  // =====================================================

  /// Rafraîchir la session
  Future<void> refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
      TelemetryService.logInfo('Session rafraîchie');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur rafraîchissement session', e, stackTrace);
    }
  }

  /// Vérifier si la session est valide
  Future<bool> isSessionValid() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;

      // Vérifier si le token n'est pas expiré
      final expiresAt = session.expiresAt;
      if (expiresAt == null) return false;

      return DateTime.now().isBefore(
        DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
      );
    } catch (e) {
      return false;
    }
  }
}


