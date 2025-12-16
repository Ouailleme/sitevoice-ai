import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import 'auth_service.dart';
import 'telemetry_service.dart';

/// Résultat d'import
class ImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });

  bool get hasErrors => errorCount > 0;
  String get summary => '$successCount réussis, $errorCount erreurs';
}

/// Service d'import de données (CSV, etc.)
class ImportService {
  final AuthService _authService;
  final SupabaseClient _supabase = Supabase.instance.client;

  ImportService({required AuthService authService})
      : _authService = authService;

  // =====================================================
  // IMPORT CLIENTS
  // =====================================================

  /// Importer des clients depuis un fichier CSV
  /// Format attendu : name,address,postal_code,city,phone,email
  Future<ImportResult> importClientsFromCsv() async {
    try {
      TelemetryService.logInfo('Sélection fichier CSV clients');

      // Sélectionner le fichier
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        throw ValidationException(message: 'Aucun fichier sélectionné');
      }

      final file = File(result.files.first.path!);
      final csvString = await file.readAsString();

      // Parser le CSV
      final rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) {
        throw ValidationException(message: 'Le fichier CSV est vide');
      }

      // Récupérer l'ID de l'entreprise
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      final companyId = userProfile!.companyId!;
      final userId = _authService.currentUser!.id;

      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      // Ignorer la première ligne si c'est un header
      final startIndex = _isHeader(rows[0]) ? 1 : 0;

      for (int i = startIndex; i < rows.length; i++) {
        try {
          final row = rows[i];

          if (row.length < 2) {
            errorCount++;
            errors.add('Ligne $i: format invalide');
            continue;
          }

          final client = {
            'company_id': companyId,
            'name': row[0].toString().trim(),
            'address': row.length > 1 ? row[1].toString().trim() : null,
            'postal_code': row.length > 2 ? row[2].toString().trim() : null,
            'city': row.length > 3 ? row[3].toString().trim() : null,
            'phone': row.length > 4 ? row[4].toString().trim() : null,
            'email': row.length > 5 ? row[5].toString().trim() : null,
            'created_by': userId,
          };

          await _supabase.from('clients').insert(client);
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('Ligne $i: ${e.toString()}');
        }
      }

      TelemetryService.logInfo(
        'Import clients terminé: $successCount réussis, $errorCount erreurs',
      );

      return ImportResult(
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;

      TelemetryService.logError('Erreur import clients', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible d\'importer les clients',
        originalError: e,
      );
    }
  }

  // =====================================================
  // IMPORT PRODUITS
  // =====================================================

  /// Importer des produits depuis un fichier CSV
  /// Format attendu : reference,name,description,unit_price,unit,category
  Future<ImportResult> importProductsFromCsv() async {
    try {
      TelemetryService.logInfo('Sélection fichier CSV produits');

      // Sélectionner le fichier
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        throw ValidationException(message: 'Aucun fichier sélectionné');
      }

      final file = File(result.files.first.path!);
      final csvString = await file.readAsString();

      // Parser le CSV
      final rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) {
        throw ValidationException(message: 'Le fichier CSV est vide');
      }

      // Récupérer l'ID de l'entreprise
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile?.companyId == null) {
        throw AppAuthException(message: 'Entreprise non définie');
      }

      final companyId = userProfile!.companyId!;

      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      // Ignorer la première ligne si c'est un header
      final startIndex = _isHeader(rows[0]) ? 1 : 0;

      for (int i = startIndex; i < rows.length; i++) {
        try {
          final row = rows[i];

          if (row.length < 4) {
            errorCount++;
            errors.add('Ligne $i: format invalide');
            continue;
          }

          final product = {
            'company_id': companyId,
            'reference': row[0].toString().trim(),
            'name': row[1].toString().trim(),
            'description': row.length > 2 ? row[2].toString().trim() : null,
            'unit_price': double.parse(row[3].toString()),
            'unit': row.length > 4 ? row[4].toString().trim() : 'unité',
            'category': row.length > 5 ? row[5].toString().trim() : null,
          };

          await _supabase.from('products').insert(product);
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('Ligne $i: ${e.toString()}');
        }
      }

      TelemetryService.logInfo(
        'Import produits terminé: $successCount réussis, $errorCount erreurs',
      );

      return ImportResult(
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e, stackTrace) {
      if (e is AppException) rethrow;

      TelemetryService.logError('Erreur import produits', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible d\'importer les produits',
        originalError: e,
      );
    }
  }

  // =====================================================
  // HELPERS
  // =====================================================

  bool _isHeader(List<dynamic> row) {
    // Vérifier si la première ligne contient des en-têtes typiques
    final firstCell = row[0].toString().toLowerCase();
    return firstCell.contains('name') ||
        firstCell.contains('nom') ||
        firstCell.contains('reference') ||
        firstCell.contains('ref');
  }

  // =====================================================
  // TEMPLATES CSV
  // =====================================================

  /// Générer un template CSV pour les clients
  String generateClientsTemplate() {
    return 'name,address,postal_code,city,phone,email\n'
        'Dupont SA,12 rue de la Paix,75001,Paris,0123456789,contact@dupont.fr\n'
        'Martin SARL,45 avenue Victor Hugo,69002,Lyon,0987654321,info@martin.fr';
  }

  /// Générer un template CSV pour les produits
  String generateProductsTemplate() {
    return 'reference,name,description,unit_price,unit,category\n'
        'CHF-100,Chauffe-eau 100L,Chauffe-eau électrique,450.00,unité,Matériel\n'
        'RAD-50,Radiateur 50cm,Radiateur blanc,85.00,unité,Matériel\n'
        'MO-H,Main d\'oeuvre,Heure de travail,45.00,heure,Main d\'oeuvre';
  }
}


