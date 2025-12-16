import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final String id;
  
  @JsonKey(name: 'company_id')
  final String companyId;
  
  final String reference;
  final String name;
  final String? description;
  
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  
  final String unit;
  final String? category;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.companyId,
    required this.reference,
    required this.name,
    this.description,
    required this.unitPrice,
    this.unit = 'unité',
    this.category,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  String get displayName => '$reference - $name';
  
  String get priceWithUnit => '$unitPrice€/$unit';
}


