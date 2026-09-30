enum UserRole { admin, tourManager, tourGuide, customer }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.tourManager:
        return 'Tour Manager';
      case UserRole.tourGuide:
        return 'Tour Guide';
      case UserRole.customer:
        return 'Customer';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.customer,
    );
  }
}
