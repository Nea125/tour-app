import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/guide_status.dart';
import '../../domain/entities/tour_guide.dart';
import '../../domain/repositories/guide_repository.dart';
import '../datasources/guide_remote_datasource.dart';

class GuideRepositoryImpl implements GuideRepository {
  final GuideRemoteDataSource dataSource;
  GuideRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<TourGuide>>> getGuides({String? query}) =>
      guardResult(() => dataSource.getGuides(query: query));

  @override
  Future<Result<TourGuide>> getGuideById(String id) =>
      guardResult(() => dataSource.getGuideById(id));

  @override
  Future<Result<TourGuide?>> getGuideByUserId(String userId) =>
      guardResult(() => dataSource.getGuideByUserId(userId));

  @override
  Future<Result<TourGuide>> createGuide(TourGuide guide) =>
      guardResult(() => dataSource.createGuide(guide));

  @override
  Future<Result<TourGuide>> updateGuide(TourGuide guide) =>
      guardResult(() => dataSource.updateGuide(guide));

  @override
  Future<Result<void>> deleteGuide(String id) =>
      guardResult(() => dataSource.deleteGuide(id));

  @override
  Future<Result<TourGuide>> setStatus(String id, GuideStatus status) async {
    // PatchTourGuideRequest has no status; it can only be set on create.
    return const Error(
      ValidationFailure('Changing guide status is not supported yet'),
    );
  }
}
