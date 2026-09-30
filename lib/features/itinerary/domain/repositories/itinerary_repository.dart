import '../../../../core/utils/result.dart';
import '../entities/itinerary.dart';
import '../entities/itinerary_activity.dart';

abstract class ItineraryRepository {
  Future<Result<List<Itinerary>>> getItineraryByTourId(String tourId);
  Future<Result<Itinerary>> addDay(Itinerary day);
  Future<Result<Itinerary>> updateDay(Itinerary day);
  Future<Result<void>> deleteDay(String id);

  Future<Result<List<ItineraryActivity>>> getActivities(String itineraryId);
  Future<Result<ItineraryActivity>> addActivity(ItineraryActivity activity);
  Future<Result<ItineraryActivity>> updateActivity(ItineraryActivity activity);
  Future<Result<void>> deleteActivity(String id);
  Future<Result<void>> reorderActivities(
    String itineraryId,
    List<String> orderedActivityIds,
  );
}
