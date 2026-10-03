import 'package:equatable/equatable.dart';
import 'destination_status.dart';

class Destination extends Equatable {
  final String id;
  final String name;
  final String description;
  final String province;
  final String country;
  final double latitude;
  final double longitude;
  /// Cover image: the first of [images].
  final String imageUrl;

  /// All image URLs, or local paths for photos picked but not yet uploaded.
  final List<String> images;
  final DestinationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.province,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.images = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Destination copyWith({
    String? id,
    String? name,
    String? description,
    String? province,
    String? country,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? images,
    DestinationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      province: province ?? this.province,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    province,
    country,
    latitude,
    longitude,
    imageUrl,
    images,
    status,
    createdAt,
    updatedAt,
  ];
}
