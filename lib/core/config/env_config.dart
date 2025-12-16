/// Configuration des variables d'environnement
/// 
/// Pour utiliser ces variables, lancer l'app avec :
/// flutter run --dart-define=OPENAI_API_KEY=sk-proj-...
/// 
/// Ou créer un fichier .env (voir .env.example)
class EnvConfig {
  // OpenAI
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String whisperModel = String.fromEnvironment(
    'WHISPER_MODEL',
    defaultValue: 'whisper-1',
  );

  static const String gptModel = String.fromEnvironment(
    'GPT_MODEL',
    defaultValue: 'gpt-4',
  );

  static const int gptMaxTokens = int.fromEnvironment(
    'GPT_MAX_TOKENS',
    defaultValue: 2000,
  );

  // Note: double.fromEnvironment n'existe pas, utiliser String et parser
  static const String _gptTemperatureStr = String.fromEnvironment(
    'GPT_TEMPERATURE',
    defaultValue: '0.3',
  );
  
  static double get gptTemperature => double.tryParse(_gptTemperatureStr) ?? 0.3;

  // Supabase (peut être optionnel si déjà configuré dans Supabase.initialize)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // App
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';

  // Validation
  static bool get isOpenAiConfigured => openAiApiKey.isNotEmpty;
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Vérifier que toutes les variables critiques sont configurées
  static void validate() {
    final errors = <String>[];

    if (openAiApiKey.isEmpty) {
      errors.add('OPENAI_API_KEY manquante');
    }

    if (errors.isNotEmpty) {
      throw Exception(
        'Variables d\'environnement manquantes:\n${errors.join('\n')}',
      );
    }
  }

  /// Afficher la config (masquer les clés sensibles)
  static void printConfig() {
    print('🔧 Configuration Environnement:');
    print('  - APP_ENV: $appEnv');
    print('  - OPENAI_API_KEY: ${_maskKey(openAiApiKey)}');
    print('  - WHISPER_MODEL: $whisperModel');
    print('  - GPT_MODEL: $gptModel');
    print('  - SUPABASE_URL: ${_maskUrl(supabaseUrl)}');
  }

  static String _maskKey(String key) {
    if (key.isEmpty) return '[NON CONFIGURÉ]';
    if (key.length < 10) return '***';
    return '${key.substring(0, 7)}...${key.substring(key.length - 4)}';
  }

  static String _maskUrl(String url) {
    if (url.isEmpty) return '[NON CONFIGURÉ]';
    return url.replaceAll(RegExp(r'https://(\w+)\.'), 'https://***.');
  }
}

