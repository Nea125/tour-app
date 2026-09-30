// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart' show TimeOfDay;

import '../../../../core/network/api_json.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/entities/itinerary_activity.dart';
import '../models/itinerary_activity_model.dart';
import '../models/itinerary_model.dart';


class ItineraryRemoteDataSource {
  static const String _ACTIVITY = "/activity";
  static const String _BY_TOUR = "/activity/tour";

  final BaseApiService api;
  ItineraryRemoteDataSource(this.api);

  static const _locationSeparator = ' @ ';

  Future<List<ItineraryModel>> getItineraryByTourId(String tourId) async {
    final activities = await api.getAllPages(
      path: '$_BY_TOUR/$tourId',
      fromJson: (json) => json,
    );
    activities.sort(
      (a, b) => ApiJson.integer(a['id']).compareTo(ApiJson.integer(b['id'])),
    );
    return [
      for (var i = 0; i < activities.length; i++)
        _day(activities[i], dayNumber: i + 1),
    ];
  }

  ItineraryModel _day(Map<String, dynamic> json, {required int dayNumber}) {
    final now = DateTime.now();
    return ItineraryModel(
      id: ApiJson.id(json['id']),
      tourId: ApiJson.id(json['tourId']),
      dayNumber: dayNumber,
      title: ApiJson.string(json['title']),
      description: ApiJson.string(json['description']),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<ItineraryModel> addDay(Itinerary day) {
    return api.onRequest(
      path: _ACTIVITY,
      method: HTTPMethod.POST,
      data: {
        'tourId': ApiJson.toId(day.tourId),
        'title': day.title,
        'description': day.description,
        'timeline': [
          {'time': '09:00-10:00', 'activity': day.title},
        ],
      },
      onSuccess: (r) =>
          _day(BaseApiService.dataOf(r), dayNumber: day.dayNumber),
    );
  }

  Future<ItineraryModel> updateDay(Itinerary day) async {
    final current = await _get(day.id);
    final saved = await _put(day.id, {
      ...current,
      'title': day.title,
      'description': day.description,
    });
    return _day(saved, dayNumber: day.dayNumber);
  }

  Future<void> deleteDay(String id) {
    return api.onRequest(
      path: '$_ACTIVITY/$id',
      method: HTTPMethod.DELETE,
      onSuccess: (_) {},
    );
  }

  Future<List<ItineraryActivityModel>> getActivities(String itineraryId) async {
    final timeline = _timeline(await _get(itineraryId));
    return [
      for (var i = 0; i < timeline.length; i++)
        _activity(itineraryId, i, timeline[i]),
    ];
  }

  Future<ItineraryActivityModel> addActivity(ItineraryActivity activity) {
    return _editTimeline(activity.itineraryId, (timeline) {
      final index = activity.sortOrder.clamp(0, timeline.length);
      timeline.insert(index, _entry(activity));
      return index;
    });
  }

  Future<ItineraryActivityModel> updateActivity(ItineraryActivity activity) {
    final (dayId, index) = _parseId(activity.id);
    return _editTimeline(dayId, (timeline) {
      _checkIndex(timeline, index);
      timeline[index] = _entry(activity);
      return index;
    });
  }

  Future<void> deleteActivity(String id) async {
    final (dayId, index) = _parseId(id);
    final current = await _get(dayId);
    final timeline = _timeline(current);
    _checkIndex(timeline, index);
    if (timeline.length == 1) {
      throw Exception(
        'A day needs at least one activity — delete the day instead',
      );
    }
    timeline.removeAt(index);
    await _put(dayId, {...current, 'timeline': timeline});
  }

  Future<void> reorderActivities(
    String itineraryId,
    List<String> orderedActivityIds,
  ) async {
    final current = await _get(itineraryId);
    final timeline = _timeline(current);
    final reordered = [
      for (final id in orderedActivityIds) timeline[_parseId(id).$2],
    ];
    if (reordered.length != timeline.length) {
      throw Exception('Activity list is out of date, please refresh');
    }
    await _put(itineraryId, {...current, 'timeline': reordered});
  }

  // --- helpers --------------------

  Future<Map<String, dynamic>> _get(String id) {
    return api.onRequest(
      path: '$_ACTIVITY/$id',
      method: HTTPMethod.GET,
      onSuccess: BaseApiService.dataOf,
    );
  }

  /// `PUT /activity/{id}` takes the full `ActivityRequest`.
  Future<Map<String, dynamic>> _put(String id, Map<String, dynamic> json) {
    return api.onRequest(
      path: '$_ACTIVITY/$id',
      method: HTTPMethod.PUT,
      data: {
        'tourId': json['tourId'],
        'title': json['title'],
        'description': json['description'],
        'timeline': json['timeline'],
      },
      onSuccess: BaseApiService.dataOf,
    );
  }

  Future<ItineraryActivityModel> _editTimeline(
    String dayId,
    int Function(List<Map<String, dynamic>> timeline) edit,
  ) async {
    final current = await _get(dayId);
    final timeline = _timeline(current);
    final index = edit(timeline);
    final saved = await _put(dayId, {...current, 'timeline': timeline});
    return _activity(dayId, index, _timeline(saved)[index]);
  }

  static List<Map<String, dynamic>> _timeline(Map<String, dynamic> json) => [
    for (final e in json['timeline'] as List? ?? const [])
      (e as Map).cast<String, dynamic>(),
  ];

  static (String, int) _parseId(String id) {
    final sep = id.lastIndexOf(':');
    if (sep <= 0) throw Exception('Activity not found');
    return (id.substring(0, sep), int.parse(id.substring(sep + 1)));
  }

  static void _checkIndex(List timeline, int index) {
    if (index < 0 || index >= timeline.length) {
      throw Exception('Activity not found');
    }
  }

  static Map<String, dynamic> _entry(ItineraryActivity a) {
    final location = a.location.trim();
    return {
      'time': '${_formatTime(a.startTime)}-${_formatTime(a.endTime)}',
      'activity': location.isEmpty
          ? a.title
          : '${a.title}$_locationSeparator$location',
    };
  }

  static ItineraryActivityModel _activity(
    String dayId,
    int index,
    Map<String, dynamic> entry,
  ) {
    final times = ApiJson.string(entry['time']).split('-');
    final start = _parseTime(times.first);
    final end = times.length > 1 ? _parseTime(times[1]) : start;
    final text = ApiJson.string(entry['activity']);
    final sep = text.lastIndexOf(_locationSeparator);
    return ItineraryActivityModel(
      id: '$dayId:$index',
      itineraryId: dayId,
      title: sep == -1 ? text : text.substring(0, sep),
      description: '',
      startTime: start,
      endTime: end,
      location: sep == -1
          ? ''
          : text.substring(sep + _locationSeparator.length),
      sortOrder: index,
    );
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Accepts `HH:mm` (also `HH:mm:ss`); anything else becomes 00:00.
  static TimeOfDay _parseTime(String value) {
    final parts = value.trim().split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }
}
