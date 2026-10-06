// import '../../../../core/network/api_json.dart';
// import '../../domain/entities/destination.dart';
// import '../../domain/entities/destination_status.dart';

// class DestinationModel extends Destination {
//   const DestinationModel({
//     required super.id,
//     required super.name,
//     required super.description,
//     required super.province,
//     required super.country,
//     required super.latitude,
//     required super.longitude,
//     required super.imageUrl,
//     required super.status,
//     required super.createdAt,
//     required super.updatedAt,
//   });

//   factory DestinationModel.fromJson(Map<String, dynamic> json) {
//     return DestinationModel(
//       id: json['id'] as String,
//       name: json['name'] as String,
//       description: json['description'] as String,
//       province: json['province'] as String,
//       country: json['country'] as String,
//       latitude: (json['latitude'] as num).toDouble(),
//       longitude: (json['longitude'] as num).toDouble(),
//       imageUrl: json['imageUrl'] as String,
//       status: DestinationStatusX.fromString(json['status'] as String),
//       createdAt: DateTime.parse(json['createdAt'] as String),
//       updatedAt: DateTime.parse(json['updatedAt'] as String),
//     );
//   }

//   /// From the backend's `DestinationResponse`. It has no status or
//   /// timestamps; a soft-deleted destination is shown as inactive, and the
//   /// cover is its first uploaded image.
//   factory DestinationModel.fromApi(Map<String, dynamic> json) {
//     final id = ApiJson.id(json['id']);
//     final imageIds = json['imageIds'] as List? ?? const [];
//     final now = DateTime.now();
//     return DestinationModel(
//       id: id,
//       name: ApiJson.string(json['name']),
//       description: ApiJson.string(json['description']),
//       province: ApiJson.string(json['province']),
//       country: ApiJson.string(json['country']),
//       latitude: ApiJson.decimal(json['latitude']),
//       longitude: ApiJson.decimal(json['longitude']),
//       imageUrl: imageIds.isEmpty
//           ? ''
//           : ApiJson.mediaUrl('destinations', id, imageIds.first),
//       status: ApiJson.flag(json, 'deleted')
//           ? DestinationStatus.inactive
//           : DestinationStatus.active,
//       createdAt: now,
//       updatedAt: now,
//     );
//   }

//   factory DestinationModel.fromEntity(Destination d) {
//     return DestinationModel(
//       id: d.id,
//       name: d.name,
//       description: d.description,
//       province: d.province,
//       country: d.country,
//       latitude: d.latitude,
//       longitude: d.longitude,
//       imageUrl: d.imageUrl,
//       status: d.status,
//       createdAt: d.createdAt,
//       updatedAt: d.updatedAt,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description,
//       'province': province,
//       'country': country,
//       'latitude': latitude,
//       'longitude': longitude,
//       'imageUrl': imageUrl,
//       'status': status.name,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }
// }


import '../../../../core/network/api_json.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_status.dart';

class DestinationModel extends Destination {
  const DestinationModel({
    required super.id,
    required super.name,
    required super.description,
    required super.province,
    required super.country,
    required super.latitude,
    required super.longitude,
    required super.imageUrl,
    super.images = const [],
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl'] as String? ?? '';
    final images = (json['images'] as List?)?.map((e) => e.toString()).toList() ??
        [if (imageUrl.isNotEmpty) imageUrl];

    return DestinationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      province: json['province'] as String,
      country: json['country'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: imageUrl,
      images: images,
      status: DestinationStatusX.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// From the backend's `DestinationResponse`. It has no status or
  /// timestamps; a soft-deleted destination is shown as inactive. Every
  /// uploaded image becomes an entry in [images]; the first is the cover.
  factory DestinationModel.fromApi(Map<String, dynamic> json) {
    final id = ApiJson.id(json['id']);
    final imageIds = json['imageIds'] as List? ?? const [];
    final imageUrls = <String>[
      for (final imageId in imageIds)
        ApiJson.mediaUrl('destinations', id, imageId),
    ];
    final now = DateTime.now();
    return DestinationModel(
      id: id,
      name: ApiJson.string(json['name']),
      description: ApiJson.string(json['description']),
      province: ApiJson.string(json['province']),
      country: ApiJson.string(json['country']),
      latitude: ApiJson.decimal(json['latitude']),
      longitude: ApiJson.decimal(json['longitude']),
      imageUrl: imageUrls.isEmpty ? '' : imageUrls.first,
      images: imageUrls,
      status: ApiJson.flag(json, 'deleted')
          ? DestinationStatus.inactive
          : DestinationStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DestinationModel.fromEntity(Destination d) {
    return DestinationModel(
      id: d.id,
      name: d.name,
      description: d.description,
      province: d.province,
      country: d.country,
      latitude: d.latitude,
      longitude: d.longitude,
      imageUrl: d.imageUrl,
      images: d.images,
      status: d.status,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'province': province,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'images': images,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}