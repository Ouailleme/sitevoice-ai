// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      reference: json['reference'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'unité',
      category: json['category'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'reference': instance.reference,
      'name': instance.name,
      'description': instance.description,
      'unit_price': instance.unitPrice,
      'unit': instance.unit,
      'category': instance.category,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

