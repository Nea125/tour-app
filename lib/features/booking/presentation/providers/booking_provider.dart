import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/features/booking/data/repositories/booking_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/utils/result.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/payment_eligibility.dart';
import '../../domain/entities/booking.dart';


final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>(
  (ref) => BookingRemoteDataSource(ref.watch(baseApiServiceProvider)),
);

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(ref.watch(bookingRemoteDataSourceProvider));
});

/// True only for ADMIN and MANAGER users.
final canManageBookingsProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserProvider)?.role;
  return role == UserRole.ADMIN || role == UserRole.MANAGER;
});

/// ADMIN, MANAGER and GUIDE may see a schedule's bookings and participants.
final canViewScheduleBookingsProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserProvider)?.role;
  return role == UserRole.ADMIN ||
      role == UserRole.MANAGER ||
      role == UserRole.GUIDE;
});

final bookingStatusFilterProvider = StateProvider<BookingStatus?>(
  (ref) => null,
);

/// Search text typed by an admin / manager (booking ID or booking code).
final bookingSearchQueryProvider = StateProvider<String>((ref) => '');

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

/// Admin / manager list of bookings with status filter and search.
class AllBookingsController extends AsyncNotifier<List<Booking>> {
  static final RegExp _numeric = RegExp(r'^\d+$');

  @override
  Future<List<Booking>> build() async {
    // Only admin / manager may load all bookings.
    if (!ref.watch(canManageBookingsProvider)) {
      throw const ValidationFailure(
        'You do not have permission to view bookings',
      );
    }

    final status = ref.watch(bookingStatusFilterProvider);
    final query = ref.watch(bookingSearchQueryProvider).trim();
    final repo = ref.watch(bookingRepositoryProvider);

    // Numeric query -> search by ID on the server (GET /bookings/{id}).
    if (_numeric.hasMatch(query)) {
      final result = await repo.getBookingById(query);
      return result.when(
        success: (b) =>
            (status == null || b.status == status) ? <Booking>[b] : <Booking>[],
        // Not found -> empty list; any other error (403, network...) is shown.
        failure: (f) => f.message.toLowerCase().contains('not found')
            ? <Booking>[]
            : throw f,
      );
    }

    // Otherwise load by status (server-side) and match the booking code.
    final result = await repo.getAllBookings(status: status);
    final list = result.when(success: (d) => d, failure: (f) => throw f);

    if (query.isEmpty) return list;
    final q = query.toLowerCase();
    return list
        .where((b) => b.bookingCode.toLowerCase().contains(q))
        .toList();
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

/// Bookings of one schedule (admin / manager / guide only).
final bookingsByScheduleProvider = FutureProvider.autoDispose
    .family<List<Booking>, String>((ref, scheduleId) async {
      if (!ref.watch(canViewScheduleBookingsProvider)) {
        throw const ValidationFailure(
          'You do not have permission to view these bookings',
        );
      }
      final repo = ref.watch(bookingRepositoryProvider);
      final result = await repo.getBookingsBySchedule(scheduleId);
      return result.when(success: (b) => b, failure: (f) => throw f);
    });

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