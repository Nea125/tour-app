// ignore_for_file: constant_identifier_names

import '../../../../core/network/api_json.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../domain/entities/report_summary.dart';

/// `/reports` endpoints of the tour-management API.
///
/// GET /reports/summary            -> ReportResponse
/// GET /reports/bookings/status    -> [BookingStatusReportResponse]
/// GET /reports/tours/top?limit=   -> [TopTourResponse]
/// GET /reports/destinations/top   -> [TopDestinationResponse]
///
/// The backend has no monthly-revenue endpoint, so that one chart is still
/// built from `/bookings` (PAID bookings only).
class ReportRemoteDataSource {
  static const String _REPORTS = "/reports";
  static const String _SUMMARY = "$_REPORTS/summary";
  static const String _BOOKINGS_BY_STATUS = "$_REPORTS/bookings/status";
  static const String _TOP_TOURS = "$_REPORTS/tours/top";
  static const String _TOP_DESTINATIONS = "$_REPORTS/destinations/top";
  static const String _BOOKINGS = "/bookings";
  static const int _topLimit = 5;

  final BaseApiService api;
  ReportRemoteDataSource(this.api);

  Future<ReportSummary> getReportSummary() async {
    final results = await Future.wait<Object>([
      _summary(),
      _bookingsByStatus(),
      _topTours(),
      _topDestinations(),
      _monthlyRevenue(),
    ]);

    final report = results[0] as Map<String, dynamic>;

    return ReportSummary(
      totalRevenue: ApiJson.decimal(report['totalRevenue']),
      totalBookings: ApiJson.integer(report['totalBooking']),
      totalCustomers: ApiJson.integer(report['totalCustomer']),
      totalTours: ApiJson.integer(report['totalTour']),
      totalDestinations: ApiJson.integer(report['totalDestination']),
      totalGuides: ApiJson.integer(report['totalGuide']),
      upcomingTours: ApiJson.integer(report['upcomingTour']),
      completedTours: ApiJson.integer(report['completedTour']),
      cancelledBookings: ApiJson.integer(report['cancelledBooking']),
      averageRating: double.parse(
        ApiJson.decimal(report['averageRating']).toStringAsFixed(1),
      ),
      bookingsByStatus: results[1] as Map<BookingStatus, int>,
      topTours: results[2] as List<TourPerformance>,
      topDestinations: results[3] as List<DestinationPerformance>,
      monthlyRevenue: results[4] as List<MonthlyRevenue>,
    );
  }

  Future<Map<String, dynamic>> _summary() {
    return api.onRequest(
      path: _SUMMARY,
      method: HTTPMethod.GET,
      onSuccess: BaseApiService.dataOf,
    );
  }

  /// Backend returns only statuses that have bookings; fill the rest with 0
  /// so every status still shows on the dashboard.
  Future<Map<BookingStatus, int>> _bookingsByStatus() {
    return api.onRequest(
      path: _BOOKINGS_BY_STATUS,
      method: HTTPMethod.GET,
      onSuccess: (r) {
        final counts = {for (final s in BookingStatus.values) s: 0};
        for (final row in BaseApiService.listOf(r)) {
          final status = BookingStatusX.fromString(
            ApiJson.enumName(row['status']),
          );
          counts[status] = counts[status]! + ApiJson.integer(row['total']);
        }
        return counts;
      },
    );
  }

  Future<List<TourPerformance>> _topTours() {
    return api.onRequest(
      path: '$_TOP_TOURS?limit=$_topLimit',
      method: HTTPMethod.GET,
      onSuccess: (r) => [
        for (final t in BaseApiService.listOf(r))
          TourPerformance(
            tourId: ApiJson.id(t['id']),
            title: ApiJson.string(t['title']),
            bookings: ApiJson.integer(t['bookings']),
            revenue: ApiJson.decimal(t['revenue']),
            rating: double.parse(
              ApiJson.decimal(t['rating']).toStringAsFixed(1),
            ),
          ),
      ],
    );
  }

  Future<List<DestinationPerformance>> _topDestinations() {
    return api.onRequest(
      path: '$_TOP_DESTINATIONS?limit=$_topLimit',
      method: HTTPMethod.GET,
      onSuccess: (r) => [
        for (final d in BaseApiService.listOf(r))
          DestinationPerformance(
            destinationId: ApiJson.id(d['id']),
            name: ApiJson.string(d['name']),
            bookings: ApiJson.integer(d['bookings']),
          ),
      ],
    );
  }

  /// Revenue of PAID bookings for the last 6 months (oldest first).
  Future<List<MonthlyRevenue>> _monthlyRevenue() async {
    final bookings = await api.getAllPages(
      path: _BOOKINGS,
      fromJson: (json) => json,
    );
    final paid = bookings.where(
      (b) =>
          BookingStatusX.fromString(ApiJson.enumName(b['status'])) ==
          BookingStatus.paid,
    );

    final now = DateTime.now();
    return [
      for (var i = 5; i >= 0; i--)
        () {
          final month = DateTime(now.year, now.month - i);
          final next = DateTime(now.year, now.month - i + 1);
          final revenue = paid
              .where((b) {
                final date = ApiJson.date(b['bookingDate']);
                return !date.isBefore(month) && date.isBefore(next);
              })
              .fold<double>(0, (sum, b) => sum + ApiJson.decimal(b['totalPrice']));
          return MonthlyRevenue(
            label: _months[month.month - 1],
            revenue: revenue,
          );
        }(),
    ];
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}