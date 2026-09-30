import 'package:equatable/equatable.dart';
import 'guide_status.dart';

class TourGuide extends Equatable {
  final String id;
  final String userId;
  final String licenseNumber;
  final int experienceYears;
  final String languages;
  final String bio;
  final GuideStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TourGuide({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    required this.experienceYears,
    required this.languages,
    required this.bio,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  List<String> get languageList => languages
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  TourGuide copyWith({
    String? id,
    String? userId,
    String? licenseNumber,
    int? experienceYears,
    String? languages,
    String? bio,
    GuideStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TourGuide(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      experienceYears: experienceYears ?? this.experienceYears,
      languages: languages ?? this.languages,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    licenseNumber,
    experienceYears,
    languages,
    bio,
    status,
    createdAt,
    updatedAt,
  ];
}
