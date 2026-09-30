
import '../../../../core/network/api_json.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../domain/entities/report_summary.dart';

class ReportRemoteDataSource {
  static const String _REPORTS = "/reports";
  static const String _BOOKINGS = "/bookings";
  static const String _SCHEDULES = "/tour-schedule";
  static const String _TOURS = "/tours";
  static const String _DESTINATIONS = "/destinations";
  static const String _REVIEWS_BY_TOUR = "/reviews/tour";

  final BaseApiService api;
  ReportRemoteDataSource(this.api);

  Future<List<Map<String, dynamic>>> _all(String path) =>
      api.getAllPages(path: path, fromJson: (json) => json);

  Future<ReportSummary> getReportSummary() async {
    final results = await Future.wait([
      api.onRequest(
        path: _REPORTS,
        method: HTTPMethod.GET,
        onSuccess: BaseApiService.dataOf,
      ),
      _all(_BOOKINGS),
      _all(_SCHEDULES),
      _all(_TOURS),
      _all(_DESTINATIONS),
    ]);
    final report = results[0] as Map<String, dynamic>;
    final bookings = results[1] as List<Map<String, dynamic>>;
    final schedules = results[2] as List<Map<String, dynamic>>;
    final tours = results[3] as List<Map<String, dynamic>>;
    final destinations = results[4] as List<Map<String, dynamic>>;

    BookingStatus statusOf(Map<String, dynamic> b) =>
        BookingStatusX.fromString(ApiJson.enumName(b['status']));
    double priceOf(Map<String, dynamic> b) => ApiJson.decimal(b['totalPrice']);

    final tourIdBySchedule = {for (final s in schedules) ApiJson.id(s['id']): ApiJson.id(s['tourId']),
    };
    String? tourIdOf(Map<String, dynamic> b) => tourIdBySchedule[ApiJson.id(b['scheduleId'])];

    final active = bookings
        .where((b) => statusOf(b) != BookingStatus.cancelled)
        .toList();
    final paid = active
        .where((b) => statusOf(b) != BookingStatus.pending)
        .toList();

    final now = DateTime.now();
    final monthlyRevenue = <MonthlyRevenue>[
      for (var i = 5; i >= 0; i--)
        () {
          final month = DateTime(now.year, now.month - i);
          final next = DateTime(now.year, now.month - i + 1);
          final revenue = paid
              .where((b) {
                final date = ApiJson.date(b['bookingDate']);
                return !date.isBefore(month) && date.isBefore(next);
              })
              .fold<double>(0, (sum, b) => sum + priceOf(b));
          return MonthlyRevenue(
            label: _months[month.month - 1],
            revenue: revenue,
          );
        }(),
    ];

    final topTours = [
      for (final tour in tours)
        () {
          final id = ApiJson.id(tour['id']);
          final tourBookings = active.where((b) => tourIdOf(b) == id);
          return TourPerformance(
            tourId: id,
            title: ApiJson.string(tour['title']),
            bookings: tourBookings.length,
            revenue: tourBookings
                .where((b) => statusOf(b) != BookingStatus.pending)
                .fold<double>(0, (sum, b) => sum + priceOf(b)),
            rating: 0,
          );
        }(),
    ]..sort((a, b) => b.revenue.compareTo(a.revenue));
    final top5 = await Future.wait(topTours.take(5).map(_withRating));

    final topDestinations = [
      for (final dest in destinations)
        () {
          final id = ApiJson.id(dest['id']);
          final tourIds = tours
              .where((t) => ApiJson.id(t['destinationId']) == id)
              .map((t) => ApiJson.id(t['id']))
              .toSet();
          return DestinationPerformance(
            destinationId: id,
            name: ApiJson.string(dest['name']),
            bookings: active.where((b) => tourIds.contains(tourIdOf(b))).length,
          );
        }(),
    ]..sort((a, b) => b.bookings.compareTo(a.bookings));

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
      bookingsByStatus: {
        for (final status in BookingStatus.values)
          status: bookings.where((b) => statusOf(b) == status).length,
      },
      monthlyRevenue: monthlyRevenue,
      topTours: top5,
      topDestinations: topDestinations.take(5).toList(),
    );
  }

  Future<TourPerformance> _withRating(TourPerformance tour) async {
    final reviews = await _all('$_REVIEWS_BY_TOUR/${tour.tourId}');
    if (reviews.isEmpty) return tour;
    final average =
        reviews.fold<int>(0, (sum, r) => sum + ApiJson.integer(r['rating'])) /
        reviews.length;
    return TourPerformance(
      tourId: tour.tourId,
      title: tour.title,
      bookings: tour.bookings,
      revenue: tour.revenue,
      rating: double.parse(average.toStringAsFixed(1)),
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
