import '../../../../core/network/api_json.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_status.dart';

class TourModel extends Tour {
  const TourModel({
    required super.id,
    required super.destinationId,
    required super.title,
    required super.description,
    required super.durationDays,
    required super.durationNights,
    required super.maxParticipants,
    required super.price,
    required super.status,
    required super.images,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TourModel.fromJson(Map<String, dynamic> json) {
    return TourModel(
      id: json['id'] as String,
      destinationId: json['destinationId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      durationDays: json['durationDays'] as int,
      durationNights: json['durationNights'] as int,
      maxParticipants: json['maxParticipants'] as int,
      price: (json['price'] as num).toDouble(),
      status: TourStatusX.fromString(json['status'] as String),
      images: List<String>.from(json['images'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// From the backend's `TourResponse`, which has no status or
  /// timestamps; a soft-deleted tour is shown as inactive.
  factory TourModel.fromApi(Map<String, dynamic> json) {
    final id = ApiJson.id(json['id']);
    final now = DateTime.now();
    return TourModel(
      id: id,
      destinationId: ApiJson.id(json['destinationId']),
      title: ApiJson.string(json['title']),
      description: ApiJson.string(json['description']),
      durationDays: ApiJson.integer(json['durationDays']),
      durationNights: ApiJson.integer(json['durationNights']),
      maxParticipants: ApiJson.integer(json['maxParticipants']),
      price: ApiJson.decimal(json['price']),
      status: ApiJson.flag(json, 'deleted')
          ? TourStatus.inactive
          : TourStatus.active,
      images: [
        for (final imageId in json['imageIds'] as List? ?? const [])
          ApiJson.mediaUrl('tours', id, imageId),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory TourModel.fromEntity(Tour t) {
    return TourModel(
      id: t.id,
      destinationId: t.destinationId,
      title: t.title,
      description: t.description,
      durationDays: t.durationDays,
      durationNights: t.durationNights,
      maxParticipants: t.maxParticipants,
      price: t.price,
      status: t.status,
      images: t.images,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destinationId': destinationId,
      'title': title,
      'description': description,
      'durationDays': durationDays,
      'durationNights': durationNights,
      'maxParticipants': maxParticipants,
      'price': price,
      'status': status.name,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
