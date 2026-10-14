import 'package:equatable/equatable.dart';
import 'tour.dart';


class PopularTour extends Equatable {
  final Tour tour;
  final double averageRating;
  final int reviewCount;

  const PopularTour({
    required this.tour,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  List<Object?> get props => [tour, averageRating, reviewCount];
}