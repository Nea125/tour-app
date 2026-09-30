import '../../../../core/entities/user_status.dart';
import '../../../../core/network/api_json.dart';
import '../../domain/entities/booking_participant.dart';

class BookingParticipantModel extends BookingParticipant {
  const BookingParticipantModel({
    required super.id,
    required super.bookingId,
    required super.fullName,
    required super.gender,
    required super.dateOfBirth,
    required super.phone,
    required super.email,
  });

  factory BookingParticipantModel.fromJson(Map<String, dynamic> json) {
    return BookingParticipantModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      fullName: json['fullName'] as String,
      gender: GenderX.fromString(json['gender'] as String),
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      phone: json['phone'] as String,
      email: json['email'] as String,
    );
  }

  factory BookingParticipantModel.fromApi(Map<String, dynamic> json) {
    return BookingParticipantModel(
      id: ApiJson.id(json['id']),
      bookingId: ApiJson.id(json['bookingId']),
      fullName: ApiJson.string(json['fullName']),
      gender: GenderX.fromString(ApiJson.enumName(json['gender'])),
      dateOfBirth: ApiJson.date(json['dateOfBirth'], DateTime(2000)),
      phone: ApiJson.string(json['phone']),
      email: ApiJson.string(json['email']),
    );
  }

  /// `ParticipantRequest` body.
  Map<String, dynamic> toApi() => {
    'bookingId': ApiJson.toId(bookingId),
    'fullName': fullName,
    'gender': gender.name.toUpperCase(),
    'dateOfBirth': ApiJson.localDate(dateOfBirth),
    'phone': phone,
    'email': email,
  };

  factory BookingParticipantModel.fromEntity(BookingParticipant p) {
    return BookingParticipantModel(
      id: p.id,
      bookingId: p.bookingId,
      fullName: p.fullName,
      gender: p.gender,
      dateOfBirth: p.dateOfBirth,
      phone: p.phone,
      email: p.email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'fullName': fullName,
      'gender': gender.name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'phone': phone,
      'email': email,
    };
  }
}
