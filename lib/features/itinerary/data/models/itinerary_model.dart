import '../../domain/entities/itinerary.dart';

class ItineraryModel extends Itinerary {
  const ItineraryModel({
    required super.id,
    required super.tourId,
    required super.dayNumber,
    required super.title,
    required super.description,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    return ItineraryModel(
      id: json['id'] as String,
      tourId: json['tourId'] as String,
      dayNumber: json['dayNumber'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory ItineraryModel.fromEntity(Itinerary i) {
    return ItineraryModel(
      id: i.id,
      tourId: i.tourId,
      dayNumber: i.dayNumber,
      title: i.title,
      description: i.description,
      createdAt: i.createdAt,
      updatedAt: i.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tourId': tourId,
      'dayNumber': dayNumber,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
