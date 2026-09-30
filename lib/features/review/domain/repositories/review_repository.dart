import '../../../../core/utils/result.dart';
import '../entities/review.dart';

abstract class ReviewRepository {
  Future<Result<List<Review>>> getReviewsByTourId(String tourId);
  Future<Result<List<Review>>> getReviewsByUserId(String userId);
  Future<Result<Review>> addReview({
    required String userId,
    required String tourId,
    required String bookingId,
    required int rating,
    required String comment,
  });
  Future<Result<Review>> updateReview({
    required String id,
    int? rating,
    String? comment,
  });
  Future<Result<void>> deleteReview(String id);


  Future<Result<void>> reportReview({
    required String id,
    required String reporterUserId,
    required String reason,
  });
}
