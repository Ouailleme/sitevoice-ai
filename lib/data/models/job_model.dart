import 'package:json_annotation/json_annotation.dart';

part 'job_model.g.dart';

@JsonSerializable()
class JobModel {
  final String id;
  
  @JsonKey(name: 'company_id')
  final String companyId;
  
  @JsonKey(name: 'created_by')
  final String createdBy;
  
  @JsonKey(name: 'client_id')
  final String? clientId;
  
  final String status;
  
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  
  @JsonKey(name: 'audio_duration_seconds')
  final int? audioDurationSeconds;
  
  @JsonKey(name: 'transcription_text')
  final String? transcriptionText;
  
  @JsonKey(name: 'photo_urls')
  final List<String>? photoUrls;
  
  @JsonKey(name: 'gps_latitude')
  final double? gpsLatitude;
  
  @JsonKey(name: 'gps_longitude')
  final double? gpsLongitude;
  
  @JsonKey(name: 'gps_captured_at')
  final DateTime? gpsCapturedAt;
  
  @JsonKey(name: 'signature_url')
  final String? signatureUrl;
  
  @JsonKey(name: 'signature_captured_at')
  final DateTime? signatureCapturedAt;
  
  @JsonKey(name: 'ai_confidence_score')
  final double? aiConfidenceScore;
  
  @JsonKey(name: 'ai_extracted_data')
  final Map<String, dynamic>? aiExtractedData;
  
  @JsonKey(name: 'ai_processing_error')
  final String? aiProcessingError;
  
  @JsonKey(name: 'ai_requires_clarification')
  final bool aiRequiresClarification;
  
  @JsonKey(name: 'intervention_date')
  final DateTime? interventionDate;
  
  @JsonKey(name: 'intervention_duration_hours')
  final double? interventionDurationHours;
  
  @JsonKey(name: 'total_ht')
  final double? totalHt;
  
  @JsonKey(name: 'total_ttc')
  final double? totalTtc;
  
  final String? notes;
  
  @JsonKey(name: 'synced_at')
  final DateTime? syncedAt;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  JobModel({
    required this.id,
    required this.companyId,
    required this.createdBy,
    this.clientId,
    required this.status,
    this.audioUrl,
    this.audioDurationSeconds,
    this.transcriptionText,
    this.photoUrls,
    this.gpsLatitude,
    this.gpsLongitude,
    this.gpsCapturedAt,
    this.signatureUrl,
    this.signatureCapturedAt,
    this.aiConfidenceScore,
    this.aiExtractedData,
    this.aiProcessingError,
    this.aiRequiresClarification = false,
    this.interventionDate,
    this.interventionDurationHours,
    this.totalHt,
    this.totalTtc,
    this.notes,
    this.syncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) =>
      _$JobModelFromJson(json);

  Map<String, dynamic> toJson() => _$JobModelToJson(this);

  JobModel copyWith({
    String? id,
    String? companyId,
    String? createdBy,
    String? clientId,
    String? status,
    String? audioUrl,
    int? audioDurationSeconds,
    String? transcriptionText,
    List<String>? photoUrls,
    double? gpsLatitude,
    double? gpsLongitude,
    DateTime? gpsCapturedAt,
    String? signatureUrl,
    DateTime? signatureCapturedAt,
    double? aiConfidenceScore,
    Map<String, dynamic>? aiExtractedData,
    String? aiProcessingError,
    bool? aiRequiresClarification,
    DateTime? interventionDate,
    double? interventionDurationHours,
    double? totalHt,
    double? totalTtc,
    String? notes,
    DateTime? syncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      createdBy: createdBy ?? this.createdBy,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      transcriptionText: transcriptionText ?? this.transcriptionText,
      photoUrls: photoUrls ?? this.photoUrls,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      gpsCapturedAt: gpsCapturedAt ?? this.gpsCapturedAt,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      signatureCapturedAt: signatureCapturedAt ?? this.signatureCapturedAt,
      aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
      aiExtractedData: aiExtractedData ?? this.aiExtractedData,
      aiProcessingError: aiProcessingError ?? this.aiProcessingError,
      aiRequiresClarification: aiRequiresClarification ?? this.aiRequiresClarification,
      interventionDate: interventionDate ?? this.interventionDate,
      interventionDurationHours:
          interventionDurationHours ?? this.interventionDurationHours,
      totalHt: totalHt ?? this.totalHt,
      totalTtc: totalTtc ?? this.totalTtc,
      notes: notes ?? this.notes,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPendingAudio => status == 'pending_audio';
  bool get isProcessing => status == 'processing';
  bool get needsReview => status == 'review_needed';
  bool get isValidated => status == 'validated';
  bool get isInvoiced => status == 'invoiced';
  bool get isSynced => syncedAt != null;
}

