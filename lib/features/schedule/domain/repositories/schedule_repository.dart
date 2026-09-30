import '../../../../core/utils/result.dart';
import '../entities/schedule_status.dart';
import '../entities/tour_schedule.dart';

abstract class ScheduleRepository {
  Future<Result<List<TourSchedule>>> getSchedulesByTourId(String tourId);
  Future<Result<List<TourSchedule>>> getUpcomingSchedules();
  Future<Result<TourSchedule>> getScheduleById(String id);
  Future<Result<TourSchedule>> createSchedule(TourSchedule schedule);
  Future<Result<TourSchedule>> updateSchedule(TourSchedule schedule);
  Future<Result<void>> deleteSchedule(String id);
  Future<Result<TourSchedule>> setStatus(String id, ScheduleStatus status);
  Future<Result<int>> getAvailableSlots(String scheduleId);

  // tour_schedule_guides
  Future<Result<void>> assignGuide(String scheduleId, String guideId);
  Future<Result<void>> removeGuide(String scheduleId, String guideId);
  Future<Result<List<String>>> getGuideIdsForSchedule(String scheduleId);
  Future<Result<List<TourSchedule>>> getSchedulesForGuide(String guideId);
}
