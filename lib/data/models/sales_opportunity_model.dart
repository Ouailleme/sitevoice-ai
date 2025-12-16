import 'package:json_annotation/json_annotation.dart';

part 'sales_opportunity_model.g.dart';

/// Modele pour les opportunites commerciales generees par l'IA
@JsonSerializable()
class SalesOpportunityModel {
  final String id;
  
  @JsonKey(name: 'equipment_id')
  final String? equipmentId;
  
  @JsonKey(name: 'client_id')
  final String clientId;
  
  @JsonKey(name: 'assigned_to_user_id')
  final String? assignedToUserId;
  
  @JsonKey(name: 'opportunity_type')
  final String opportunityType; // 'replacement', 'upgrade', 'maintenance_contract'
  
  @JsonKey(name: 'confidence_score')
  final double? confidenceScore;
  
  @JsonKey(name: 'estimated_value')
  final double? estimatedValue;
  
  @JsonKey(name: 'trigger_reason')
  final String? triggerReason;
  
  @JsonKey(name: 'suggested_action')
  final String? suggestedAction;
  
  final String status; // 'pending', 'accepted', 'declined', 'converted', 'expired'
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'notified_at')
  final DateTime? notifiedAt;
  
  @JsonKey(name: 'responded_at')
  final DateTime? respondedAt;
  
  @JsonKey(name: 'converted_at')
  final DateTime? convertedAt;
  
  @JsonKey(name: 'ai_metadata')
  final Map<String, dynamic>? aiMetadata;
  
  // Relations (chargeees via join)
  final String? clientName;
  final String? equipmentType;

  SalesOpportunityModel({
    required this.id,
    this.equipmentId,
    required this.clientId,
    this.assignedToUserId,
    required this.opportunityType,
    this.confidenceScore,
    this.estimatedValue,
    this.triggerReason,
    this.suggestedAction,
    required this.status,
    required this.createdAt,
    this.notifiedAt,
    this.respondedAt,
    this.convertedAt,
    this.aiMetadata,
    this.clientName,
    this.equipmentType,
  });

  factory SalesOpportunityModel.fromJson(Map<String, dynamic> json) =>
      _$SalesOpportunityModelFromJson(json);

  Map<String, dynamic> toJson() => _$SalesOpportunityModelToJson(this);

  SalesOpportunityModel copyWith({
    String? id,
    String? equipmentId,
    String? clientId,
    String? assignedToUserId,
    String? opportunityType,
    double? confidenceScore,
    double? estimatedValue,
    String? triggerReason,
    String? suggestedAction,
    String? status,
    DateTime? createdAt,
    DateTime? notifiedAt,
    DateTime? respondedAt,
    DateTime? convertedAt,
    Map<String, dynamic>? aiMetadata,
    String? clientName,
    String? equipmentType,
  }) {
    return SalesOpportunityModel(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      clientId: clientId ?? this.clientId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      opportunityType: opportunityType ?? this.opportunityType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      triggerReason: triggerReason ?? this.triggerReason,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      convertedAt: convertedAt ?? this.convertedAt,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      clientName: clientName ?? this.clientName,
      equipmentType: equipmentType ?? this.equipmentType,
    );
  }

  /// Retourne la couleur associee au niveau de confiance
  String get confidenceLevel {
    if (confidenceScore == null) return 'unknown';
    if (confidenceScore! >= 90) return 'very_high';
    if (confidenceScore! >= 80) return 'high';
    if (confidenceScore! >= 70) return 'medium';
    return 'low';
  }

  /// Retourne le montant formate
  String get formattedValue {
    if (estimatedValue == null) return 'N/A';
    return '${estimatedValue!.toStringAsFixed(2)}€';
  }

  /// Est-ce une opportunite urgente ?
  bool get isUrgent {
    return confidenceScore != null && confidenceScore! >= 90;
  }

  /// Est-ce une nouvelle opportunite (< 24h) ?
  bool get isNew {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    return diff.inHours < 24;
  }
}




