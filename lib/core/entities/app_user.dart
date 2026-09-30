import 'package:equatable/equatable.dart';
import 'user_role.dart';
import 'user_status.dart';

/// Mirrors the `users` table. `role` has no column on that table by
/// design — in the real system roles/groups are owned by Keycloak (hence
/// `keycloakUserId`) rather than this service's database — but the app
/// still needs a role to gate navigation and screens, so it's carried
/// here as the client-side projection of that external assignment.
class AppUser extends Equatable {
  final String id;
  final String keycloakUserId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String profileImage;
  final Gender gender;
  final DateTime dateOfBirth;
  final UserStatus status;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    required this.keycloakUserId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.gender,
    required this.dateOfBirth,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  bool get isActive => status == UserStatus.active;

  AppUser copyWith({
    String? id,
    String? keycloakUserId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileImage,
    Gender? gender,
    DateTime? dateOfBirth,
    UserStatus? status,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      keycloakUserId: keycloakUserId ?? this.keycloakUserId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      status: status ?? this.status,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    keycloakUserId,
    firstName,
    lastName,
    email,
    phone,
    profileImage,
    gender,
    dateOfBirth,
    status,
    role,
    createdAt,
    updatedAt,
  ];
}
