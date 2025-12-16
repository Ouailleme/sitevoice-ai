// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientModel _$ClientModelFromJson(Map<String, dynamic> json) => ClientModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      postalCode: json['postal_code'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ClientModelToJson(ClientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'name': instance.name,
      'address': instance.address,
      'postal_code': instance.postalCode,
      'city': instance.city,
      'phone': instance.phone,
      'email': instance.email,
      'notes': instance.notes,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

