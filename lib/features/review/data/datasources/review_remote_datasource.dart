// ignore_for_file: constant_identifier_names

import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../../../core/network/dio_exception.dart';
import '../models/review_model.dart';

/// `/reviews` endpoints of the tour-management API.
class ReviewRemoteDataSource {
  static const String _REVIEWS = "/reviews";
  static const String _BY_TOUR = "/reviews/tour";
  static const String _BY_BOOKING = "/reviews/booking";
  static const String _MY_BOOKINGS = "/bookings/my";

  final BaseApiService api;
  ReviewRemoteDataSource(this.api);

  Future<List<ReviewModel>> getReviewsByTourId(String tourId) {
    return api.getAllPages(
      path: '$_BY_TOUR/$tourId',
      fromJson: ReviewModel.fromApi,
    );
  }

  /// There is no "reviews by user" endpoint: look up the review of each of
  /// the signed-in user's reviewable bookings instead.
  Future<List<ReviewModel>> getMyReviews() async {
    final bookings = await api.onRequest(
      path: _MY_BOOKINGS,
      method: HTTPMethod.GET,
      onSuccess: BaseApiService.listOf,
    );
    final reviewable = bookings.where(
      (b) => b['status'] == 'CONFIRMED' || b['status'] == 'COMPLETED',
    );
    final reviews = await Future.wait(
      reviewable.map((b) => getReviewByBookingId(b['id'].toString())),
    );
    return reviews.whereType<ReviewModel>().toList();
  }

  Future<ReviewModel?> getReviewByBookingId(String bookingId) async {
    try {
      return await api.onRequest(
        path: '$_BY_BOOKING/$bookingId',
        method: HTTPMethod.GET,
        // `data: null` means the booking has no review yet.
        onSuccess: (r) => r.data['data'] == null
            ? null
            : ReviewModel.fromApi(BaseApiService.dataOf(r)),
      );
    } on DioErrorHttpException catch (e) {
      if (e.code == 404) return null;
      rethrow;
    }
  }

  Future<ReviewModel> getReviewById(String id) {
    return api.onRequest(
      path: '$_REVIEWS/$id',
      method: HTTPMethod.GET,
      onSuccess: (r) => ReviewModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<ReviewModel> addReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) {
    return api.onRequest(
      path: _REVIEWS,
      method: HTTPMethod.POST,
      data: {
        'bookingId': int.parse(bookingId),
        'rating': rating,
        'comment': comment,
      },
      onSuccess: (r) => ReviewModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<void> deleteReview(String id) {
    return api.onRequest(
      path: '$_REVIEWS/$id',
      method: HTTPMethod.DELETE,
      onSuccess: (_) {},
    );
  }
}
