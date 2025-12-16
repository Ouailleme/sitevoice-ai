import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../services/storage_service.dart';
import '../services/openai_service.dart';
import '../services/telemetry_service.dart';

/// Repository pour gérer les Jobs (offline-first)
/// 
/// - Stocke en local (Hive) d'abord
/// - Synchronise avec Supabase quand possible
/// - Gère la queue de synchronisation
class JobRepository {
  static const String _jobsBoxName = 'jobs';
  static const String _pendingSyncBoxName = 'pending_sync';
  
  final _supabase = Supabase.instance.client;
  final _storageService = StorageService();
  final _openAiService = OpenAIService();
  final _uuid = const Uuid();

  /// Initialiser Hive (à appeler au démarrage de l'app)
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_jobsBoxName);
    await Hive.openBox(_pendingSyncBoxName);
    TelemetryService.logInfo('JobRepository initialized');
  }

  Box get _jobsBox => Hive.box(_jobsBoxName);
  Box get _pendingSyncBox => Hive.box(_pendingSyncBoxName);

  /// Créer un nouveau job depuis un enregistrement audio
  /// 
  /// Flow complet : Audio → Upload → Transcription → Extraction → Sauvegarde locale
  Future<Map<String, dynamic>> createJobFromAudio({
    required String audioFilePath,
    List<String>? existingClients,
    List<String>? existingProducts,
  }) async {
    final jobId = _uuid.v4();
    
    try {
      TelemetryService.logInfo('Starting job creation from audio: $jobId');
      
      // 1. Upload audio vers Supabase Storage
      final audioStoragePath = await _storageService.uploadAudio(audioFilePath);
      TelemetryService.logInfo('Audio uploaded: $audioStoragePath');
      
      // 2. Transcription avec Whisper
      final transcription = await _openAiService.transcribeAudio(audioFilePath);
      TelemetryService.logInfo('Transcription: ${transcription.substring(0, 50)}...');
      
      // 3. Extraction de données avec GPT-4
      final extractedData = await _openAiService.extractJobData(
        transcription: transcription,
        existingClients: existingClients ?? [],
        existingProducts: existingProducts ?? [],
      );
      
      // 4. Créer le job
      final job = {
        'id': jobId,
        'client_name': extractedData['client'],
        'is_new_client': extractedData['client_nouveau'] ?? false,
        'address': extractedData['adresse_intervention'],
        'notes': extractedData['notes'],
        'audio_file_path': audioStoragePath,
        'transcription': transcription,
        'confidence_score': extractedData['confiance'],
        'products': extractedData['produits'],
        'status': 'draft',
        'is_synced': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // 5. Sauvegarder en local
      await _saveJobLocally(jobId, job);
      
      // 6. Ajouter à la queue de synchronisation
      await _addToPendingSync(jobId);
      
      TelemetryService.logInfo('Job created successfully: $jobId');
      
      return job;
    } catch (e, stack) {
      TelemetryService.logError('Error creating job from audio', e, stack);
      
      // Sauvegarder une version minimale en local même en cas d'erreur
      final fallbackJob = {
        'id': jobId,
        'audio_file_path': audioFilePath,
        'status': 'error',
        'error_message': e.toString(),
        'is_synced': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _saveJobLocally(jobId, fallbackJob);
      
      rethrow;
    }
  }

  /// Sauvegarder un job en local (Hive) - méthode privée
  Future<void> _saveJobLocally(String jobId, Map<String, dynamic> job) async {
    try {
      await _jobsBox.put(jobId, jsonEncode(job));
      TelemetryService.logInfo('Job saved locally: $jobId');
    } catch (e, stack) {
      TelemetryService.logError('Error saving job locally', e, stack);
      throw AppStorageException(
        message: 'Impossible de sauvegarder le job localement',
        code: 'LOCAL_SAVE_ERROR',
      );
    }
  }

  /// Sauvegarder un job en local (Hive) - méthode publique
  Future<void> saveJobLocally(String jobId, Map<String, dynamic> job) async {
    await _saveJobLocally(jobId, job);
  }

  /// Récupérer un job depuis le local
  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    try {
      final jobJson = _jobsBox.get(jobId) as String?;
      if (jobJson == null) return null;
      
      return jsonDecode(jobJson) as Map<String, dynamic>;
    } catch (e, stack) {
      TelemetryService.logError('Error getting job by ID', e, stack);
      return null;
    }
  }

  /// Lister tous les jobs locaux
  Future<List<Map<String, dynamic>>> getAllJobs() async {
    try {
      final jobs = <Map<String, dynamic>>[];
      
      for (var key in _jobsBox.keys) {
        final jobJson = _jobsBox.get(key) as String?;
        if (jobJson != null) {
          jobs.add(jsonDecode(jobJson) as Map<String, dynamic>);
        }
      }
      
      // Trier par date (plus récent d'abord)
      jobs.sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] as String);
        final dateB = DateTime.parse(b['created_at'] as String);
        return dateB.compareTo(dateA);
      });
      
      return jobs;
    } catch (e, stack) {
      TelemetryService.logError('Error getting all jobs', e, stack);
      return [];
    }
  }

  /// Lister les jobs non synchronisés
  Future<List<Map<String, dynamic>>> getPendingSyncJobs() async {
    try {
      final jobs = await getAllJobs();
      return jobs.where((job) => job['is_synced'] == false).toList();
    } catch (e, stack) {
      TelemetryService.logError('Error getting pending sync jobs', e, stack);
      return [];
    }
  }

  /// Ajouter un job à la queue de synchronisation
  Future<void> _addToPendingSync(String jobId) async {
    try {
      final pendingIds = List<String>.from(_pendingSyncBox.get('pending_ids', defaultValue: []));
      if (!pendingIds.contains(jobId)) {
        pendingIds.add(jobId);
        await _pendingSyncBox.put('pending_ids', pendingIds);
        TelemetryService.logInfo('Job added to sync queue: $jobId');
      }
    } catch (e, stack) {
      TelemetryService.logError('Error adding to pending sync', e, stack);
    }
  }

  /// Synchroniser un job avec Supabase
  Future<bool> syncJob(String jobId) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) {
        throw AppStorageException(
          message: 'Job introuvable',
          code: 'JOB_NOT_FOUND',
        );
      }
      
      if (job['is_synced'] == true) {
        TelemetryService.logInfo('Job already synced: $jobId');
        return true;
      }
      
      // Vérifier la connexion
      if (!await _hasInternetConnection()) {
        TelemetryService.logInfo('No internet connection, skipping sync');
        return false;
      }
      
      TelemetryService.logInfo('Syncing job to Supabase: $jobId');
      
      // 1. Créer le client si nouveau
      String? clientId;
      if (job['is_new_client'] == true) {
        final clientResponse = await _supabase.from('clients').insert({
          'name': job['client_name'],
          'address': job['address'],
        }).select().single();
        clientId = clientResponse['id'] as String;
      } else {
        // Trouver le client existant par nom
        final clientResponse = await _supabase
            .from('clients')
            .select('id')
            .eq('name', job['client_name'])
            .maybeSingle();
        clientId = clientResponse?['id'] as String?;
      }
      
      if (clientId == null) {
        throw ServerException(
          message: 'Client non trouvé ou non créé',
          code: 'CLIENT_ERROR',
        );
      }
      
      // 2. Créer le job dans Supabase
      await _supabase.from('jobs').insert({
        'id': jobId,
        'client_id': clientId,
        'address': job['address'],
        'notes': job['notes'],
        'audio_file_path': job['audio_file_path'],
        'transcription': job['transcription'],
        'confidence_score': job['confidence_score'],
        'status': job['status'],
        'created_at': job['created_at'],
      });
      
      // 3. Créer les lignes de produits
      final products = job['products'] as List?;
      if (products != null && products.isNotEmpty) {
        for (var product in products) {
          await _supabase.from('job_items').insert({
            'job_id': jobId,
            'product_name': product['nom'],
            'quantity': product['quantite'],
            'unit': product['unite'],
            'unit_price': product['prix_unitaire'],
          });
        }
      }
      
      // 4. Marquer comme synchronisé localement
      job['is_synced'] = true;
      job['synced_at'] = DateTime.now().toIso8601String();
      await _saveJobLocally(jobId, job);
      
      // 5. Retirer de la queue de synchronisation
      await _removeFromPendingSync(jobId);
      
      TelemetryService.logInfo('Job synced successfully: $jobId');
      return true;
    } catch (e, stack) {
      TelemetryService.logError('Error syncing job', e, stack);
      return false;
    }
  }

  /// Retirer un job de la queue de synchronisation
  Future<void> _removeFromPendingSync(String jobId) async {
    try {
      final pendingIds = List<String>.from(_pendingSyncBox.get('pending_ids', defaultValue: []));
      pendingIds.remove(jobId);
      await _pendingSyncBox.put('pending_ids', pendingIds);
      TelemetryService.logInfo('Job removed from sync queue: $jobId');
    } catch (e, stack) {
      TelemetryService.logError('Error removing from pending sync', e, stack);
    }
  }

  /// Synchroniser tous les jobs en attente
  Future<int> syncAllPendingJobs() async {
    try {
      final pendingIds = List<String>.from(_pendingSyncBox.get('pending_ids', defaultValue: []));
      
      if (pendingIds.isEmpty) {
        TelemetryService.logInfo('No pending jobs to sync');
        return 0;
      }
      
      TelemetryService.logInfo('Syncing ${pendingIds.length} pending jobs');
      
      int syncedCount = 0;
      for (var jobId in List.from(pendingIds)) {
        final success = await syncJob(jobId);
        if (success) syncedCount++;
      }
      
      TelemetryService.logInfo('Synced $syncedCount/${pendingIds.length} jobs');
      return syncedCount;
    } catch (e, stack) {
      TelemetryService.logError('Error syncing all pending jobs', e, stack);
      return 0;
    }
  }

  /// Vérifier la connexion internet
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Supprimer un job (local et Supabase si synchronisé)
  Future<void> deleteJob(String jobId) async {
    try {
      final job = await getJobById(jobId);
      
      // Supprimer de Supabase si synchronisé
      if (job?['is_synced'] == true) {
        await _supabase.from('jobs').delete().eq('id', jobId);
      }
      
      // Supprimer localement
      await _jobsBox.delete(jobId);
      
      // Retirer de la queue
      await _removeFromPendingSync(jobId);
      
      TelemetryService.logInfo('Job deleted: $jobId');
    } catch (e, stack) {
      TelemetryService.logError('Error deleting job', e, stack);
      throw AppStorageException(
        message: 'Impossible de supprimer le job',
        code: 'DELETE_ERROR',
      );
    }
  }

  /// Mettre à jour un job
  Future<void> updateJob(String jobId, Map<String, dynamic> updates) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) {
        throw AppStorageException(
          message: 'Job introuvable',
          code: 'JOB_NOT_FOUND',
        );
      }
      
      // Merger les updates
      job.addAll(updates);
      job['is_synced'] = false; // Marquer comme non synchronisé
      
      await _saveJobLocally(jobId, job);
      await _addToPendingSync(jobId);
      
      TelemetryService.logInfo('Job updated: $jobId');
    } catch (e, stack) {
      TelemetryService.logError('Error updating job', e, stack);
      rethrow;
    }
  }

  /// Obtenir le nombre de jobs en attente de synchronisation
  Future<int> getPendingSyncCount() async {
    final pendingIds = List<String>.from(_pendingSyncBox.get('pending_ids', defaultValue: []));
    return pendingIds.length;
  }
}

