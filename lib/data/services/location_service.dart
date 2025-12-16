import 'package:geolocator/geolocator.dart';

import '../../core/errors/app_exception.dart';
import 'telemetry_service.dart';

/// Coordonnées GPS
class GpsCoordinates {
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final double? accuracy; // En mètres

  GpsCoordinates({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.accuracy,
  });

  @override
  String toString() => 'GPS($latitude, $longitude) ±${accuracy ?? '?'}m';
}

/// Service de géolocalisation
class LocationService {
  // =====================================================
  // PERMISSIONS
  // =====================================================

  /// Vérifier si la permission de localisation est accordée
  Future<bool> checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur vérification permission GPS', e, stackTrace);
      return false;
    }
  }

  /// Demander la permission de localisation
  Future<bool> requestLocationPermission() async {
    try {
      TelemetryService.logInfo('Demande de permission GPS');

      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        TelemetryService.logInfo('Permission GPS accordée');
        return true;
      } else if (permission == LocationPermission.denied) {
        TelemetryService.logWarning('Permission GPS refusée');
        throw PermissionException(
          message: 'La permission GPS est nécessaire pour prouver la présence',
        );
      } else if (permission == LocationPermission.deniedForever) {
        TelemetryService.logWarning('Permission GPS définitivement refusée');
        throw PermissionException(
          message: 'Veuillez activer la permission GPS dans les paramètres',
        );
      }

      return false;
    } catch (e, stackTrace) {
      if (e is PermissionException) rethrow;

      TelemetryService.logError('Erreur demande permission GPS', e, stackTrace);
      throw PermissionException(
        message: 'Impossible de demander la permission GPS',
        originalError: e,
      );
    }
  }

  // =====================================================
  // CAPTURE GPS
  // =====================================================

  /// Capturer les coordonnées GPS actuelles
  Future<GpsCoordinates> captureCurrentLocation() async {
    try {
      // Vérifier que le service de localisation est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw PermissionException(
          message: 'Le service de localisation est désactivé',
        );
      }

      // Vérifier les permissions
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) {
          throw PermissionException(
            message: 'Permission GPS non accordée',
          );
        }
      }

      TelemetryService.logInfo('Capture GPS en cours...');

      // Capturer la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final coordinates = GpsCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        capturedAt: DateTime.now(),
        accuracy: position.accuracy,
      );

      TelemetryService.logInfo('GPS capturé: $coordinates');

      return coordinates;
    } on PermissionException {
      rethrow;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur capture GPS', e, stackTrace);

      throw NetworkException(
        message: 'Impossible de capturer la position GPS',
        originalError: e,
      );
    }
  }

  /// Capturer la position avec un timeout court (pour ne pas bloquer l'UX)
  Future<GpsCoordinates?> captureCurrentLocationQuick() async {
    try {
      return await captureCurrentLocation().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          TelemetryService.logWarning('Timeout capture GPS');
          throw NetworkException(message: 'Timeout GPS');
        },
      );
    } catch (e) {
      TelemetryService.logWarning('GPS non disponible: $e');
      return null; // Ne pas bloquer si GPS indisponible
    }
  }

  // =====================================================
  // CALCUL DE DISTANCE
  // =====================================================

  /// Calculer la distance (en mètres) entre deux coordonnées
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Vérifier si la position est proche d'une adresse cible
  /// Retourne true si distance < maxDistanceMeters
  bool isNearLocation({
    required GpsCoordinates current,
    required double targetLat,
    required double targetLon,
    double maxDistanceMeters = 100, // 100m par défaut
  }) {
    final distance = calculateDistance(
      lat1: current.latitude,
      lon1: current.longitude,
      lat2: targetLat,
      lon2: targetLon,
    );

    TelemetryService.logInfo('Distance: ${distance.toStringAsFixed(2)}m');

    return distance <= maxDistanceMeters;
  }
}


