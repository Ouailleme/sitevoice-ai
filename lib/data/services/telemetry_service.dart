import 'package:logger/logger.dart';

/// Service de télémétrie pour le logging et le tracking des erreurs
class TelemetryService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  TelemetryService._();

  static Future<void> initialize() async {
    // TODO: Initialiser Sentry quand prêt
    // await SentryFlutter.init(
    //   (options) {
    //     options.dsn = 'your-sentry-dsn';
    //     options.environment = 'production';
    //   },
    // );
    
    _logger.i('TelemetryService initialized');
  }

  static void logInfo(String message, [dynamic data]) {
    _logger.i(message, error: data);
  }

  static void logWarning(String message, [dynamic data]) {
    _logger.w(message, error: data);
  }

  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    
    // TODO: Envoyer à Sentry
    // if (error != null) {
    //   Sentry.captureException(error, stackTrace: stackTrace);
    // }
  }

  static void logDebug(String message, [dynamic data]) {
    _logger.d(message, error: data);
  }
}


