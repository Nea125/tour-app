import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;

class ItineraryActivity extends Equatable {
  final String id;
  final String itineraryId;
  final String title;
  final String description;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String location;
  final int sortOrder;

  const ItineraryActivity({
    required this.id,
    required this.itineraryId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.sortOrder,
  });

  ItineraryActivity copyWith({
    String? id,
    String? itineraryId,
    String? title,
    String? description,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? location,
    int? sortOrder,
  }) {
    return ItineraryActivity(
      id: id ?? this.id,
      itineraryId: itineraryId ?? this.itineraryId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    id,
    itineraryId,
    title,
    description,
    startTime.hour,
    startTime.minute,
    endTime.hour,
    endTime.minute,
    location,
    sortOrder,
  ];
}
