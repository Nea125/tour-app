import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_status.dart';
import '../../domain/repositories/tour_repository.dart';
import '../datasources/tour_remote_datasource.dart';

class TourRepositoryImpl implements TourRepository {
  final TourRemoteDataSource dataSource;
  TourRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Tour>>> getTours({String? destinationId, String? query}) =>
      guardResult(
        () => dataSource.getTours(destinationId: destinationId, query: query),
      );

  @override
  Future<Result<Tour>> getTourById(String id) =>
      guardResult(() => dataSource.getTourById(id));

  @override
  Future<Result<Tour>> createTour(Tour tour) =>
      guardResult(() => dataSource.createTour(tour));

  @override
  Future<Result<Tour>> updateTour(Tour tour) =>
      guardResult(() => dataSource.updateTour(tour));

  @override
  Future<Result<void>> deleteTour(String id) =>
      guardResult(() => dataSource.deleteTour(id));

  @override
  Future<Result<Tour>> setStatus(String id, TourStatus status) async {
    // TourResponse/UpdateTourRequest carry no status field.
    return const Error(
      ValidationFailure('Changing tour status is not supported yet'),
    );
  }
}
