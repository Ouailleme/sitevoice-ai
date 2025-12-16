import 'package:flutter/material.dart';
import '../../core/services/localization_service.dart';

/// Widget de sélection de langue
class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const LanguageSelector({
    Key? key,
    required this.currentLocale,
    required this.onLocaleChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language / Langue / Idioma',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...LocalizationService.supportedLocales.map((locale) {
              return _buildLanguageOption(
                context,
                locale,
                currentLocale.languageCode == locale.languageCode,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    Locale locale,
    bool isSelected,
  ) {
    final flag = LocalizationService.getLanguageFlag(locale.languageCode);
    final name = LocalizationService.getLanguageName(locale.languageCode);

    return InkWell(
      onTap: () => onLocaleChanged(locale),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialog de sélection de langue
class LanguageSelectorDialog extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const LanguageSelectorDialog({
    Key? key,
    required this.currentLocale,
    required this.onLocaleChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Language'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: LocalizationService.supportedLocales.map((locale) {
            return ListTile(
              leading: Text(
                LocalizationService.getLanguageFlag(locale.languageCode),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                LocalizationService.getLanguageName(locale.languageCode),
              ),
              trailing: currentLocale.languageCode == locale.languageCode
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                onLocaleChanged(locale);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  /// Show the language selector dialog
  static Future<void> show(
    BuildContext context, {
    required Locale currentLocale,
    required ValueChanged<Locale> onLocaleChanged,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => LanguageSelectorDialog(
        currentLocale: currentLocale,
        onLocaleChanged: onLocaleChanged,
      ),
    );
  }
}




