import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import 'auth_service.dart';
import 'telemetry_service.dart';

/// Élément de la queue de synchronisation
class SyncQueueItem {
  final String id;
  final String entityType; // 'job', 'client', 'product'
  final String entityId;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic> payload;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;

  SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    this.retryCount = 0,
    this.lastError,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload': payload,
        'retry_count': retryCount,
        'last_error': lastError,
        'created_at': createdAt.toIso8601String(),
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'],
        entityType: json['entity_type'],
        entityId: json['entity_id'],
        operation: json['operation'],
        payload: Map<String, dynamic>.from(json['payload']),
        retryCount: json['retry_count'] ?? 0,
        lastError: json['last_error'],
        createdAt: DateTime.parse(json['created_at']),
      );
}

/// Service de synchronisation Offline-First
class SyncService {
  final AuthService authService;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity();

  late Box<dynamic> _syncQueueBox;
  StreamSubscription? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  bool _isSyncing = false;
  bool _isInitialized = false;

  /// Stream de l'état de la synchronisation
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Nombre d'éléments en attente de sync
  int get pendingItemsCount => _syncQueueBox.length;

  SyncService({required this.authService});

  // =====================================================
  // INITIALISATION
  // =====================================================

  /// Initialiser le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      TelemetryService.logInfo('Initialisation SyncService');

      // Ouvrir la box Hive pour la queue de sync
      _syncQueueBox = await Hive.openBox(AppConstants.hiveBoxSyncQueue);

