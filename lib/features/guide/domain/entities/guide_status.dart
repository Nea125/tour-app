enum GuideStatus { active, inactive }

extension GuideStatusX on GuideStatus {
  String get label => this == GuideStatus.active ? 'Active' : 'Inactive';

  static GuideStatus fromString(String value) {
    return GuideStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GuideStatus.active,
    );
  }
}
