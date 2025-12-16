import 'package:hive/hive.dart';

part 'local_job.g.dart';

/// Modèle Hive pour stocker les jobs en local (offline-first)
@HiveType(typeId: 0)
class LocalJob {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String clientId;

  @HiveField(2)
  final String clientName;

  @HiveField(3)
  final String? address;

  @HiveField(4)
  final List<LocalJobItem> items;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final double totalHt;

  @HiveField(7)
  final String? audioFilePath; // Chemin local

  @HiveField(8)
  final String? audioStoragePath; // Chemin Supabase Storage

  @HiveField(9)
  final String? transcription;

  @HiveField(10)
  final int? confidenceScore;

  @HiveField(11)
  final bool isSynced;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime? syncedAt;

  @HiveField(14)
  final String status; // draft, pending_sync, synced, error

  LocalJob({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.address,
    required this.items,
    this.notes,
    required this.totalHt,
    this.audioFilePath,
    this.audioStoragePath,
    this.transcription,
    this.confidenceScore,
    this.isSynced = false,
    required this.createdAt,
    this.syncedAt,
    this.status = 'draft',
  });

  /// Créer un LocalJob depuis les données extraites par l'IA
  factory LocalJob.fromExtractedData({
    required String id,
    required String clientId,
    required String clientName,
    required Map<String, dynamic> extractedData,
    String? audioFilePath,
    String? audioStoragePath,
    String? transcription,
  }) {
    final products = (extractedData['produits'] as List<dynamic>?) ?? [];
    final items = products.map((p) => LocalJobItem.fromMap(p as Map<String, dynamic>)).toList();

    final totalHt = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.quantity * (item.unitPrice ?? 0)),
    );

    return LocalJob(
      id: id,
      clientId: clientId,
      clientName: clientName,
      address: extractedData['adresse_intervention'] as String?,
      items: items,
      notes: extractedData['notes'] as String?,
      totalHt: totalHt,
      audioFilePath: audioFilePath,
      audioStoragePath: audioStoragePath,
      transcription: transcription,
      confidenceScore: extractedData['confiance'] as int?,
      isSynced: false,
      createdAt: DateTime.now(),
      status: 'draft',
    );
  }

  /// Convertir en Map pour Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'client_id': clientId,
      'address': address,
      'notes': notes,
      'total_ht': totalHt,
      'audio_file_path': audioStoragePath,
      'transcription': transcription,
      'confidence_score': confidenceScore,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LocalJob copyWith({
    bool? isSynced,
    DateTime? syncedAt,
    String? status,
    String? audioStoragePath,
  }) {
    return LocalJob(
      id: id,
      clientId: clientId,
      clientName: clientName,
      address: address,
      items: items,
      notes: notes,
      totalHt: totalHt,
      audioFilePath: audioFilePath,
      audioStoragePath: audioStoragePath ?? this.audioStoragePath,
      transcription: transcription,
      confidenceScore: confidenceScore,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      status: status ?? this.status,
    );
  }
}

/// Ligne de produit/service d'un job
@HiveType(typeId: 1)
class LocalJobItem {
  @HiveField(0)
  final String productName;

  @HiveField(1)
  final double quantity;

  @HiveField(2)
  final String unit;

  @HiveField(3)
  final double? unitPrice;

  @HiveField(4)
  final bool isNewProduct;

  LocalJobItem({
    required this.productName,
    required this.quantity,
    required this.unit,
    this.unitPrice,
    this.isNewProduct = false,
  });

  factory LocalJobItem.fromMap(Map<String, dynamic> map) {
    return LocalJobItem(
      productName: map['nom'] as String,
      quantity: (map['quantite'] as num).toDouble(),
      unit: map['unite'] as String,
      unitPrice: map['prix_unitaire'] != null ? (map['prix_unitaire'] as num).toDouble() : null,
      isNewProduct: map['produit_nouveau'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSupabaseMap(String jobId) {
    return {
      'job_id': jobId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
    };
  }

  double get total => quantity * (unitPrice ?? 0);
}

