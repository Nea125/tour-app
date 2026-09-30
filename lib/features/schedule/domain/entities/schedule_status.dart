enum ScheduleStatus { open, closed, completed, cancelled }

extension ScheduleStatusX on ScheduleStatus {
  String get label {
    switch (this) {
      case ScheduleStatus.open:
        return 'Open';
      case ScheduleStatus.closed:
        return 'Closed';
      case ScheduleStatus.completed:
        return 'Completed';
      case ScheduleStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ScheduleStatus fromString(String value) {
    return ScheduleStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ScheduleStatus.open,
    );
  }
}
