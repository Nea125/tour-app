enum DestinationStatus { active, inactive }

extension DestinationStatusX on DestinationStatus {
  String get label => this == DestinationStatus.active ? 'Active' : 'Inactive';

  static DestinationStatus fromString(String value) {
    return DestinationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DestinationStatus.active,
    );
  }
}
