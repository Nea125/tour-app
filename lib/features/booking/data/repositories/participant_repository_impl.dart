import '../../../../core/utils/result.dart';
import '../../domain/entities/booking_participant.dart';
import '../../domain/repositories/participant_repository.dart';
import '../datasources/participant_remote_datasource.dart';

class ParticipantRepositoryImpl implements ParticipantRepository {
  final ParticipantRemoteDataSource dataSource;
  ParticipantRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<BookingParticipant>>> getParticipantsByBookingId(
    String bookingId,
  ) => guardResult(() => dataSource.getParticipantsByBookingId(bookingId));

  @override
  Future<Result<BookingParticipant>> addParticipant(
    BookingParticipant participant,
  ) => guardResult(() => dataSource.addParticipant(participant));

  @override
  Future<Result<BookingParticipant>> updateParticipant(
    BookingParticipant participant,
  ) => guardResult(() => dataSource.updateParticipant(participant));

  @override
  Future<Result<void>> removeParticipant(String id) =>
      guardResult(() => dataSource.removeParticipant(id));

  @override
  Future<Result<String?>> checkEligibility(String bookingId) =>
      guardResult(() => dataSource.checkEligibility(bookingId));
}
