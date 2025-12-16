import 'package:json_annotation/json_annotation.dart';

part 'client_model.g.dart';

@JsonSerializable()
class ClientModel {
  final String id;
  
  @JsonKey(name: 'company_id')
  final String companyId;
  
  final String name;
  final String? address;
  
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  
  final String? city;
  final String? phone;
  final String? email;
  final String? notes;
  
  @JsonKey(name: 'created_by')
  final String? createdBy;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  ClientModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.address,
    this.postalCode,
    this.city,
    this.phone,
    this.email,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) =>
      _$ClientModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClientModelToJson(this);

  String get fullAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (postalCode != null) parts.add(postalCode!);
    if (city != null) parts.add(city!);
    return parts.join(', ');
  }
}


