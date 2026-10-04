// ignore_for_file: constant_identifier_names

import '../../../../core/network/api_json.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/entities/schedule_status.dart';
import '../../domain/entities/tour_schedule.dart';
import '../models/tour_schedule_model.dart';

/// `/tour-schedule` endpoints (plus guide ↔ schedule links) of the API.
class ScheduleRemoteDataSource {
  static const String _SCHEDULES = "/tour-schedule";
  static const String _BY_TOUR = "/tour-schedule/tour";
  static const String _OPEN = "/tour-schedule/status/OPEN";
  static const String _GUIDES = "/guides";
  static const String _TOUR_GUIDES = "/tour-guide";
  static const String _SCHEDULES_OF_GUIDE = "/schedules";

  final BaseApiService api;
  ScheduleRemoteDataSource(this.api);

  static List<TourScheduleModel> _byStart(List<TourScheduleModel> list) =>
      list..sort((a, b) => a.startDate.compareTo(b.startDate));

  Future<List<TourScheduleModel>> getSchedulesByTourId(String tourId) async {
    return _byStart(
      await api.getAllPages(
        path: '$_BY_TOUR/$tourId',
        fromJson: TourScheduleModel.fromApi,
      ),
    );
  }

  Future<List<TourScheduleModel>> getUpcomingSchedules() async {
    final now = DateTime.now();
    final open = await api.getAllPages(
      path: _OPEN,
      fromJson: TourScheduleModel.fromApi,
    );
    return _byStart(open.where((s) => s.startDate.isAfter(now)).toList());
  }

  Future<Map<String, dynamic>> _getRaw(String id) {
    return api.onRequest(
      path: '$_SCHEDULES/$id',
      method: HTTPMethod.GET,
      onSuccess: BaseApiService.dataOf,
    );
  }

  Future<TourScheduleModel> getScheduleById(String id) async =>
      TourScheduleModel.fromApi(await _getRaw(id));

  Future<TourScheduleModel> createSchedule(TourSchedule schedule) {
    if (schedule.endDate.isBefore(schedule.startDate)) {
      throw Exception('End date must be after the start date');
    }
    return api.onRequest(
      path: _SCHEDULES,
      method: HTTPMethod.POST,
      data: {
        'tourId': ApiJson.toId(schedule.tourId),
        'startDate': ApiJson.localDate(schedule.startDate),
        'endDate': ApiJson.localDate(schedule.endDate),
        // 'capacity': schedule.capacity,
      },
      onSuccess: (r) => TourScheduleModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<TourScheduleModel> updateSchedule(TourSchedule schedule) {
    if (schedule.endDate.isBefore(schedule.startDate)) {
      throw Exception('End date must be after the start date');
    }
    return _patch(schedule.id, {
      'startDate': ApiJson.localDate(schedule.startDate),
      'endDate': ApiJson.localDate(schedule.endDate),
      // 'capacity': schedule.capacity,
      'status': TourScheduleModel.statusToApi(schedule.status),
    });
  }

  Future<TourScheduleModel> setStatus(String id, ScheduleStatus status) =>
      _patch(id, {'status': TourScheduleModel.statusToApi(status)});

  Future<TourScheduleModel> _patch(String id, Map<String, dynamic> body) {
    return api.onRequest(
      path: '$_SCHEDULES/$id',
      method: HTTPMethod.PATCH,
      data: body,
      onSuccess: (r) => TourScheduleModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<void> deleteSchedule(String id) {
    return api.onRequest(
      path: '$_SCHEDULES/$id',
      method: HTTPMethod.DELETE,
      onSuccess: (_) {},
    );
  }

  /// The API tracks remaining seats as `availableCapacity`.
  Future<int> getAvailableSlots(String scheduleId) async {
    final json = await _getRaw(scheduleId);
    return ApiJson.integer(
      json['availableCapacity'],
      ApiJson.integer(json['capacity']),
    );
  }

  Future<void> assignGuide(String scheduleId, String guideId) {
    return api.onRequest(
      path: '$_SCHEDULES/$scheduleId$_GUIDES/$guideId',
      method: HTTPMethod.POST,
      onSuccess: (_) {},
    );
  }

  Future<void> removeGuide(String scheduleId, String guideId) {
    return api.onRequest(
      path: '$_SCHEDULES/$scheduleId$_GUIDES/$guideId',
      method: HTTPMethod.DELETE,
      onSuccess: (_) {},
    );
  }

  Future<List<String>> getGuideIdsForSchedule(String scheduleId) {
    return api.onRequest(
      path: '$_SCHEDULES/$scheduleId$_GUIDES',
      method: HTTPMethod.GET,
      onSuccess: (r) =>
          BaseApiService.listOf(r).map((g) => ApiJson.id(g['id'])).toList(),
    );
  }

  Future<List<TourScheduleModel>> getSchedulesForGuide(String guideId) {
    return api.onRequest(
      path: '$_TOUR_GUIDES/$guideId$_SCHEDULES_OF_GUIDE',
      method: HTTPMethod.GET,
      onSuccess: (r) => _byStart(
        BaseApiService.listOf(r).map(TourScheduleModel.fromApi).toList(),
      ),
    );
  }
}
