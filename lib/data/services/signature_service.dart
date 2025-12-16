import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../../core/errors/app_exception.dart';
import 'telemetry_service.dart';

/// Service de gestion de signature
class SignatureService {
  // =====================================================
  // CRÉATION CONTRÔLEUR
  // =====================================================

  /// Créer un contrôleur de signature
  SignatureController createController({
    Color penColor = Colors.black,
    double penStrokeWidth = 3.0,
  }) {
    return SignatureController(
      penColor: penColor,
      penStrokeWidth: penStrokeWidth,
      exportBackgroundColor: Colors.white,
    );
  }

  // =====================================================
  // EXPORT & SAUVEGARDE
  // =====================================================

  /// Exporter la signature en PNG
  Future<File?> exportSignatureToPng(SignatureController controller) async {
    try {
      if (controller.isEmpty) {
        throw ValidationException(message: 'La signature est vide');
      }

      TelemetryService.logInfo('Export signature en PNG');

      // Obtenir l'image depuis le controller
      final ui.Image? image = await controller.toImage();
      
      if (image == null) {
        throw AppStorageException(message: 'Impossible de générer l\'image');
      }

      // Convertir en bytes PNG
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw AppStorageException(message: 'Impossible de convertir l\'image');
      }

      final bytes = byteData.buffer.asUint8List();

      // Sauvegarder dans un fichier temporaire
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/signature_$timestamp.png');
      await file.writeAsBytes(bytes);

      final fileSize = bytes.length;
      TelemetryService.logInfo(
        'Signature exportée: ${file.path} (${fileSize ~/ 1024} KB)',
      );

      return file;
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      
      TelemetryService.logError('Erreur export signature', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible d\'exporter la signature',
        originalError: e,
      );
    }
  }

  /// Exporter la signature en SVG
  Future<File?> exportSignatureToSvg(SignatureController controller) async {
    try {
      if (controller.isEmpty) {
        throw ValidationException(message: 'La signature est vide');
      }

      TelemetryService.logInfo('Export signature en SVG');

      // Obtenir les points de la signature
      final svg = controller.toSVG();
      
      if (svg == null) {
        throw AppStorageException(message: 'Impossible de générer le SVG');
      }

      // Sauvegarder dans un fichier temporaire
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/signature_$timestamp.svg');
      await file.writeAsString(svg);

      TelemetryService.logInfo('Signature SVG exportée: ${file.path}');

      return file;
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;
      
      TelemetryService.logError('Erreur export signature SVG', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible d\'exporter la signature en SVG',
        originalError: e,
      );
    }
  }

  // =====================================================
  // VALIDATION
  // =====================================================

  /// Valider qu'une signature est suffisamment fournie
  bool validateSignature(SignatureController controller) {
    if (controller.isEmpty) {
      return false;
    }

    // Vérifier qu'il y a au moins quelques points
    final points = controller.points;
    return points.length > 10; // Minimum 10 points
  }

  // =====================================================
  // UTILITAIRES
  // =====================================================

  /// Supprimer un fichier de signature
  Future<void> deleteSignature(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        TelemetryService.logInfo('Signature supprimée: $path');
      }
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur suppression signature', e, stackTrace);
    }
  }
}


