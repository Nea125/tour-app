import 'package:equatable/equatable.dart';
import 'schedule_status.dart';

class TourSchedule extends Equatable {
  final String id;
  final String tourId;
  final DateTime startDate;
  final DateTime endDate;
  final int capacity;
  final ScheduleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TourSchedule({
    required this.id,
    required this.tourId,
    required this.startDate,
    required this.endDate,
    required this.capacity,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  TourSchedule copyWith({
    String? id,
    String? tourId,
    DateTime? startDate,
    DateTime? endDate,
    int? capacity,
    ScheduleStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TourSchedule(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tourId,
    startDate,
    endDate,
    capacity,
    status,
    createdAt,
    updatedAt,
  ];
}
