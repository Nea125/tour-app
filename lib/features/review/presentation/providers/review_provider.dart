import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/network/base_api_service.dart';
import '../../data/datasources/review_remote_datasource.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';

final reviewRemoteDataSourceProvider = Provider<ReviewRemoteDataSource>(
  (ref) => ReviewRemoteDataSource(ref.watch(baseApiServiceProvider)),
);

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.watch(reviewRemoteDataSourceProvider));
});

final reviewsByTourProvider = FutureProvider.family<List<Review>, String>((
  ref,
  tourId,
) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final result = await repo.getReviewsByTourId(tourId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

/// Average rating for a tour, computed from its reviews since `tours`
/// has no cached rating column.
final averageRatingForTourProvider = FutureProvider.family<double, String>((
  ref,
  tourId,
) async {
  final reviews = await ref.watch(reviewsByTourProvider(tourId).future);
  if (reviews.isEmpty) return 0;
  return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
});

class MyReviewsController extends AsyncNotifier<List<Review>> {
  @override
  Future<List<Review>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final repo = ref.watch(reviewRepositoryProvider);
    final result = await repo.getReviewsByUserId(user.id);
    return result.when(success: (data) => data, failure: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<String?> addReview({
    required String tourId,
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 'You must be signed in to review';
    final repo = ref.read(reviewRepositoryProvider);
    final result = await repo.addReview(
      userId: user.id,
      tourId: tourId,
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );
    return result.when(
      success: (_) {
        refresh();
        ref.invalidate(reviewsByTourProvider);
        ref.invalidate(averageRatingForTourProvider);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> updateReview({
    required String id,
    int? rating,
    String? comment,
  }) async {
    final repo = ref.read(reviewRepositoryProvider);
    final result = await repo.updateReview(
      id: id,
      rating: rating,
      comment: comment,
    );
    return result.when(
      success: (_) {
        refresh();
        ref.invalidate(reviewsByTourProvider);
        ref.invalidate(averageRatingForTourProvider);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> reportReview({
    required String reviewId,
    required String reason,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 'You must be signed in to report a review';
    final repo = ref.read(reviewRepositoryProvider);
    final result = await repo.reportReview(
      id: reviewId,
      reporterUserId: user.id,
      reason: reason,
    );
    return result.when(success: (_) => null, failure: (f) => f.message);
  }
}

final myReviewsControllerProvider =
    AsyncNotifierProvider<MyReviewsController, List<Review>>(
      MyReviewsController.new,
    );

class AdminReviewController extends Notifier<void> {
  @override
  void build() {}

  Future<String?> deleteReview(String id) async {
    final repo = ref.read(reviewRepositoryProvider);
    final result = await repo.deleteReview(id);
    return result.when(
      success: (_) {
        ref.invalidate(reviewsByTourProvider);
        ref.invalidate(averageRatingForTourProvider);
        return null;
      },
      failure: (f) => f.message,
    );
  }
}

final adminReviewControllerProvider =
    NotifierProvider<AdminReviewController, void>(AdminReviewController.new);
