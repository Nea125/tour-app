import '../../../../core/network/api_json.dart';
import '../../domain/entities/guide_status.dart';
import '../../domain/entities/tour_guide.dart';

class TourGuideModel extends TourGuide {
  const TourGuideModel({
    required super.id,
    required super.userId,
    required super.licenseNumber,
    required super.experienceYears,
    required super.languages,
    required super.bio,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TourGuideModel.fromJson(Map<String, dynamic> json) {
    return TourGuideModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      licenseNumber: json['licenseNumber'] as String,
      experienceYears: json['experienceYears'] as int,
      languages: json['languages'] as String,
      bio: json['bio'] as String,
      status: GuideStatusX.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// From the backend's `TourGuideResponse`; `languages` is a JSON list
  /// there and a comma-separated string here.
  factory TourGuideModel.fromApi(Map<String, dynamic> json) {
    final now = DateTime.now();
    return TourGuideModel(
      id: ApiJson.id(json['id']),
      userId: ApiJson.id(json['userId']),
      licenseNumber: ApiJson.string(json['licenseNumber']),
      experienceYears: ApiJson.integer(json['experienceYears']),
      languages: (json['languages'] as List? ?? const []).join(', '),
      bio: ApiJson.string(json['bio']),
      status: GuideStatusX.fromString(ApiJson.enumName(json['status'])),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory TourGuideModel.fromEntity(TourGuide g) {
    return TourGuideModel(
      id: g.id,
      userId: g.userId,
      licenseNumber: g.licenseNumber,
      experienceYears: g.experienceYears,
      languages: g.languages,
      bio: g.bio,
      status: g.status,
      createdAt: g.createdAt,
      updatedAt: g.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'licenseNumber': licenseNumber,
      'experienceYears': experienceYears,
      'languages': languages,
      'bio': bio,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
