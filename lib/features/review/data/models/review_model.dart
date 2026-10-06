import '../../../../core/network/api_json.dart';
import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.userId,
    required super.tourId,
    required super.bookingId,
    required super.rating,
    required super.comment,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tourId: json['tourId'] as String,
      bookingId: json['bookingId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// From the backend's `ReviewResponse` (no timestamps).
  factory ReviewModel.fromApi(Map<String, dynamic> json) {
    return ReviewModel(
      id: ApiJson.id(json['id']),
      userId: ApiJson.id(json['userId']),
      tourId: ApiJson.id(json['tourId']),
      bookingId: ApiJson.id(json['bookingId']),
      rating: ApiJson.integer(json['rating']),
      comment: ApiJson.string(json['comment']),
      createdAt: json['createdAt'] != null
          ? ApiJson.localDateTime(json['createdAt'])!
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? ApiJson.localDateTime(json['updatedAt'])
          : null,
    );
  }

  factory ReviewModel.fromEntity(Review r) {
    return ReviewModel(
      id: r.id,
      userId: r.userId,
      tourId: r.tourId,
      bookingId: r.bookingId,
      rating: r.rating,
      comment: r.comment,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tourId': tourId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
