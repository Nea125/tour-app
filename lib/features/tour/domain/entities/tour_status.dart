enum TourStatus { active, inactive, draft }

extension TourStatusX on TourStatus {
  String get label {
    switch (this) {
      case TourStatus.active:
        return 'Active';
      case TourStatus.inactive:
        return 'Inactive';
      case TourStatus.draft:
        return 'Draft';
    }
  }

  static TourStatus fromString(String value) {
    return TourStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TourStatus.active,
    );
  }
}
