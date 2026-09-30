import '../../../../core/utils/result.dart';
import '../entities/booking_participant.dart';

abstract class ParticipantRepository {
  Future<Result<List<BookingParticipant>>> getParticipantsByBookingId(
    String bookingId,
  );
  Future<Result<BookingParticipant>> addParticipant(
    BookingParticipant participant,
  );
  Future<Result<BookingParticipant>> updateParticipant(
    BookingParticipant participant,
  );
  Future<Result<void>> removeParticipant(String id);

  /// Eligibility for a booking is met once the number of registered
  /// participants matches the booking's declared `numberOfPeople`.
  /// Returns null when eligible, otherwise a human-readable reason.
  Future<Result<String?>> checkEligibility(String bookingId);
}
