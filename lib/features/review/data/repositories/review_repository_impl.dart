import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource dataSource;
  ReviewRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Review>>> getReviewsByTourId(String tourId) =>
      guardResult(() => dataSource.getReviewsByTourId(tourId));

  /// The API derives the user from the access token, so [userId] must be
  /// the current user.
  @override
  Future<Result<List<Review>>> getReviewsByUserId(String userId) =>
      guardResult(dataSource.getMyReviews);

  @override
  Future<Result<Review>> addReview({
    required String userId,
    required String tourId,
    required String bookingId,
    required int rating,
    required String comment,
  }) => guardResult(
    () => dataSource.addReview(
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    ),
  );

  @override
  Future<Result<Review>> updateReview({
    required String id,
    int? rating,
    String? comment,
  }) async {
    return const Error(
      ValidationFailure('Editing reviews is not supported yet'),
    );
  }

  @override
  Future<Result<void>> deleteReview(String id) =>
      guardResult(() => dataSource.deleteReview(id));

  /// No report endpoint exists; this only checks the review still exists.
  @override
  Future<Result<void>> reportReview({
    required String id,
    required String reporterUserId,
    required String reason,
  }) => guardResult(() => dataSource.getReviewById(id));
}
