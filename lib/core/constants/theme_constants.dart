import 'package:flutter/material.dart';

/// Constantes de thème et couleurs
class ThemeConstants {
  ThemeConstants._();

  // =====================================================
  // COULEURS PRINCIPALES
  // =====================================================
  
  /// Couleur primaire - Bleu industriel
  static const Color primaryColor = Color(0xFF2563EB); // Blue-600
  
  /// Couleur primaire claire
  static const Color primaryLightColor = Color(0xFF3B82F6); // Blue-500
  
  /// Couleur primaire foncée
  static const Color primaryDarkColor = Color(0xFF1E40AF); // Blue-700

  /// Couleur secondaire - Orange construction
  static const Color secondaryColor = Color(0xFFEA580C); // Orange-600
  
  /// Couleur d'accent
  static const Color accentColor = Color(0xFF10B981); // Green-500

  // =====================================================
  // COULEURS DE STATUS
  // =====================================================
  
  /// Success
  static const Color successColor = Color(0xFF10B981); // Green-500
  
  /// Warning
  static const Color warningColor = Color(0xFFF59E0B); // Amber-500
  
  /// Error
  static const Color errorColor = Color(0xFFEF4444); // Red-500
  
  /// Info
  static const Color infoColor = Color(0xFF3B82F6); // Blue-500

  // =====================================================
  // COULEURS NEUTRES
  // =====================================================
  
  /// Arrière-plan principal
  static const Color backgroundColor = Color(0xFFF9FAFB); // Gray-50
  
  /// Arrière-plan des cartes
  static const Color cardBackgroundColor = Color(0xFFFFFFFF);
  
  /// Texte principal
  static const Color textPrimaryColor = Color(0xFF111827); // Gray-900
  
  /// Texte secondaire
  static const Color textSecondaryColor = Color(0xFF6B7280); // Gray-500
  
  /// Texte désactivé
  static const Color textDisabledColor = Color(0xFF9CA3AF); // Gray-400
  
  /// Bordures
  static const Color borderColor = Color(0xFFE5E7EB); // Gray-200
  
  /// Dividers
  static const Color dividerColor = Color(0xFFE5E7EB); // Gray-200

  // =====================================================
  // COULEURS SPÉCIFIQUES AU MÉTIER
  // =====================================================
  
  /// Couleur du bouton d'enregistrement (rouge vif)
  static const Color recordButtonColor = Color(0xFFDC2626); // Red-600
  
  /// Couleur du bouton en cours d'enregistrement (rouge pulsant)
  static const Color recordingActiveColor = Color(0xFFEF4444); // Red-500
  
  /// Couleur pour les icônes d'outils
  static const Color toolIconColor = Color(0xFF6B7280); // Gray-500

  // =====================================================
  // COLOR SCHEME
  // =====================================================
  
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: Colors.white,
    secondary: secondaryColor,
    onSecondary: Colors.white,
    error: errorColor,
    onError: Colors.white,
    surface: cardBackgroundColor,
    onSurface: textPrimaryColor,
    background: backgroundColor,
    onBackground: textPrimaryColor,
  );

  // =====================================================
  // OMBRES
  // =====================================================
  
  /// Ombre légère (pour les cartes)
  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  /// Ombre moyenne (pour les boutons flottants)
  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  /// Ombre forte (pour les modals)
  static List<BoxShadow> get strongShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ];

  // =====================================================
  // TEXT STYLES
  // =====================================================
  
  /// Titre principal (H1)
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    height: 1.2,
  );

  /// Titre secondaire (H2)
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    height: 1.3,
  );

  /// Titre tertiaire (H3)
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    height: 1.4,
  );

  /// Texte du corps
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
    height: 1.5,
  );

  /// Texte secondaire
  static const TextStyle bodyTextSecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
    height: 1.5,
  );

  /// Légende
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
    height: 1.4,
  );

  /// Bouton principal
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}


