// ignore_for_file: constant_identifier_names

import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';

/// `/bookings` and `/payments` endpoints of the tour-management API.
class BookingRemoteDataSource {
  static const String _BOOKINGS = "/bookings";
  static const String _MY_BOOKINGS = "/bookings/my";
  static const String _CANCEL = "/cancel";
  static const String _PAYMENTS = "/payments";

  final BaseApiService api;
  BookingRemoteDataSource(this.api);

  static List<BookingModel> _newestFirst(List<BookingModel> list) =>
      list..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

  /// `/bookings/my` resolves the user from the access token.
  Future<List<BookingModel>> getMyBookings() {
    return api.onRequest(
      path: _MY_BOOKINGS,
      method: HTTPMethod.GET,
      onSuccess: (r) => _newestFirst(
        BaseApiService.listOf(r).map(BookingModel.fromApi).toList(),
      ),
    );
  }

  Future<List<BookingModel>> getAllBookings({BookingStatus? status}) async {
    final all = await api.getAllPages(
      path: _BOOKINGS,
      fromJson: BookingModel.fromApi,
    );
    return _newestFirst(
      status == null ? all : all.where((b) => b.status == status).toList(),
    );
  }

  Future<BookingModel> getBookingById(String id) {
    return api.onRequest(
      path: '$_BOOKINGS/$id',
      method: HTTPMethod.GET,
      onSuccess: (r) => BookingModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<BookingModel> createBooking({
    required String tourScheduleId,
    required int numberOfPeople,
  }) {
    return api.onRequest(
      path: _BOOKINGS,
      method: HTTPMethod.POST,
      data: {
        'scheduleId': int.parse(tourScheduleId),
        'numberOfPeople': numberOfPeople,
      },
      onSuccess: (r) => BookingModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<BookingModel> cancelBooking(String id) {
    return api.onRequest(
      path: '$_BOOKINGS/$id$_CANCEL',
      method: HTTPMethod.PATCH,
      onSuccess: (r) => BookingModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  /// Paying a PENDING booking confirms it on the backend right away; no
  /// admin approval is involved.
  Future<BookingModel> payBooking(String id) async {
    await api.onRequest(
      path: _PAYMENTS,
      method: HTTPMethod.POST,
      data: {'bookingId': int.parse(id)},
      onSuccess: (_) {},
    );
    return getBookingById(id);
  }
}
