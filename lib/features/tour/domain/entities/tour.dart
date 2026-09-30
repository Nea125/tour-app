import 'package:equatable/equatable.dart';
import 'tour_status.dart';

class Tour extends Equatable {
  final String id;
  final String destinationId;
  final String title;
  final String description;
  final int durationDays;
  final int durationNights;
  final int maxParticipants;
  final double price;
  final TourStatus status;
  // Not a column on the `tours` table — sourced from an implied tour-media
  // relation (mirrors how `destinations.image_url` works, just 1:many);
  // kept here so "Upload tour images" has somewhere to live.
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tour({
    required this.id,
    required this.destinationId,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.durationNights,
    required this.maxParticipants,
    required this.price,
    required this.status,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  Tour copyWith({
    String? id,
    String? destinationId,
    String? title,
    String? description,
    int? durationDays,
    int? durationNights,
    int? maxParticipants,
    double? price,
    TourStatus? status,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tour(
      id: id ?? this.id,
      destinationId: destinationId ?? this.destinationId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      durationNights: durationNights ?? this.durationNights,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      price: price ?? this.price,
      status: status ?? this.status,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    destinationId,
    title,
    description,
    durationDays,
    durationNights,
    maxParticipants,
    price,
    status,
    images,
    createdAt,
    updatedAt,
  ];
}
