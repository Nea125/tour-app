import 'package:equatable/equatable.dart';
import '../../../booking/domain/entities/booking.dart';

class MonthlyRevenue extends Equatable {
  final String label;
  final double revenue;
  const MonthlyRevenue({required this.label, required this.revenue});

  @override
  List<Object?> get props => [label, revenue];
}

class TourPerformance extends Equatable {
  final String tourId;
  final String title;
  final int bookings;
  final double revenue;
  final double rating;

  const TourPerformance({
    required this.tourId,
    required this.title,
    required this.bookings,
    required this.revenue,
    required this.rating,
  });

  @override
  List<Object?> get props => [tourId, title, bookings, revenue, rating];
}

class DestinationPerformance extends Equatable {
  final String destinationId;
  final String name;
  final int bookings;

  const DestinationPerformance({
    required this.destinationId,
    required this.name,
    required this.bookings,
  });

  @override
  List<Object?> get props => [destinationId, name, bookings];
}

class ReportSummary extends Equatable {
  final double totalRevenue;
  final int totalBookings;
  final int totalCustomers;
  final int totalTours;
  final int totalDestinations;
  final int totalGuides;
  final int upcomingTours;
  final int completedTours;
  final int cancelledBookings;
  final double averageRating;
  final Map<BookingStatus, int> bookingsByStatus;
  final List<MonthlyRevenue> monthlyRevenue;
  final List<TourPerformance> topTours;
  final List<DestinationPerformance> topDestinations;

  const ReportSummary({
    required this.totalRevenue,
    required this.totalBookings,
    required this.totalCustomers,
    required this.totalTours,
    required this.totalDestinations,
    required this.totalGuides,
    required this.upcomingTours,
    required this.completedTours,
    required this.cancelledBookings,
    required this.averageRating,
    required this.bookingsByStatus,
    required this.monthlyRevenue,
    required this.topTours,
    required this.topDestinations,
  });

  @override
  List<Object?> get props => [
    totalRevenue,
    totalBookings,
    totalCustomers,
    totalTours,
    totalDestinations,
    totalGuides,
    upcomingTours,
    completedTours,
    cancelledBookings,
    averageRating,
    bookingsByStatus,
    monthlyRevenue,
    topTours,
    topDestinations,
  ];
}
