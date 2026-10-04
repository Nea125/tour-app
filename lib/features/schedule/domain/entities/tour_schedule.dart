import 'package:equatable/equatable.dart';
import 'schedule_status.dart';

class TourSchedule extends Equatable {
  final String id;
  final String tourId;
  final DateTime startDate;
  final DateTime endDate;

  // Response only
  final int? capacity;
  final int? availableCapacity;

  final ScheduleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TourSchedule({
    required this.id,
    required this.tourId,
    required this.startDate,
    required this.endDate,
    this.capacity,
    this.availableCapacity,
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
    int? availableCapacity,
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
      availableCapacity: availableCapacity ?? this.availableCapacity,
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
    availableCapacity,
    status,
    createdAt,
    updatedAt,
  ];
}