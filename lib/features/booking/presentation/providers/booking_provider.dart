import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/utils/result.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/payment_eligibility.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>(
  (ref) => BookingRemoteDataSource(ref.watch(baseApiServiceProvider)),
);

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(ref.watch(bookingRemoteDataSourceProvider));
});

final bookingStatusFilterProvider = StateProvider<BookingStatus?>(
  (ref) => null,
);

class MyBookingsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final repo = ref.watch(bookingRepositoryProvider);
    final result = await repo.getBookingsForUser(user.id);
    return result.when(success: (data) => data, failure: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Creates a PENDING booking; it's confirmed once [payBooking] succeeds.
  Future<Result<Booking>> createBooking({
    required String tourScheduleId,
    required int numberOfPeople,
    // String specialRequest = '',
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return const Error(ValidationFailure('You must be signed in to book'));
    }
    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.createBooking(
      userId: user.id,
      tourScheduleId: tourScheduleId,
      numberOfPeople: numberOfPeople,
      // specialRequest: specialRequest,
    );
    if (result.isSuccess) {
      refresh();
      ref.invalidate(allBookingsControllerProvider);
      ref.invalidate(availableSlotsProvider(tourScheduleId));
    }
    return result;
  }

  Future<String?> payBooking(String id) async {
    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.payBooking(id);
    return result.when(
      success: (_) {
        refresh();
        ref.invalidate(allBookingsControllerProvider);
        ref.invalidate(bookingByIdProvider(id));
        ref.invalidate(canPayBookingProvider(id));
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> cancelBooking(String id) async {
    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.updateBookingStatus(id, BookingStatus.cancelled);
    return result.when(
      success: (_) {
        refresh();
        ref.invalidate(allBookingsControllerProvider);
        ref.invalidate(bookingByIdProvider(id));
        ref.invalidate(canPayBookingProvider(id));
        return null;
      },
      failure: (f) => f.message,
    );
  }
}

final myBookingsControllerProvider =
    AsyncNotifierProvider<MyBookingsController, List<Booking>>(
      MyBookingsController.new,
    );

class AllBookingsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final status = ref.watch(bookingStatusFilterProvider);
    final repo = ref.watch(bookingRepositoryProvider);
    final result = await repo.getAllBookings(status: status);
    return result.when(success: (data) => data, failure: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final allBookingsControllerProvider =
    AsyncNotifierProvider<AllBookingsController, List<Booking>>(
      AllBookingsController.new,
    );

final bookingByIdProvider = FutureProvider.family<Booking, String>((
  ref,
  id,
) async {
  final repo = ref.watch(bookingRepositoryProvider);
  final result = await repo.getBookingById(id);
  return result.when(success: (b) => b, failure: (f) => throw f);
});

/// Backend check of whether a booking can be paid right now. Auto-disposed
/// so it is re-checked every time a screen asks again.
final canPayBookingProvider = FutureProvider.autoDispose
    .family<PaymentEligibility, String>((ref, id) async {
      final repo = ref.watch(bookingRepositoryProvider);
      final result = await repo.canPayBooking(id);
      return result.when(success: (r) => r, failure: (f) => throw f);
    });