/// Exception de base pour l'application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Erreur réseau
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Erreur d'authentification
class AppAuthException extends AppException {
  AppAuthException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Erreur de validation
class ValidationException extends AppException {
  ValidationException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Erreur serveur
class ServerException extends AppException {
  ServerException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Erreur de stockage local
class AppStorageException extends AppException {
  AppStorageException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Erreur de permission
class PermissionException extends AppException {
  PermissionException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Erreur audio
class AudioException extends AppException {
  AudioException({
    required super.message,
    super.code,
    super.originalError,
  });
}


