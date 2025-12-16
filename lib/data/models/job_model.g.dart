// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobModel _$JobModelFromJson(Map<String, dynamic> json) => JobModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      createdBy: json['created_by'] as String,
      clientId: json['client_id'] as String?,
      status: json['status'] as String,
      audioUrl: json['audio_url'] as String?,
      audioDurationSeconds: (json['audio_duration_seconds'] as num?)?.toInt(),
      transcriptionText: json['transcription_text'] as String?,
      photoUrls: (json['photo_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      gpsLatitude: (json['gps_latitude'] as num?)?.toDouble(),
      gpsLongitude: (json['gps_longitude'] as num?)?.toDouble(),
      gpsCapturedAt: json['gps_captured_at'] == null
          ? null
          : DateTime.parse(json['gps_captured_at'] as String),
      signatureUrl: json['signature_url'] as String?,
      signatureCapturedAt: json['signature_captured_at'] == null
          ? null
          : DateTime.parse(json['signature_captured_at'] as String),
      aiConfidenceScore: (json['ai_confidence_score'] as num?)?.toDouble(),
      aiExtractedData: json['ai_extracted_data'] as Map<String, dynamic>?,
      aiProcessingError: json['ai_processing_error'] as String?,
      aiRequiresClarification:
          json['ai_requires_clarification'] as bool? ?? false,
      interventionDate: json['intervention_date'] == null
          ? null
          : DateTime.parse(json['intervention_date'] as String),
      interventionDurationHours:
          (json['intervention_duration_hours'] as num?)?.toDouble(),
      totalHt: (json['total_ht'] as num?)?.toDouble(),
      totalTtc: (json['total_ttc'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      syncedAt: json['synced_at'] == null
          ? null
          : DateTime.parse(json['synced_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$JobModelToJson(JobModel instance) => <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'created_by': instance.createdBy,
      'client_id': instance.clientId,
      'status': instance.status,
      'audio_url': instance.audioUrl,
      'audio_duration_seconds': instance.audioDurationSeconds,
      'transcription_text': instance.transcriptionText,
      'photo_urls': instance.photoUrls,
      'gps_latitude': instance.gpsLatitude,
      'gps_longitude': instance.gpsLongitude,
      'gps_captured_at': instance.gpsCapturedAt?.toIso8601String(),
      'signature_url': instance.signatureUrl,
      'signature_captured_at': instance.signatureCapturedAt?.toIso8601String(),
      'ai_confidence_score': instance.aiConfidenceScore,
      'ai_extracted_data': instance.aiExtractedData,
      'ai_processing_error': instance.aiProcessingError,
      'ai_requires_clarification': instance.aiRequiresClarification,
      'intervention_date': instance.interventionDate?.toIso8601String(),
      'intervention_duration_hours': instance.interventionDurationHours,
      'total_ht': instance.totalHt,
      'total_ttc': instance.totalTtc,
      'notes': instance.notes,
      'synced_at': instance.syncedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

