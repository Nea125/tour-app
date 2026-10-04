import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/network/base_api_service.dart';
import '../../data/datasources/participant_remote_datasource.dart';
import '../../data/repositories/participant_repository_impl.dart';
import '../../domain/entities/booking_participant.dart';
import '../../domain/repositories/participant_repository.dart';

final participantRemoteDataSourceProvider =
    Provider<ParticipantRemoteDataSource>(
      (ref) => ParticipantRemoteDataSource(ref.watch(baseApiServiceProvider)),
    );

final participantRepositoryProvider = Provider<ParticipantRepository>((ref) {
  return ParticipantRepositoryImpl(
    ref.watch(participantRemoteDataSourceProvider),
  );
});

final participantsByBookingProvider =
    FutureProvider.family<List<BookingParticipant>, String>((
      ref,
      bookingId,
    ) async {
      final repo = ref.watch(participantRepositoryProvider);
      final result = await repo.getParticipantsByBookingId(bookingId);
      return result.when(success: (data) => data, failure: (f) => throw f);
    });

final bookingEligibilityProvider = FutureProvider.family<String?, String>((
  ref,
  bookingId,
) async {
  final repo = ref.watch(participantRepositoryProvider);
  final result = await repo.checkEligibility(bookingId);
  return result.when(success: (msg) => msg, failure: (f) => f.message);
});

class ParticipantController extends Notifier<void> {
  @override
  void build() {}

  void _invalidate(String bookingId) {
    ref.invalidate(participantsByBookingProvider(bookingId));
    ref.invalidate(bookingEligibilityProvider(bookingId));
  }

  Future<String?> addParticipant(BookingParticipant participant) async {
    final repo = ref.read(participantRepositoryProvider);
    final result = await repo.addParticipant(participant);
    return result.when(
      success: (_) {
        _invalidate(participant.bookingId);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  /// Registers the signed-in purchaser as a traveler on [bookingId], using
  /// their profile details, so a solo booking needs no participant form.
  Future<String?> addPurchaser(String bookingId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 'You must be signed in';
    return addParticipant(
      BookingParticipant(
        id: '',
        bookingId: bookingId,
        fullName: user.fullName.trim(),
        gender: user.gender,
        dateOfBirth: user.dateOfBirth,
        phone: user.phone,
        email: user.email,
      ),
    );
  }

  Future<String?> updateParticipant(BookingParticipant participant) async {
    final repo = ref.read(participantRepositoryProvider);
    final result = await repo.updateParticipant(participant);
    return result.when(
      success: (_) {
        _invalidate(participant.bookingId);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> removeParticipant(String id, String bookingId) async {
    final repo = ref.read(participantRepositoryProvider);
    final result = await repo.removeParticipant(id);
    return result.when(
      success: (_) {
        _invalidate(bookingId);
        return null;
      },
      failure: (f) => f.message,
    );
  }
}

final participantControllerProvider =
    NotifierProvider<ParticipantController, void>(ParticipantController.new);