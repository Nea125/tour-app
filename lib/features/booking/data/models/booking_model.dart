import '../../../../core/network/api_json.dart';
import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.bookingCode,
    required super.userId,
    required super.tourScheduleId,
    required super.numberOfPeople,
    required super.bookingDate,
    required super.status,
    super.specialRequest,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      bookingCode: json['bookingCode'] as String,
      userId: json['userId'] as String,
      tourScheduleId: json['tourScheduleId'] as String,
      numberOfPeople: json['numberOfPeople'] as int,
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      status: BookingStatusX.fromString(json['status'] as String),
      specialRequest: json['specialRequest'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// From the backend's `BookingResponse` (no special request or
  /// timestamps; `bookingDate` stands in for both).
  factory BookingModel.fromApi(Map<String, dynamic> json) {
    final bookingDate = ApiJson.date(json['bookingDate']);
    return BookingModel(
      id: ApiJson.id(json['id']),
      bookingCode: ApiJson.string(json['bookingCode']),
      userId: ApiJson.id(json['userId']),
      tourScheduleId: ApiJson.id(json['scheduleId']),
      numberOfPeople: ApiJson.integer(json['numberOfPeople']),
      bookingDate: bookingDate,
      status: BookingStatusX.fromString(ApiJson.enumName(json['status'])),
      createdAt: bookingDate,
      updatedAt: bookingDate,
    );
  }

  factory BookingModel.fromEntity(Booking b) {
    return BookingModel(
      id: b.id,
      bookingCode: b.bookingCode,
      userId: b.userId,
      tourScheduleId: b.tourScheduleId,
      numberOfPeople: b.numberOfPeople,
      bookingDate: b.bookingDate,
      status: b.status,
      specialRequest: b.specialRequest,
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingCode': bookingCode,
      'userId': userId,
      'tourScheduleId': tourScheduleId,
      'numberOfPeople': numberOfPeople,
      'bookingDate': bookingDate.toIso8601String(),
      'status': status.name,
      'specialRequest': specialRequest,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
