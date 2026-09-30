import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/base_api_service.dart';
import '../../data/datasources/schedule_remote_datasource.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../domain/entities/schedule_status.dart';
import '../../domain/entities/tour_schedule.dart';
import '../../domain/repositories/schedule_repository.dart';

final scheduleRemoteDataSourceProvider = Provider<ScheduleRemoteDataSource>(
  (ref) => ScheduleRemoteDataSource(ref.watch(baseApiServiceProvider)),
);

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(ref.watch(scheduleRemoteDataSourceProvider));
});

final schedulesByTourProvider =
    FutureProvider.family<List<TourSchedule>, String>((ref, tourId) async {
      final repo = ref.watch(scheduleRepositoryProvider);
      final result = await repo.getSchedulesByTourId(tourId);
      return result.when(success: (data) => data, failure: (f) => throw f);
    });

final upcomingSchedulesProvider = FutureProvider<List<TourSchedule>>((
  ref,
) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  final result = await repo.getUpcomingSchedules();
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final scheduleByIdProvider = FutureProvider.family<TourSchedule, String>((
  ref,
  id,
) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  final result = await repo.getScheduleById(id);
  return result.when(success: (s) => s, failure: (f) => throw f);
});

final availableSlotsProvider = FutureProvider.family<int, String>((
  ref,
  scheduleId,
) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  final result = await repo.getAvailableSlots(scheduleId);
  return result.when(success: (n) => n, failure: (f) => throw f);
});

final guideIdsForScheduleProvider = FutureProvider.family<List<String>, String>(
  (ref, scheduleId) async {
    final repo = ref.watch(scheduleRepositoryProvider);
    final result = await repo.getGuideIdsForSchedule(scheduleId);
    return result.when(success: (data) => data, failure: (f) => throw f);
  },
);

final schedulesForGuideProvider =
    FutureProvider.family<List<TourSchedule>, String>((ref, guideId) async {
      final repo = ref.watch(scheduleRepositoryProvider);
      final result = await repo.getSchedulesForGuide(guideId);
      return result.when(success: (data) => data, failure: (f) => throw f);
    });

class ScheduleController extends Notifier<void> {
  @override
  void build() {}

  void _invalidateAll() {
    ref.invalidate(schedulesByTourProvider);
    ref.invalidate(upcomingSchedulesProvider);
    ref.invalidate(scheduleByIdProvider);
    ref.invalidate(availableSlotsProvider);
    ref.invalidate(guideIdsForScheduleProvider);
    ref.invalidate(schedulesForGuideProvider);
  }

  Future<String?> createSchedule(TourSchedule schedule) async {
    final repo = ref.read(scheduleRepositoryProvider);
    final result = await repo.createSchedule(schedule);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> updateSchedule(TourSchedule schedule) async {
    final repo = ref.read(scheduleRepositoryProvider);
    final result = await repo.updateSchedule(schedule);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> deleteSchedule(String id) async {
    final repo = ref.read(scheduleRepositoryProvider);
    final result = await repo.deleteSchedule(id);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> setStatus(String id, ScheduleStatus status) async {
    final repo = ref.read(scheduleRepositoryProvider);
    final result = await repo.setStatus(id, status);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> assignGuide(String scheduleId, String guideId) async {
    final repo = ref.read(scheduleRepositoryProvider);
    final result = await repo.assignGuide(scheduleId, guideId);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> removeGuide(String scheduleId, String guideId) async {
    final repo = ref.read(scheduleRepositoryProvider);
    final result = await repo.removeGuide(scheduleId, guideId);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }
}

final scheduleControllerProvider = NotifierProvider<ScheduleController, void>(
  ScheduleController.new,
);
