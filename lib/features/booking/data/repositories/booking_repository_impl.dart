import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/payment_eligibility.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource dataSource;
  BookingRepositoryImpl(this.dataSource);

  /// The API only returns the signed-in user's bookings, so [userId] must
  /// be the current user.
  @override
  Future<Result<List<Booking>>> getBookingsForUser(String userId) =>
      guardResult(dataSource.getMyBookings);

  @override
  Future<Result<List<Booking>>> getAllBookings({BookingStatus? status}) =>
      guardResult(() => dataSource.getAllBookings(status: status));

  @override
  Future<Result<Booking>> getBookingById(String id) =>
      guardResult(() => dataSource.getBookingById(id));

  /// The user comes from the access token; the API has no field for a
  /// special request, so it isn't sent.
  @override
  Future<Result<Booking>> createBooking({
    required String userId,
    required String tourScheduleId,
    required int numberOfPeople,
  }) => guardResult(
    () => dataSource.createBooking(
      tourScheduleId: tourScheduleId,
      numberOfPeople: numberOfPeople,
    ),
  );

  @override
  Future<Result<Booking>> updateBookingStatus(
    String id,
    BookingStatus status,
  ) async {
    switch (status) {
      case BookingStatus.cancelled:
        return guardResult(() => dataSource.cancelBooking(id));
      case BookingStatus.paid:
        return const Error(
          ValidationFailure('Bookings are confirmed automatically by payment'),
        );
      case BookingStatus.pending:
        return const Error(
          ValidationFailure('Bookings cannot be reverted to pending'),
        );
    }
  }

  @override
  Future<Result<Booking>> payBooking(String id) =>
      guardResult(() => dataSource.payBooking(id));

  @override
  Future<Result<PaymentEligibility>> canPayBooking(String id) =>
      guardResult(() => dataSource.canPayBooking(id));
}