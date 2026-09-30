import '../../../../core/utils/result.dart';
import '../entities/booking.dart';

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
}
