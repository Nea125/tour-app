import 'package:equatable/equatable.dart';
import '../../../../core/entities/user_status.dart';

class BookingParticipant extends Equatable {
  final String id;
  final String bookingId;
  final String fullName;
  final Gender gender;
  final DateTime dateOfBirth;
  final String phone;
  final String email;

  const BookingParticipant({
    required this.id,
    required this.bookingId,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.phone,
    required this.email,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  bool get isMinor => age < 18;

  BookingParticipant copyWith({
    String? id,
    String? bookingId,
    String? fullName,
    Gender? gender,
    DateTime? dateOfBirth,
    String? phone,
    String? email,
  }) {
    return BookingParticipant(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bookingId,
    fullName,
    gender,
    dateOfBirth,
    phone,
    email,
  ];
}
