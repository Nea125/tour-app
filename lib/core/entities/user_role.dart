enum UserRole {
  ADMIN,
  MANAGER,
  GUIDE,
  CUSTOMER,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.ADMIN:
        return 'Admin';
      case UserRole.MANAGER:
        return 'Manager';
      case UserRole.GUIDE:
        return 'Guide';
      case UserRole.CUSTOMER:
        return 'Customer';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN':
        return UserRole.ADMIN;

      case 'MANAGER':
        return UserRole.MANAGER;

      case 'GUIDE':
        return UserRole.GUIDE;

      case 'CUSTOMER':
        return UserRole.CUSTOMER;

      default:
        return UserRole.CUSTOMER;
    }
  }
}