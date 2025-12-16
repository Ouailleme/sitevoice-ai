import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;

/// Service de gestion de la localisation
/// Dates, Monnaies, Détection langue
class LocalizationService {
  // Locale courante
  Locale? _currentLocale;

  // Locales supportées
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // Anglais (défaut)
    Locale('fr', 'FR'), // Français
    Locale('es', 'ES'), // Espagnol
  ];

  // Codes langues supportés (pour l'IA)
  static const List<String> supportedLanguageCodes = ['en', 'fr', 'es'];

  // =====================================================
  // DÉTECTION AUTOMATIQUE
  // =====================================================

  /// Détecte la langue du système
  Locale detectSystemLocale() {
    try {
      // Récupérer la locale du système
      final String systemLocale = Platform.localeName; // Format: "en_US" ou "fr_FR"
      
      // Parser
      final parts = systemLocale.split('_');
      final languageCode = parts[0]; // 'en', 'fr', etc.
      final countryCode = parts.length > 1 ? parts[1] : null;

      // Vérifier si supporté
      final locale = Locale(languageCode, countryCode);
      if (_isLocaleSupported(locale)) {
        _currentLocale = locale;
        return locale;
      }

      // Fallback : chercher juste par code langue
      for (final supported in supportedLocales) {
        if (supported.languageCode == languageCode) {
          _currentLocale = supported;
          return supported;
        }
      }

      // Fallback final : anglais
      _currentLocale = const Locale('en', 'US');
      return _currentLocale!;
    } catch (e) {
      // En cas d'erreur, retourner anglais
      _currentLocale = const Locale('en', 'US');
      return _currentLocale!;
    }
  }

  /// Vérifie si une locale est supportée
  bool _isLocaleSupported(Locale locale) {
    return supportedLocales.any((supported) =>
        supported.languageCode == locale.languageCode &&
        (supported.countryCode == locale.countryCode ||
            supported.countryCode == null));
  }

  /// Retourne la locale courante
  Locale get currentLocale => _currentLocale ?? detectSystemLocale();

  /// Retourne le code langue pour l'IA (ex: 'fr-FR', 'en-US')
  String get currentLocaleCode {
    final locale = currentLocale;
    return '${locale.languageCode}-${locale.countryCode}';
  }

  /// Change la langue
  void setLocale(Locale locale) {
    if (_isLocaleSupported(locale)) {
      _currentLocale = locale;
    }
  }

  // =====================================================
  // FORMAT DATES
  // =====================================================

  /// Formate une date selon la locale
  String formatDate(DateTime date, {String? pattern}) {
    final locale = currentLocale;
    final dateFormat = pattern != null
        ? DateFormat(pattern, locale.toString())
        : DateFormat.yMd(locale.toString());
    return dateFormat.format(date);
  }

  /// Formate une date complète (ex: "Lundi 14 décembre 2025")
  String formatFullDate(DateTime date) {
    final locale = currentLocale;
    return DateFormat.yMMMMEEEEd(locale.toString()).format(date);
  }

  /// Formate une date courte (ex: "14/12/2025")
  String formatShortDate(DateTime date) {
    final locale = currentLocale;
    return DateFormat.yMd(locale.toString()).format(date);
  }

  /// Formate une heure (ex: "14:30")
  String formatTime(DateTime time) {
    final locale = currentLocale;
    return DateFormat.Hm(locale.toString()).format(time);
  }

  /// Formate une date + heure
  String formatDateTime(DateTime dateTime) {
    final locale = currentLocale;
    return DateFormat.yMd(locale.toString()).add_Hm().format(dateTime);
  }

  /// Formate une durée relative (ex: "il y a 2 heures")
  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    final locale = currentLocale.languageCode;

    if (difference.inSeconds < 60) {
      return _translate(locale, 'just_now', 'just now', 'à l\'instant', 'ahora mismo');
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return _translate(
        locale,
        'minutes_ago',
        '$minutes minute${minutes > 1 ? 's' : ''} ago',
        'il y a $minutes minute${minutes > 1 ? 's' : ''}',
        'hace $minutes minuto${minutes > 1 ? 's' : ''}',
      );
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return _translate(
        locale,
        'hours_ago',
        '$hours hour${hours > 1 ? 's' : ''} ago',
        'il y a $hours heure${hours > 1 ? 's' : ''}',
        'hace $hours hora${hours > 1 ? 's' : ''}',
      );
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return _translate(
        locale,
        'days_ago',
        '$days day${days > 1 ? 's' : ''} ago',
        'il y a $days jour${days > 1 ? 's' : ''}',
        'hace $days día${days > 1 ? 's' : ''}',
      );
    } else {
      return formatShortDate(dateTime);
    }
  }

  // =====================================================
  // FORMAT MONNAIES
  // =====================================================

  /// Formate un montant selon la locale
  String formatCurrency(double amount, {String? currencySymbol}) {
    final locale = currentLocale;
    final symbol = currencySymbol ?? _getCurrencySymbol(locale.languageCode);

    final numberFormat = NumberFormat.currency(
      locale: locale.toString(),
      symbol: symbol,
      decimalDigits: 2,
    );

    return numberFormat.format(amount);
  }

  /// Retourne le symbole monétaire selon la langue
  String _getCurrencySymbol(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '\$';
      case 'fr':
      case 'es':
        return '€';
      default:
        return '\$';
    }
  }

  /// Formate un nombre avec séparateurs de milliers
  String formatNumber(num number) {
    final locale = currentLocale;
    final numberFormat = NumberFormat.decimalPattern(locale.toString());
    return numberFormat.format(number);
  }

  // =====================================================
  // HELPERS
  // =====================================================

  /// Helper pour traduire rapidement (fallback simple)
  String _translate(
    String locale,
    String key,
    String en,
    String fr,
    String es,
  ) {
    switch (locale) {
      case 'en':
        return en;
      case 'fr':
        return fr;
      case 'es':
        return es;
      default:
        return en;
    }
  }

  /// Retourne le nom de la langue dans sa propre langue
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      default:
        return languageCode.toUpperCase();
    }
  }

  /// Retourne le drapeau emoji pour une langue
  static String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      default:
        return '🌍';
    }
  }
}

/// Extension pour accès facile aux localisations
extension LocalizationExtension on BuildContext {
  /// Accès rapide aux traductions
  /// Usage: context.l10n.hello
  // AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Accès au service de localisation
  // LocalizationService get localization => Provider.of<LocalizationService>(this, listen: false);
}




