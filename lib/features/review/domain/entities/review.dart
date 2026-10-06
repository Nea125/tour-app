import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String userId;
  final String tourId;
  final String bookingId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Review({
    required this.id,
    required this.userId,
    required this.tourId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  Review copyWith({
    String? id,
    String? userId,
    String? tourId,
    String? bookingId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tourId: tourId ?? this.tourId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    tourId,
    bookingId,
    rating,
    comment,
    createdAt,
    updatedAt,
  ];
}
