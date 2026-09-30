import 'package:equatable/equatable.dart';

class Itinerary extends Equatable {
  final String id;
  final String tourId;
  final int dayNumber;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Itinerary({
    required this.id,
    required this.tourId,
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Itinerary copyWith({
    String? id,
    String? tourId,
    int? dayNumber,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Itinerary(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tourId,
    dayNumber,
    title,
    description,
    createdAt,
    updatedAt,
  ];
}