      // Écouter les changements de connectivité
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (result) => _onConnectivityChanged(result),
      );

      // Démarrer la synchronisation périodique
      _startPeriodicSync();

      // Faire une première synchronisation si en ligne
      if (await isOnline()) {
        await syncAll();
      }

      _isInitialized = true;
      TelemetryService.logInfo('SyncService initialisé');
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur initialisation SyncService', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible d\'initialiser le service de synchronisation',
        originalError: e,
      );
    }
  }

  // =====================================================
  // CONNECTIVITÉ
  // =====================================================

  /// Vérifier si l'appareil est en ligne
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Vérifier avec un ping réel vers Supabase
      try {
        final result = await InternetAddress.lookup('supabase.co')
            .timeout(const Duration(seconds: 5));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Callback quand la connectivité change
  void _onConnectivityChanged(ConnectivityResult result) {
    if (result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi) {
      TelemetryService.logInfo('Connectivité restaurée, synchronisation...');
      syncAll();
    } else {
      TelemetryService.logInfo('Connectivité perdue, mode offline');
      _syncStatusController.add(SyncStatus.offline);
    }
  }

  // =====================================================
  // AJOUT À LA QUEUE
  // =====================================================

  /// Ajouter un élément à la queue de synchronisation
  Future<void> addToQueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Initialiser si pas encore fait (lazy initialization)
      if (!_isInitialized) {
        await initialize();
      }

      final queueItem = SyncQueueItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        createdAt: DateTime.now(),
      );

      await _syncQueueBox.put(queueItem.id, queueItem.toJson());

      TelemetryService.logInfo(
        'Ajouté à la queue: $entityType.$operation ($entityId)',
      );

      // Essayer de synchroniser immédiatement si en ligne
      if (await isOnline()) {
        await syncAll();
      }
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur ajout queue', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible d\'ajouter à la queue de synchronisation',
        originalError: e,
      );
    }
  }

  // =====================================================
  // SYNCHRONISATION
  // =====================================================

  /// Synchroniser tous les éléments en attente
  Future<void> syncAll() async {
    if (_isSyncing) {
      TelemetryService.logInfo('Synchronisation déjà en cours');
      return;
    }

    if (!authService.isAuthenticated) {
      TelemetryService.logWarning('Non authentifié, synchronisation impossible');
      return;
    }

    if (!await isOnline()) {
      TelemetryService.logInfo('Hors ligne, synchronisation reportée');
      _syncStatusController.add(SyncStatus.offline);
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      TelemetryService.logInfo('Démarrage synchronisation (${_syncQueueBox.length} éléments)');

      int successCount = 0;
      int errorCount = 0;

      // Récupérer tous les éléments de la queue
      final items = _syncQueueBox.values
          .map((json) => SyncQueueItem.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Trier par date de création (FIFO)
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final item in items) {
        try {
          await _syncItem(item);
          await _syncQueueBox.delete(item.id);
          successCount++;
        } catch (e) {
          errorCount++;
          
          // Incrémenter le retry count
          if (item.retryCount < AppConstants.maxRetryAttempts) {
            final updatedItem = SyncQueueItem(
              id: item.id,
              entityType: item.entityType,
              entityId: item.entityId,
              operation: item.operation,
              payload: item.payload,
              retryCount: item.retryCount + 1,
              lastError: e.toString(),
              createdAt: item.createdAt,
            );
            await _syncQueueBox.put(item.id, updatedItem.toJson());
          } else {
            // Max tentatives atteint, supprimer de la queue
            TelemetryService.logError(
              'Max tentatives atteint pour ${item.entityType}.${item.operation}',
              e,
            );
            await _syncQueueBox.delete(item.id);
          }
        }
      }

      TelemetryService.logInfo(
        'Synchronisation terminée: $successCount réussis, $errorCount erreurs',
      );

      _syncStatusController.add(SyncStatus.synced);
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur synchronisation', e, stackTrace);
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Synchroniser un élément spécifique
  Future<void> _syncItem(SyncQueueItem item) async {
    TelemetryService.logInfo('Sync ${item.entityType}.${item.operation} (${item.entityId})');

    switch (item.entityType) {
      case 'job':
        await _syncJob(item);
        break;
      case 'client':
        await _syncClient(item);
        break;
      case 'product':
        await _syncProduct(item);
        break;
      default:
        throw ValidationException(
          message: 'Type d\'entité inconnu: ${item.entityType}',
        );
    }
  }

  /// Synchroniser un job
  Future<void> _syncJob(SyncQueueItem item) async {
    switch (item.operation) {
      case 'create':
        // Uploader l'audio si présent
        if (item.payload['audio_url'] != null &&
            !item.payload['audio_url'].toString().startsWith('http')) {
          final localPath = item.payload['audio_url'];
          final file = File(localPath);
          
          if (await file.exists()) {
            final audioUrl = await _uploadAudio(file, item.entityId);
            item.payload['audio_url'] = audioUrl;
          }
        }

        await _supabase.from('jobs').insert(item.payload);
        break;

      case 'update':
        await _supabase
            .from('jobs')
            .update(item.payload)
            .eq('id', item.entityId);
        break;

      case 'delete':
        await _supabase.from('jobs').delete().eq('id', item.entityId);
        break;
    }
  }

  /// Synchroniser un client
  Future<void> _syncClient(SyncQueueItem item) async {
    switch (item.operation) {
      case 'create':
        await _supabase.from('clients').insert(item.payload);
        break;

      case 'update':
        await _supabase
            .from('clients')
            .update(item.payload)
            .eq('id', item.entityId);
        break;

      case 'delete':
        await _supabase.from('clients').delete().eq('id', item.entityId);
        break;
    }
  }

  /// Synchroniser un produit
  Future<void> _syncProduct(SyncQueueItem item) async {
    switch (item.operation) {
      case 'create':
        await _supabase.from('products').insert(item.payload);
        break;

      case 'update':
        await _supabase
            .from('products')
            .update(item.payload)
            .eq('id', item.entityId);
        break;

      case 'delete':
        await _supabase.from('products').delete().eq('id', item.entityId);
        break;
    }
  }

  // =====================================================
  // UPLOAD AUDIO
  // =====================================================

  /// Uploader un fichier audio vers Supabase Storage
  Future<String> _uploadAudio(File file, String jobId) async {
    try {
      TelemetryService.logInfo('Upload audio pour job $jobId');

      final fileName = '$jobId.m4a';
      final path = 'audio-recordings/$fileName';

      await _supabase.storage.from('audio-recordings').upload(
            path,
            file,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from('audio-recordings')
          .getPublicUrl(path);

      TelemetryService.logInfo('Audio uploadé: $publicUrl');

      return publicUrl;
    } catch (e, stackTrace) {
      TelemetryService.logError('Erreur upload audio', e, stackTrace);
      throw AppStorageException(
        message: 'Impossible d\'uploader le fichier audio',
        originalError: e,
      );
    }
  }

  // =====================================================
  // SYNCHRONISATION PÉRIODIQUE
  // =====================================================

  /// Démarrer la synchronisation périodique
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      Duration(minutes: AppConstants.syncIntervalMinutes),
      (_) => syncAll(),
    );
  }

  /// Arrêter la synchronisation périodique
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
  }

  // =====================================================
  // NETTOYAGE
  // =====================================================

  /// Dispose des ressources
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Status de synchronisation
enum SyncStatus {
  offline,
  syncing,
  synced,
  error,
}


