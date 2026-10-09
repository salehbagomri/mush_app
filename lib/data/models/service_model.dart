import 'package:flutter/foundation.dart';
import 'category_model.dart';
import 'requirement_model.dart';

@immutable
class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? phone;       // ✅ String بدل int
  final String? whatsapp;    // ✅ String بدل int
  final String? email;
  final String? website;
  final String? workDays;
  final String? workTime;
  final String? imageUrl;
  final String categoryId;
  final CategoryModel? category;
  final String? providerId;
  final bool isSuspended;
  final bool isDeleted;
  final RequirementModel? requirement;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.workDays,
    this.workTime,
    this.imageUrl,
    required this.categoryId,
    this.category,
    this.providerId,
    this.isSuspended = false,
    this.isDeleted = false,
    this.requirement,
    this.createdAt,
    this.updatedAt,
  });

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    final catMap = _asMap(map['categories']);
    final reqMap = _asMap(map['requirements']);

    return ServiceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      address: map['address'] as String?,
      phone: map['phone']?.toString(),
      whatsapp: map['whatsapp']?.toString(),
      email: map['email'] as String?,
      website: map['website'] as String?,
      workDays: map['work_days'] as String?,
      workTime: map['work_time'] as String?,
      imageUrl: map['image_url'] as String?,
      categoryId: map['category_id'] as String,
      category: catMap != null ? CategoryModel.fromMap(catMap) : null,
      providerId: map['provider_id'] as String?,
      isSuspended: map['is_suspended'] as bool? ?? false,
      isDeleted: map['is_deleted'] as bool? ?? false,
      requirement: reqMap != null ? RequirementModel.fromMap(reqMap) : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'website': website,
      'work_days': workDays,
      'work_time': workTime,
      'image_url': imageUrl,
      'category_id': categoryId,
      'provider_id': providerId,
      'is_suspended': isSuspended,
    };
  }

  ServiceModel copyWith({
    String? name,
    String? description,
    String? address,
    String? phone,
    String? whatsapp,
    String? email,
    String? website,
    String? workDays,
    String? workTime,
    String? imageUrl,
    String? categoryId,
    bool? isSuspended,
  }) {
    return ServiceModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      website: website ?? this.website,
      workDays: workDays ?? this.workDays,
      workTime: workTime ?? this.workTime,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      providerId: providerId,
      isSuspended: isSuspended ?? this.isSuspended,
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasWhatsapp => whatsapp != null && whatsapp!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get isActive => !isSuspended && !isDeleted;
}
