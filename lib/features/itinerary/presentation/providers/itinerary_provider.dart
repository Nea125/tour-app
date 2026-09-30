import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/base_api_service.dart';
import '../../data/datasources/itinerary_remote_datasource.dart';
import '../../data/repositories/itinerary_repository_impl.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/entities/itinerary_activity.dart';
import '../../domain/repositories/itinerary_repository.dart';

final itineraryRemoteDataSourceProvider = Provider<ItineraryRemoteDataSource>(
  (ref) => ItineraryRemoteDataSource(ref.watch(baseApiServiceProvider)),
);

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepositoryImpl(ref.watch(itineraryRemoteDataSourceProvider));
});

final itineraryByTourProvider = FutureProvider.family<List<Itinerary>, String>((
  ref,
  tourId,
) async {
  final repo = ref.watch(itineraryRepositoryProvider);
  final result = await repo.getItineraryByTourId(tourId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final activitiesByItineraryProvider =
    FutureProvider.family<List<ItineraryActivity>, String>((
      ref,
      itineraryId,
    ) async {
      final repo = ref.watch(itineraryRepositoryProvider);
      final result = await repo.getActivities(itineraryId);
      return result.when(success: (data) => data, failure: (f) => throw f);
    });

class ItineraryController extends Notifier<void> {
  @override
  void build() {}

  void _invalidateAll() {
    ref.invalidate(itineraryByTourProvider);
    ref.invalidate(activitiesByItineraryProvider);
  }

  Future<String?> addDay(Itinerary day) async {
    final repo = ref.read(itineraryRepositoryProvider);
    final result = await repo.addDay(day);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> updateDay(Itinerary day) async {
    final repo = ref.read(itineraryRepositoryProvider);
    final result = await repo.updateDay(day);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> deleteDay(String id) async {
    final repo = ref.read(itineraryRepositoryProvider);
    final result = await repo.deleteDay(id);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> addActivity(ItineraryActivity activity) async {
    final repo = ref.read(itineraryRepositoryProvider);
    final result = await repo.addActivity(activity);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> updateActivity(ItineraryActivity activity) async {
    final repo = ref.read(itineraryRepositoryProvider);
    final result = await repo.updateActivity(activity);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> deleteActivity(String id) async {
    final repo = ref.read(itineraryRepositoryProvider);
    final result = await repo.deleteActivity(id);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> reorderActivities(
    String itineraryId,
    List<String> orderedIds,
  ) async {
    final repo = ref.read(itineraryRepositoryProvider);
    final result = await repo.reorderActivities(itineraryId, orderedIds);
    return result.when(
      success: (_) {
        _invalidateAll();
        return null;
      },
      failure: (f) => f.message,
    );
  }
}

final itineraryControllerProvider = NotifierProvider<ItineraryController, void>(
  ItineraryController.new,
);
