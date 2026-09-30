import '../../../../core/network/api_json.dart';
import '../../domain/entities/schedule_status.dart';
import '../../domain/entities/tour_schedule.dart';

class TourScheduleModel extends TourSchedule {
  const TourScheduleModel({
    required super.id,
    required super.tourId,
    required super.startDate,
    required super.endDate,
    required super.capacity,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TourScheduleModel.fromJson(Map<String, dynamic> json) {
    return TourScheduleModel(
      id: json['id'] as String,
      tourId: json['tourId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      capacity: json['capacity'] as int,
      status: ScheduleStatusX.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// From the backend's `TourScheduleResponse` (no timestamps).
  factory TourScheduleModel.fromApi(Map<String, dynamic> json) {
    final now = DateTime.now();
    return TourScheduleModel(
      id: ApiJson.id(json['id']),
      tourId: ApiJson.id(json['tourId']),
      startDate: ApiJson.date(json['startDate']),
      endDate: ApiJson.date(json['endDate']),
      capacity: ApiJson.integer(json['capacity']),
      status: statusFromApi(json['status']),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// `TourScheduleStatus` is OPEN/FULL/COMPLETED/CANCELLED; FULL is the
  /// app's "closed".
  static ScheduleStatus statusFromApi(dynamic value) {
    final name = ApiJson.enumName(value);
    return name == 'full'
        ? ScheduleStatus.closed
        : ScheduleStatusX.fromString(name);
  }

  static String statusToApi(ScheduleStatus status) =>
      status == ScheduleStatus.closed ? 'FULL' : status.name.toUpperCase();

  factory TourScheduleModel.fromEntity(TourSchedule s) {
    return TourScheduleModel(
      id: s.id,
      tourId: s.tourId,
      startDate: s.startDate,
      endDate: s.endDate,
      capacity: s.capacity,
      status: s.status,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tourId': tourId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'capacity': capacity,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
