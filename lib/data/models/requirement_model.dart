import 'package:flutter/foundation.dart';

@immutable
class RequirementModel {
  final String id;
  final String serviceId;
  final String? documents;
  final String? age;
  final String? fees;
  final String? gender;
  final bool needsImmunizationRecord;
  final bool needsPersonalPhoto;
  final DateTime? createdAt;

  const RequirementModel({
    required this.id,
    required this.serviceId,
    this.documents,
    this.age,
    this.fees,
    this.gender,
    this.needsImmunizationRecord = false,
    this.needsPersonalPhoto = false,
    this.createdAt,
  });

  factory RequirementModel.fromMap(Map<String, dynamic> map) {
    return RequirementModel(
      id: map['id'] as String,
      serviceId: map['service_id'] as String,
      documents: map['documents'] as String?,
      age: map['age'] as String?,
      fees: map['fees'] as String?,
      gender: map['gender'] as String?,
      needsImmunizationRecord: map['needs_immunization_record'] as bool? ?? false,
      needsPersonalPhoto: map['needs_personal_photo'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_id': serviceId,
      'documents': documents,
      'age': age,
      'fees': fees,
      'gender': gender,
      'needs_immunization_record': needsImmunizationRecord,
      'needs_personal_photo': needsPersonalPhoto,
    };
  }

  bool get hasAnyRequirement =>
      (documents != null && documents!.isNotEmpty) ||
      (age != null && age!.isNotEmpty) ||
      (fees != null && fees!.isNotEmpty) ||
      needsImmunizationRecord ||
      needsPersonalPhoto;
}

@immutable
class AdvertisementModel {
  final String id;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;
  final DateTime? createdAt;

  const AdvertisementModel({
    required this.id,
    required this.imageUrl,
    this.linkUrl,
    this.isActive = true,
    this.createdAt,
  });

  factory AdvertisementModel.fromMap(Map<String, dynamic> map) {
    return AdvertisementModel(
      id: map['id'] as String,
      imageUrl: map['image_url'] as String,
      linkUrl: map['link_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'image_url': imageUrl,
        'link_url': linkUrl,
        'is_active': isActive,
      };
}
