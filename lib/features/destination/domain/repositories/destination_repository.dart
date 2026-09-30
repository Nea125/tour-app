import '../../../../core/utils/result.dart';
import '../entities/destination.dart';
import '../entities/destination_status.dart';

abstract class DestinationRepository {
  Future<Result<List<Destination>>> getDestinations({String? query});
  Future<Result<Destination>> getDestinationById(String id);
  Future<Result<Destination>> createDestination(Destination destination);
  Future<Result<Destination>> updateDestination(Destination destination);
  Future<Result<void>> deleteDestination(String id);
  Future<Result<Destination>> setStatus(String id, DestinationStatus status);
}
