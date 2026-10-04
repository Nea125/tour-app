import 'package:travel_app/features/booking/domain/entities/payment_eligibility.dart';
import 'package:travel_app/features/booking/domain/entities/booking.dart';

import '../../../../core/utils/result.dart';


abstract class BookingRepository {
  Future<Result<List<Booking>>> getBookingsForUser(String userId);
  Future<Result<List<Booking>>> getAllBookings({BookingStatus? status});
  Future<Result<Booking>> getBookingById(String id);
  Future<Result<Booking>> createBooking({
    required String userId,
    required String tourScheduleId,
    required int numberOfPeople,
    String specialRequest,
  });
  Future<Result<Booking>> updateBookingStatus(String id, BookingStatus status);

  /// Pays a pending booking; a successful payment confirms it.
  Future<Result<Booking>> payBooking(String id);

  /// Asks the backend whether a booking can be paid right now (still
  /// pending, not already paid, schedule open, tour not started, seats left).
  Future<Result<PaymentEligibility>> canPayBooking(String id);
}