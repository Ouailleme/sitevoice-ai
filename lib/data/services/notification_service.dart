import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'telemetry_service.dart';

/// Service de notifications locales
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // =====================================================
  // INITIALISATION
  // =====================================================

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      TelemetryService.logInfo('Initialisation NotificationService');

      // Configuration Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialiser
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Demander permissions
      await _requestPermissions();

      _isInitialized = true;
      TelemetryService.logInfo('NotificationService initialisé');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur init notifications', e, stackTrace);
    }
  }

  Future<void> _requestPermissions() async {
    // Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    // iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTap(NotificationResponse response) {
    TelemetryService.logInfo('Notification tappée: ${response.payload}');
    // TODO: Router vers l'écran approprié
  }

  // =====================================================
  // NOTIFICATIONS GEOFENCING
  // =====================================================

  /// Notification de sortie de zone (FEATURE PRINCIPALE V2.0)
  Future<void> showGeofenceExitNotification({
    required String clientName,
    VoidCallback? onTap,
  }) async {
    try {
      TelemetryService.logInfo('Notification sortie zone: $clientName');

      const androidDetails = AndroidNotificationDetails(
        'geofencing',
        'Détection Chantiers',
        channelDescription: 'Notifications de sortie de chantier',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1, // ID fixe pour remplacer les anciennes
        'Sortie de chantier détectée',
        'Vous avez quitté $clientName. Lancer l\'enregistrement ?',
        details,
        payload: 'geofence_exit:$clientName',
      );

      TelemetryService.logInfo('Notification affichée');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur notification', e, stackTrace);
    }
  }

  // =====================================================
  // NOTIFICATIONS GÉNÉRIQUES
  // =====================================================

  /// Notification générique
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'general',
        'Notifications générales',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur notification', e, stackTrace);
    }
  }

  /// Notification avec action
  Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required List<String> actions,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'interactive',
        'Notifications interactives',
        importance: Importance.high,
        priority: Priority.high,
        actions: actions
            .map((action) => AndroidNotificationAction(action, action))
            .toList(),
      );

      const iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details);
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur notification actions', e, stackTrace);
    }
  }

  /// Annuler une notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Annuler toutes les notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}


