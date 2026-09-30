enum UserStatus { active, inactive, suspended }

extension UserStatusX on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
    }
  }

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserStatus.active,
    );
  }
}

enum Gender { male, female, other }

extension GenderX on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Gender.other,
    );
  }
}
