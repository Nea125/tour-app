import 'package:equatable/equatable.dart';

enum BookingStatus { pending, paid, cancelled }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.paid:
        return 'Paid';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

class Booking extends Equatable {
  final String id;
  final String bookingCode;
  final String userId;
  final String tourScheduleId;
  final int numberOfPeople;
  final DateTime bookingDate;
  final BookingStatus status;
  final String specialRequest;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Booking({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.tourScheduleId,
    required this.numberOfPeople,
    required this.bookingDate,
    required this.status,
    this.specialRequest = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// A pending booking can still be paid until its schedule's start day.
  bool canPayBefore(DateTime scheduleStart, {DateTime? now}) {
    if (status != BookingStatus.pending) return false;
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final startDay = DateTime(
      scheduleStart.year,
      scheduleStart.month,
      scheduleStart.day,
    );
    return today.isBefore(startDay);
  }

  Booking copyWith({
    String? id,
    String? bookingCode,
    String? userId,
    String? tourScheduleId,
    int? numberOfPeople,
    DateTime? bookingDate,
    BookingStatus? status,
    String? specialRequest,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      bookingCode: bookingCode ?? this.bookingCode,
      userId: userId ?? this.userId,
      tourScheduleId: tourScheduleId ?? this.tourScheduleId,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      specialRequest: specialRequest ?? this.specialRequest,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bookingCode,
    userId,
    tourScheduleId,
    numberOfPeople,
    bookingDate,
    status,
    specialRequest,
    createdAt,
    updatedAt,
  ];
}
