import 'package:flutter/foundation.dart';

Map<String, dynamic>? _asMap(dynamic value) {
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

@immutable
class PlaceModel {
  final String id;
  final String name;
  final DateTime? createdAt;

  const PlaceModel({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

@immutable
class MainSectionModel {
  final String id;
  final String name;
  final String placeId;
  final PlaceModel? place;
  final DateTime? createdAt;

  const MainSectionModel({
    required this.id,
    required this.name,
    required this.placeId,
    this.place,
    this.createdAt,
  });

  factory MainSectionModel.fromMap(Map<String, dynamic> map) {
    final placeMap = _asMap(map['places']);
    return MainSectionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      placeId: map['place_id'] as String,
      place: placeMap != null ? PlaceModel.fromMap(placeMap) : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }
}

@immutable
class CategoryModel {
  final String id;
  final String name;
  final String? iconUrl;
  final String mainSectionId;
  final MainSectionModel? mainSection;
  final int? serviceCount;
  final DateTime? createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.mainSectionId,
    this.mainSection,
    this.serviceCount,
    this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    final msMap = _asMap(map['main_sections']);
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconUrl: map['icon_url'] as String?,
      mainSectionId: map['main_section_id'] as String? ?? '',
      mainSection: msMap != null ? MainSectionModel.fromMap(msMap) : null,
      serviceCount: map['service_count'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon_url': iconUrl,
        'main_section_id': mainSectionId,
      };
}
