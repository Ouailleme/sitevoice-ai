import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';

/// Service pour gérer l'upload de fichiers vers Supabase Storage
class StorageService {
  final _supabase = Supabase.instance.client;

  /// Upload un fichier audio vers Supabase Storage
  /// 
  /// [filePath] : Chemin local du fichier audio
  /// 
  /// Retourne le chemin du fichier dans le storage (format: company_id/timestamp.m4a)
  Future<String> uploadAudio(String filePath) async {
    try {
      // Vérifier que l'utilisateur est connecté
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AppAuthException(
          message: 'Utilisateur non connecté',
          code: 'USER_NOT_AUTHENTICATED',
        );
      }

      // Récupérer le company_id de l'utilisateur
      final userResponse = await _supabase
          .from('users')
          .select('company_id')
          .eq('id', userId)
          .single();

      final companyId = userResponse['company_id'];
      if (companyId == null) {
        throw ServerException(
          message: 'Company ID non trouvé',
          code: 'COMPANY_ID_NOT_FOUND',
        );
      }

      // Lire le fichier
      final file = File(filePath);
      if (!await file.exists()) {
        throw AppStorageException(
          message: 'Fichier audio introuvable',
          code: 'FILE_NOT_FOUND',
        );
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw AppStorageException(
          message: 'Fichier audio vide',
          code: 'EMPTY_FILE',
        );
      }

      // Créer un nom unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.m4a';
      final storagePath = '$companyId/$fileName';

      // Upload
      await _supabase.storage.from('audio-recordings').uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'audio/m4a',
              upsert: false,
            ),
          );

      return storagePath;
    } on StorageException catch (e) {
      throw ServerException(
        message: 'Erreur Supabase Storage: ${e.message}',
        code: 'STORAGE_ERROR',
      );
    } catch (e) {
      throw ServerException(
        message: 'Erreur upload audio: $e',
        code: 'UPLOAD_ERROR',
      );
    }
  }

  /// Obtenir une URL signée pour accéder à un fichier audio
  /// 
  /// [path] : Chemin du fichier dans le storage
  /// [expiresIn] : Durée de validité de l'URL en secondes (par défaut 1h)
  /// 
  /// Retourne l'URL signée valide pour la durée spécifiée
  Future<String> getSignedUrl(String path, {int expiresIn = 3600}) async {
    try {
      final url = await _supabase.storage
          .from('audio-recordings')
          .createSignedUrl(path, expiresIn);

      return url;
    } on StorageException catch (e) {
      throw ServerException(
        message: 'Erreur génération URL: ${e.message}',
        code: 'URL_GENERATION_ERROR',
      );
    }
  }

  /// Obtenir l'URL publique d'un fichier (si le bucket est public)
  /// 
  /// [path] : Chemin du fichier dans le storage
  /// 
  /// Retourne l'URL publique du fichier
  String getPublicUrl(String path) {
    return _supabase.storage.from('audio-recordings').getPublicUrl(path);
  }

  /// Supprimer un fichier audio du storage
  /// 
  /// [path] : Chemin du fichier dans le storage
  Future<void> deleteAudio(String path) async {
    try {
      await _supabase.storage.from('audio-recordings').remove([path]);
    } on StorageException catch (e) {
      throw ServerException(
        message: 'Erreur suppression fichier: ${e.message}',
        code: 'DELETE_ERROR',
      );
    }
  }

  /// Lister tous les fichiers audio d'une company
  /// 
  /// [companyId] : ID de l'entreprise
  /// 
  /// Retourne la liste des fichiers audio
  Future<List<FileObject>> listCompanyAudios(String companyId) async {
    try {
      final files = await _supabase.storage
          .from('audio-recordings')
          .list(path: companyId);

      return files;
    } on StorageException catch (e) {
      throw ServerException(
        message: 'Erreur liste fichiers: ${e.message}',
        code: 'LIST_ERROR',
      );
    }
  }
}

