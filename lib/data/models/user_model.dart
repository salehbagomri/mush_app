import 'package:flutter/foundation.dart';

enum UserRole { user, providerGovt, providerPrivate, admin }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.providerGovt:
        return 'provider_govt';
      case UserRole.providerPrivate:
        return 'provider_private';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String? role) {
    switch (role) {
      case 'provider_govt':
        return UserRole.providerGovt;
      case 'provider_private':
        return UserRole.providerPrivate;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}

@immutable
class UserModel {
  final String id;
  final String username;
  final String email;
  final UserRole role;
  final String? categoryId;
  final String? avatarUrl;
  final bool isBlocked;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.role = UserRole.user,
    this.categoryId,
    this.avatarUrl,
    this.isBlocked = false,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRoleExtension.fromString(map['role'] as String?),
      categoryId: map['category_id'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isBlocked: map['is_blocked'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role.name,
      'category_id': categoryId,
      'avatar_url': avatarUrl,
      'is_blocked': isBlocked,
    };
  }

  UserModel copyWith({
    String? username,
    String? email,
    UserRole? role,
    String? categoryId,
    String? avatarUrl,
    bool? isBlocked,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      categoryId: categoryId ?? this.categoryId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isProvider =>
      role == UserRole.providerGovt || role == UserRole.providerPrivate;
  bool get isPrivateProvider => role == UserRole.providerPrivate;
  bool get isGovtProvider => role == UserRole.providerGovt;
}
