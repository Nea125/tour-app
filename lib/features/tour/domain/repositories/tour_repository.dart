import '../../../../core/utils/result.dart';
import '../entities/tour.dart';
import '../entities/tour_status.dart';

abstract class TourRepository {
  Future<Result<List<Tour>>> getTours({String? destinationId, String? query});
  Future<Result<Tour>> getTourById(String id);
  Future<Result<Tour>> createTour(Tour tour);
  Future<Result<Tour>> updateTour(Tour tour);
  Future<Result<void>> deleteTour(String id);
  Future<Result<Tour>> setStatus(String id, TourStatus status);
}
