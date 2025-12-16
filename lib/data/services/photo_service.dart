import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_exception.dart';
import 'telemetry_service.dart';

/// Service de gestion des photos
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  // =====================================================
  // CAPTURE PHOTO
  // =====================================================

  /// Prendre une photo avec la caméra
  Future<File?> capturePhoto() async {
    try {
      TelemetryService.logInfo('Ouverture caméra');

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compression qualité
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo == null) {
        TelemetryService.logInfo('Capture photo annulée');
        return null;
      }

      final file = File(photo.path);
      final fileSize = await file.length();
      
      TelemetryService.logInfo(
        'Photo capturée: ${photo.path} (${fileSize ~/ 1024} KB)',
      );

      // Compresser si > 2MB
      if (fileSize > 2 * 1024 * 1024) {
        return await _compressImage(file);
      }

      return file;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur capture photo', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible de prendre une photo',
        originalError: e,
      );
    }
  }

  /// Sélectionner une photo depuis la galerie
  Future<File?> pickFromGallery() async {
    try {
      TelemetryService.logInfo('Ouverture galerie');

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo == null) {
        TelemetryService.logInfo('Sélection photo annulée');
        return null;
      }

      final file = File(photo.path);
      final fileSize = await file.length();
      
      TelemetryService.logInfo(
        'Photo sélectionnée: ${photo.path} (${fileSize ~/ 1024} KB)',
      );

      // Compresser si > 2MB
      if (fileSize > 2 * 1024 * 1024) {
        return await _compressImage(file);
      }

      return file;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur sélection photo', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible de sélectionner une photo',
        originalError: e,
      );
    }
  }

  /// Sélectionner plusieurs photos
  Future<List<File>> pickMultipleFromGallery({int maxImages = 5}) async {
    try {
      TelemetryService.logInfo('Ouverture galerie (multiple)');

      final List<XFile> photos = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photos.isEmpty) {
        TelemetryService.logInfo('Aucune photo sélectionnée');
        return [];
      }

      // Limiter le nombre
      final limitedPhotos = photos.take(maxImages).toList();

      final files = <File>[];
      for (final photo in limitedPhotos) {
        final file = File(photo.path);
        final fileSize = await file.length();

        // Compresser si nécessaire
        if (fileSize > 2 * 1024 * 1024) {
          final compressed = await _compressImage(file);
          if (compressed != null) {
            files.add(compressed);
          }
        } else {
          files.add(file);
        }
      }

      TelemetryService.logInfo('${files.length} photos sélectionnées');

      return files;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur sélection photos', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible de sélectionner les photos',
        originalError: e,
      );
    }
  }

  // =====================================================
  // COMPRESSION
  // =====================================================

  /// Compresser une image
  Future<File?> _compressImage(File file) async {
    try {
      TelemetryService.logInfo('Compression image...');

      // Lire l'image
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        TelemetryService.logWarning('Image non décodable');
        return file;
      }

      // Redimensionner si trop grande
      if (image.width > 1920 || image.height > 1920) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1920 : null,
        );
      }

      // Compresser en JPEG qualité 80
      final compressedBytes = img.encodeJpg(image, quality: 80);

      // Sauvegarder
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFile = File('${directory.path}/compressed_$timestamp.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      final originalSize = await file.length();
      final compressedSize = compressedBytes.length;
      final ratio = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

      TelemetryService.logInfo(
        'Image compressée: ${originalSize ~/ 1024}KB -> ${compressedSize ~/ 1024}KB (-$ratio%)',
      );

      return compressedFile;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur compression image', e, stackTrace);
      return file; // Retourner l'original en cas d'erreur
    }
  }

  // =====================================================
  // UTILITAIRES
  // =====================================================

  /// Supprimer un fichier photo
  Future<void> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        TelemetryService.logInfo('Photo supprimée: $path');
      }
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur suppression photo', e, stackTrace);
    }
  }

  /// Obtenir la taille d'une photo
  Future<int> getPhotoSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}


