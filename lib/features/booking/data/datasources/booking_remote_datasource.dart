
import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/entities/payment_eligibility.dart';
import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';

/// `/bookings` and `/payments` endpoints of the tour-management API.
class BookingRemoteDataSource {
  static const String _BOOKINGS = "/bookings";
  static const String _MY_BOOKINGS = "/bookings/my";
  static const String _BY_SCHEDULE = "/bookings/schedule";
  static const String _BY_STATUS = "/bookings/status";
  static const String _CANCEL = "/cancel";
  static const String _PAYMENTS = "/payments";

  final BaseApiService api;
  BookingRemoteDataSource(this.api);

  static List<BookingModel> _newestFirst(List<BookingModel> list) =>
      list..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

  Future<List<BookingModel>> getMyBookings() {
    return api.onRequest(
      path: _MY_BOOKINGS,
      method: HTTPMethod.GET,
      onSuccess: (r) => _newestFirst(
        BaseApiService.listOf(r).map(BookingModel.fromApi).toList(),
      ),
    );
  }


  Future<List<BookingModel>> getBookingsBySchedule(String scheduleId) {
    return api.onRequest(
      path: '$_BY_SCHEDULE/$scheduleId',
      method: HTTPMethod.GET,
      onSuccess: (r) => _newestFirst(
        BaseApiService.listOf(r).map(BookingModel.fromApi).toList(),
      ),
    );
  }

  /// Admin / manager only (enforced by the backend).
  /// With a [status] it uses `GET /bookings/status/{STATUS}`,
  /// otherwise `GET /bookings`.
  Future<List<BookingModel>> getAllBookings({BookingStatus? status}) async {
    final path = status == null
        ? _BOOKINGS
        : '$_BY_STATUS/${status.name.toUpperCase()}';

    final all = await api.getAllPages(
      path: path,
      fromJson: BookingModel.fromApi,
    );
    return _newestFirst(all);
  }

  /// `GET /bookings/{id}`. Admin / manager can read any booking; other
  /// users only their own (enforced by the backend).
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

  /// `GET /payments/booking/{id}/can-pay`.
  Future<PaymentEligibility> canPayBooking(String id) {
    return api.onRequest(
      path: '$_PAYMENTS/booking/$id/can-pay',
      method: HTTPMethod.GET,
      onSuccess: (r) {
        final data = BaseApiService.dataOf(r);
        return PaymentEligibility(
          canPay: data['canPay'] == true,
          message: (data['message'] ?? '').toString(),
        );
      },
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