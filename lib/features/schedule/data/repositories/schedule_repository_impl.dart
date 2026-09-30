import '../../../../core/utils/result.dart';
import '../../domain/entities/schedule_status.dart';
import '../../domain/entities/tour_schedule.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource dataSource;
  ScheduleRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<TourSchedule>>> getSchedulesByTourId(String tourId) =>
      guardResult(() => dataSource.getSchedulesByTourId(tourId));

  @override
  Future<Result<List<TourSchedule>>> getUpcomingSchedules() =>
      guardResult(dataSource.getUpcomingSchedules);

  @override
  Future<Result<TourSchedule>> getScheduleById(String id) =>
      guardResult(() => dataSource.getScheduleById(id));

  @override
  Future<Result<TourSchedule>> createSchedule(TourSchedule schedule) =>
      guardResult(() => dataSource.createSchedule(schedule));

  @override
  Future<Result<TourSchedule>> updateSchedule(TourSchedule schedule) =>
      guardResult(() => dataSource.updateSchedule(schedule));

  @override
  Future<Result<void>> deleteSchedule(String id) =>
      guardResult(() => dataSource.deleteSchedule(id));

  @override
  Future<Result<TourSchedule>> setStatus(String id, ScheduleStatus status) =>
      guardResult(() => dataSource.setStatus(id, status));

  @override
  Future<Result<int>> getAvailableSlots(String scheduleId) =>
      guardResult(() => dataSource.getAvailableSlots(scheduleId));

  @override
  Future<Result<void>> assignGuide(String scheduleId, String guideId) =>
      guardResult(() => dataSource.assignGuide(scheduleId, guideId));

  @override
  Future<Result<void>> removeGuide(String scheduleId, String guideId) =>
      guardResult(() => dataSource.removeGuide(scheduleId, guideId));

  @override
  Future<Result<List<String>>> getGuideIdsForSchedule(String scheduleId) =>
      guardResult(() => dataSource.getGuideIdsForSchedule(scheduleId));

  @override
  Future<Result<List<TourSchedule>>> getSchedulesForGuide(String guideId) =>
      guardResult(() => dataSource.getSchedulesForGuide(guideId));
}
