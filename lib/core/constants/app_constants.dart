/// Constantes globales de l'application
class AppConstants {
  AppConstants._(); // Private constructor pour empêcher l'instanciation

  // =====================================================
  // CONFIGURATION SUPABASE
  // =====================================================
  
  /// URL du projet Supabase
  /// TEMPORAIRE : Hardcodé pour debug
  static const String supabaseUrl = 'https://dndjtcxypqnsyjzlzbxh.supabase.co';

  /// Clé anonyme Supabase
  /// TEMPORAIRE : Hardcodé pour debug
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRuZGp0Y3h5cHFuc3lqemx6YnhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3MzcwNzUsImV4cCI6MjA4MTMxMzA3NX0.t_WPgNs15d5bBmfoAzNBnfFdQABgoDKL_oeNaVKe0N4';

  // =====================================================
  // CONFIGURATION OPENAI
  // =====================================================
  
  /// Clé API OpenAI (pour Whisper et GPT-4o)
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  /// URL de l'API OpenAI
  static const String openaiBaseUrl = 'https://api.openai.com/v1';

  /// Modèle Whisper pour la transcription
  static const String whisperModel = 'whisper-1';

  /// Modèle GPT pour l'extraction
  static const String gptModel = 'gpt-4o';

  // =====================================================
  // CONFIGURATION STRIPE
  // =====================================================
  
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_your-key',
  );

  // =====================================================
  // CONFIGURATION AUDIO
  // =====================================================
  
  /// Durée maximale d'enregistrement (en secondes) - HARD CAP critique
  static const int maxAudioDurationSeconds = 600; // 10 minutes MAX

  /// Taille maximale du fichier audio (en MB)
  static const int maxAudioFileSizeMB = 25;

  /// Format d'encodage audio
  static const String audioEncoder = 'aacLc'; // AAC Low Complexity

  /// Taux d'échantillonnage (optimisé pour Whisper)
  static const int audioSampleRate = 16000; // 16kHz suffisant pour la voix

  /// Bitrate audio (optimisé pour la voix)
  static const int audioBitRate = 64000; // 64 kbps

  // =====================================================
  // CONFIGURATION SYNC
  // =====================================================
  
  /// Intervalle de synchronisation en arrière-plan (en minutes)
  static const int syncIntervalMinutes = 5;

  /// Nombre de tentatives de retry pour les uploads
  static const int maxRetryAttempts = 3;

  /// Délai entre les tentatives (en secondes)
  static const int retryDelaySeconds = 5;

  // =====================================================
  // STORAGE KEYS
  // =====================================================
  
  static const String hiveBoxJobs = 'jobs_box';
  static const String hiveBoxClients = 'clients_box';
  static const String hiveBoxProducts = 'products_box';
  static const String hiveBoxSyncQueue = 'sync_queue_box';
  static const String hiveBoxSettings = 'settings_box';

  // =====================================================
  // SHARED PREFERENCES KEYS
  // =====================================================
  
  static const String prefKeyFirstLaunch = 'first_launch';
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyLastSync = 'last_sync';

  // =====================================================
  // API ENDPOINTS
  // =====================================================
  
  static const String edgeFunctionProcessAudio = '/functions/v1/process-audio';

  // =====================================================
  // BUSINESS LOGIC
  // =====================================================
  
  /// Seuil de confiance IA minimum pour validation automatique
  static const double aiConfidenceThreshold = 0.8;
  
  /// Seuil de matching exact pour éviter l'hallucination
  static const double aiExactMatchThreshold = 0.9; // 90% pour requires_clarification

  /// Prix de l'abonnement (en centimes)
  static const int subscriptionPriceInCents = 2900; // 29€

  // =====================================================
  // UI
  // =====================================================
  
  /// Durée des animations (en millisecondes)
  static const int animationDurationMs = 300;

  /// Rayon de bordure par défaut
  static const double defaultBorderRadius = 12.0;

  /// Padding par défaut
  static const double defaultPadding = 16.0;
}

