import 'dart:async';
import 'package:background_location/background_location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/client_model.dart';
import 'notification_service.dart';
import 'telemetry_service.dart';

/// Zone géographique surveillée
class GeofenceZone {
  final String id;
  final String clientId;
  final String clientName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime? lastVisit;

  GeofenceZone({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100, // 100m par défaut
    this.lastVisit,
  });

  factory GeofenceZone.fromClient(ClientModel client) {
    // Supposons que les clients ont des coordonnées GPS
    // À adapter selon votre modèle
    return GeofenceZone(
      id: 'zone_${client.id}',
      clientId: client.id,
      clientName: client.name,
      latitude: 0.0, // TODO: Ajouter lat/long dans ClientModel
      longitude: 0.0,
      radiusMeters: 100,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'last_visit': lastVisit?.toIso8601String(),
      };

  factory GeofenceZone.fromJson(Map<String, dynamic> json) => GeofenceZone(
        id: json['id'],
        clientId: json['client_id'],
        clientName: json['client_name'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        radiusMeters: json['radius_meters'] ?? 100,
        lastVisit: json['last_visit'] != null
            ? DateTime.parse(json['last_visit'])
            : null,
      );
}

/// Service de geofencing proactif
class GeofencingService {
  final NotificationService _notificationService;
  
  late Box<dynamic> _zonesBox;
  bool _isMonitoring = false;
  GeofenceZone? _currentZone;
  StreamSubscription<Location>? _locationSubscription;

  GeofencingService({required NotificationService notificationService})
      : _notificationService = notificationService;

  // =====================================================
  // INITIALISATION
  // =====================================================

  /// Initialiser le service
  Future<void> initialize() async {
    try {
      TelemetryService.logInfo('Initialisation GeofencingService');

      // Ouvrir la box Hive pour les zones
      _zonesBox = await Hive.openBox('geofence_zones');

      // Configurer les permissions
      await _requestPermissions();

      TelemetryService.logInfo('GeofencingService initialisé');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur init Geofencing', e, stackTrace);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Demander permission location
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      // Demander permission always (pour background)
      if (permission != LocationPermission.always) {
        TelemetryService.logWarning(
          'Permission "Always" requise pour le geofencing',
        );
      }
    } catch (e) {
      TelemetryService.logError('Erreur permissions Geofencing', e);
    }
  }

  // =====================================================
  // GESTION DES ZONES
  // =====================================================

  /// Ajouter une zone de geofencing
  Future<void> addZone(GeofenceZone zone) async {
    try {
      await _zonesBox.put(zone.id, zone.toJson());
      TelemetryService.logInfo('Zone ajoutée: ${zone.clientName}');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur ajout zone', e, stackTrace);
    }
  }

  /// Supprimer une zone
  Future<void> removeZone(String zoneId) async {
    try {
      await _zonesBox.delete(zoneId);
      TelemetryService.logInfo('Zone supprimée: $zoneId');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur suppression zone', e, stackTrace);
    }
  }

  /// Lister toutes les zones
  List<GeofenceZone> getZones() {
    try {
      return _zonesBox.values
          .map((json) => GeofenceZone.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Synchroniser les zones avec les clients
  Future<void> syncZonesFromClients(List<ClientModel> clients) async {
    try {
      TelemetryService.logInfo('Synchronisation zones depuis clients');

      for (final client in clients) {
        // Vérifier si le client a des coordonnées GPS
        // TODO: Adapter selon votre modèle
        final zone = GeofenceZone.fromClient(client);
        
        if (zone.latitude != 0.0 && zone.longitude != 0.0) {
          await addZone(zone);
        }
      }

      TelemetryService.logInfo('${clients.length} zones synchronisées');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur sync zones', e, stackTrace);
    }
  }

  // =====================================================
  // MONITORING
  // =====================================================

  /// Démarrer le monitoring en background
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      TelemetryService.logInfo('Geofencing déjà actif');
      return;
    }

    try {
      TelemetryService.logInfo('Démarrage geofencing monitoring');

      // Configurer Background Location
      await BackgroundLocation.setAndroidNotification(
        title: 'SiteVoice AI',
        message: 'Détection automatique des sorties de chantier',
        icon: '@mipmap/ic_launcher',
      );

      await BackgroundLocation.setAndroidConfiguration(1000); // 1 seconde
      await BackgroundLocation.startLocationService(distanceFilter: 20); // 20 mètres

      // Écouter les changements de position
      _locationSubscription = BackgroundLocation.getLocationUpdates((location) {
        _onLocationUpdate(location);
      });

      _isMonitoring = true;
      TelemetryService.logInfo('Geofencing monitoring actif');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur démarrage monitoring', e, stackTrace);
      throw PermissionException(
        message: 'Impossible de démarrer le geofencing',
        originalError: e,
      );
    }
  }

  /// Arrêter le monitoring
  Future<void> stopMonitoring() async {
    try {
      TelemetryService.logInfo('Arrêt geofencing monitoring');

      await _locationSubscription?.cancel();
      await BackgroundLocation.stopLocationService();

      _isMonitoring = false;
      _currentZone = null;

      TelemetryService.logInfo('Geofencing monitoring arrêté');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur arrêt monitoring', e, stackTrace);
    }
  }

  /// Callback quand la position change
  void _onLocationUpdate(Location location) {
    try {
      final currentLat = location.latitude!;
      final currentLon = location.longitude!;

      // Vérifier dans quelle zone on se trouve
      final zones = getZones();
      GeofenceZone? foundZone;

      for (final zone in zones) {
        final distance = Geolocator.distanceBetween(
          currentLat,
          currentLon,
          zone.latitude,
          zone.longitude,
        );

        if (distance <= zone.radiusMeters) {
          foundZone = zone;
          break;
        }
      }

      // Détecter l'entrée ou la sortie de zone
      if (foundZone != null && _currentZone == null) {
        // ENTRÉE dans une zone
        _onZoneEnter(foundZone);
      } else if (foundZone == null && _currentZone != null) {
        // SORTIE d'une zone
        _onZoneExit(_currentZone!);
      }

      _currentZone = foundZone;
    } catch (e) {
      TelemetryService.logError('Erreur traitement position', e);
    }
  }

  /// Callback entrée dans une zone
  void _onZoneEnter(GeofenceZone zone) {
    TelemetryService.logInfo('Entrée zone: ${zone.clientName}');

    // Mettre à jour lastVisit
    final updatedZone = GeofenceZone(
      id: zone.id,
      clientId: zone.clientId,
      clientName: zone.clientName,
      latitude: zone.latitude,
      longitude: zone.longitude,
      radiusMeters: zone.radiusMeters,
      lastVisit: DateTime.now(),
    );
    addZone(updatedZone);
  }

  /// Callback sortie d'une zone
  void _onZoneExit(GeofenceZone zone) {
    TelemetryService.logInfo('Sortie zone: ${zone.clientName}');

    // NOTIFICATION PUSH PROACTIVE
    _notificationService.showGeofenceExitNotification(
      clientName: zone.clientName,
      onTap: () {
        // Ouvrir l'app sur l'écran d'enregistrement
        TelemetryService.logInfo('Notification geofencing tapée');
      },
    );
  }

  // =====================================================
  // UTILITAIRES
  // =====================================================

  /// Vérifier si on est dans une zone cliente
  Future<GeofenceZone?> getCurrentZone() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final zones = getZones();

      for (final zone in zones) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          zone.latitude,
          zone.longitude,
        );

        if (distance <= zone.radiusMeters) {
          return zone;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Dispose
  void dispose() {
    stopMonitoring();
  }
}


