import '../../../../core/entities/app_user.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/entities/user_status.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.keycloakUserId,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phone,
    required super.profileImage,
    required super.gender,
    required super.dateOfBirth,
    required super.status,
    required super.role,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'] as String,
      keycloakUserId: json['keycloakUserId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      profileImage: json['profileImage'] as String,
      gender: GenderX.fromString(json['gender'] as String),
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      status: UserStatusX.fromString(json['status'] as String),
      role: UserRoleX.fromString(json['role'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Builds the session user from the backend's `UserProfileResponse`.
  /// The role comes from the Keycloak access token, since the backend
  /// stores no role column — Keycloak realm roles are the source of truth.
  factory AppUserModel.fromProfileResponse(
    Map<String, dynamic> json, {
    required List<String> realmRoles,
  }) {
    final now = DateTime.now();
    final dateOfBirth = json['dateOfBirth'] as String?;
    return AppUserModel(
      id: json['id'] as String,
      keycloakUserId: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profileImage: json['profileImage'] as String? ?? '',
      gender: GenderX.fromString(
        (json['gender'] as String? ?? '').toLowerCase(),
      ),
      dateOfBirth: dateOfBirth != null
          ? DateTime.parse(dateOfBirth)
          : DateTime(2000, 1, 1),
      status: UserStatusX.fromString(
        (json['status'] as String? ?? 'active').toLowerCase(),
      ),
      role: roleFromKeycloak(realmRoles),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Most-privileged Keycloak realm role wins; the role names match the
  /// backend's `UserRole` enum plus the `STAFF` authority in SecurityConfig.
  static UserRole roleFromKeycloak(List<String> realmRoles) {
    final roles = realmRoles.map((r) => r.toUpperCase()).toSet();
    if (roles.contains('ADMIN')) return UserRole.admin;
    if (roles.contains('MANAGER') || roles.contains('STAFF')) {
      return UserRole.tourManager;
    }
    if (roles.contains('TOUR_GUIDE')) return UserRole.tourGuide;
    return UserRole.customer;
  }

  factory AppUserModel.fromEntity(AppUser user) {
    return AppUserModel(
      id: user.id,
      keycloakUserId: user.keycloakUserId,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      profileImage: user.profileImage,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      status: user.status,
      role: user.role,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keycloakUserId': keycloakUserId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'gender': gender.name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'status': status.name,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
