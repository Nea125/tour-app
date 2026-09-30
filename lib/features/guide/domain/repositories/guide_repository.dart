import '../../../../core/utils/result.dart';
import '../entities/guide_status.dart';
import '../entities/tour_guide.dart';

abstract class GuideRepository {
  Future<Result<List<TourGuide>>> getGuides({String? query});
  Future<Result<TourGuide>> getGuideById(String id);
  Future<Result<TourGuide?>> getGuideByUserId(String userId);
  Future<Result<TourGuide>> createGuide(TourGuide guide);
  Future<Result<TourGuide>> updateGuide(TourGuide guide);
  Future<Result<void>> deleteGuide(String id);
  Future<Result<TourGuide>> setStatus(String id, GuideStatus status);
}
