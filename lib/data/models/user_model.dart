import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  
  @JsonKey(name: 'full_name')
  final String? fullName;
  
  final String role; // 'admin' ou 'tech'
  
  @JsonKey(name: 'company_id')
  final String? companyId;
  
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  
  final String? phone;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // V2.3 : Web Payments (Stripe)
  @JsonKey(name: 'subscription_status')
  final String? subscriptionStatus; // 'free', 'active', 'trialing', 'canceled', etc.
  
  @JsonKey(name: 'subscription_tier')
  final String? subscriptionTier; // 'monthly', 'annual', 'oto'
  
  @JsonKey(name: 'subscription_expires_at')
  final DateTime? subscriptionExpiresAt;
  
  @JsonKey(name: 'stripe_customer_id')
  final String? stripeCustomerId;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.companyId,
    this.avatarUrl,
    this.phone,
    this.isActive = true,
    this.subscriptionStatus,
    this.subscriptionTier,
    this.subscriptionExpiresAt,
    this.stripeCustomerId,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Vérifie si l'utilisateur est premium
  bool get isPremium =>
      subscriptionStatus == 'active' || subscriptionStatus == 'trialing';

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? companyId,
    String? avatarUrl,
    String? phone,
    bool? isActive,
    String? subscriptionStatus,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
    String? stripeCustomerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isTech => role == 'tech';
}


