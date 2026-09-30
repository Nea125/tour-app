import '../../../../core/utils/result.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/entities/itinerary_activity.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../datasources/itinerary_remote_datasource.dart';

class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryRemoteDataSource dataSource;
  ItineraryRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Itinerary>>> getItineraryByTourId(String tourId) =>
      guardResult(() => dataSource.getItineraryByTourId(tourId));

  @override
  Future<Result<Itinerary>> addDay(Itinerary day) =>
      guardResult(() => dataSource.addDay(day));

  @override
  Future<Result<Itinerary>> updateDay(Itinerary day) =>
      guardResult(() => dataSource.updateDay(day));

  @override
  Future<Result<void>> deleteDay(String id) =>
      guardResult(() => dataSource.deleteDay(id));

  @override
  Future<Result<List<ItineraryActivity>>> getActivities(String itineraryId) =>
      guardResult(() => dataSource.getActivities(itineraryId));

  @override
  Future<Result<ItineraryActivity>> addActivity(ItineraryActivity activity) =>
      guardResult(() => dataSource.addActivity(activity));

  @override
  Future<Result<ItineraryActivity>> updateActivity(
    ItineraryActivity activity,
  ) => guardResult(() => dataSource.updateActivity(activity));

  @override
  Future<Result<void>> deleteActivity(String id) =>
      guardResult(() => dataSource.deleteActivity(id));

  @override
  Future<Result<void>> reorderActivities(
    String itineraryId,
    List<String> orderedActivityIds,
  ) => guardResult(
    () => dataSource.reorderActivities(itineraryId, orderedActivityIds),
  );
}
