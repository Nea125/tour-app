import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_status.dart';
import '../../domain/repositories/destination_repository.dart';
import '../datasources/destination_remote_datasource.dart';

class DestinationRepositoryImpl implements DestinationRepository {
  final DestinationRemoteDataSource dataSource;
  DestinationRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Destination>>> getDestinations({String? query}) =>
      guardResult(() => dataSource.getDestinations(query: query));

  @override
  Future<Result<Destination>> getDestinationById(String id) =>
      guardResult(() => dataSource.getDestinationById(id));

  @override
  Future<Result<Destination>> createDestination(Destination destination) =>
      guardResult(() => dataSource.createDestination(destination));

  @override
  Future<Result<Destination>> updateDestination(Destination destination) =>
      guardResult(() => dataSource.updateDestination(destination));

  @override
  Future<Result<void>> deleteDestination(String id) =>
      guardResult(() => dataSource.deleteDestination(id));

  @override
  Future<Result<Destination>> setStatus(
    String id,
    DestinationStatus status,
  ) async {
    // DestinationResponse/UpdateDestinationRequest carry no status field.
    return const Error(
      ValidationFailure('Changing destination status is not supported yet'),
    );
  }
}
