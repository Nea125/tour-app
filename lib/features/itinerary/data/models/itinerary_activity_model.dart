import 'package:flutter/material.dart';
import '../../domain/entities/itinerary_activity.dart';

class ItineraryActivityModel extends ItineraryActivity {
  const ItineraryActivityModel({
    required super.id,
    required super.itineraryId,
    required super.title,
    required super.description,
    required super.startTime,
    required super.endTime,
    required super.location,
    required super.sortOrder,
  });

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  factory ItineraryActivityModel.fromJson(Map<String, dynamic> json) {
    return ItineraryActivityModel(
      id: json['id'] as String,
      itineraryId: json['itineraryId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: _parseTime(json['startTime'] as String),
      endTime: _parseTime(json['endTime'] as String),
      location: json['location'] as String,
      sortOrder: json['sortOrder'] as int,
    );
  }

  factory ItineraryActivityModel.fromEntity(ItineraryActivity a) {
    return ItineraryActivityModel(
      id: a.id,
      itineraryId: a.itineraryId,
      title: a.title,
      description: a.description,
      startTime: a.startTime,
      endTime: a.endTime,
      location: a.location,
      sortOrder: a.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itineraryId': itineraryId,
      'title': title,
      'description': description,
      'startTime': _formatTime(startTime),
      'endTime': _formatTime(endTime),
      'location': location,
      'sortOrder': sortOrder,
    };
  }
}
