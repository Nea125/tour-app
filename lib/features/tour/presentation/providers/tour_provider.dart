import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/base_api_service.dart';
import '../../data/datasources/tour_remote_datasource.dart';
import '../../data/repositories/tour_repository_impl.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_status.dart';
import '../../domain/repositories/tour_repository.dart';

final tourRemoteDataSourceProvider = Provider<TourRemoteDataSource>(
  (ref) => TourRemoteDataSource(ref.watch(baseApiServiceProvider)),
);

final tourRepositoryProvider = Provider<TourRepository>((ref) {
  return TourRepositoryImpl(ref.watch(tourRemoteDataSourceProvider));
});

final tourSearchQueryProvider = StateProvider<String>((ref) => '');
final tourDestinationFilterProvider = StateProvider<String?>((ref) => null);

class TourListController extends AsyncNotifier<List<Tour>> {
  @override
  Future<List<Tour>> build() async {
    final query = ref.watch(tourSearchQueryProvider);
    final destinationId = ref.watch(tourDestinationFilterProvider);
    final repo = ref.watch(tourRepositoryProvider);
    final result = await repo.getTours(
      query: query,
      destinationId: destinationId,
    );
    return result.when(success: (data) => data, failure: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(tourByIdProvider);
    ref.invalidate(toursByDestinationProvider);
  }

  Future<String?> createTour(Tour tour) async {
    final repo = ref.read(tourRepositoryProvider);
    final result = await repo.createTour(tour);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> updateTour(Tour tour) async {
    final repo = ref.read(tourRepositoryProvider);
    final result = await repo.updateTour(tour);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> deleteTour(String id) async {
    final repo = ref.read(tourRepositoryProvider);
    final result = await repo.deleteTour(id);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> setStatus(String id, TourStatus status) async {
    final repo = ref.read(tourRepositoryProvider);
    final result = await repo.setStatus(id, status);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }
}

final tourListControllerProvider =
    AsyncNotifierProvider<TourListController, List<Tour>>(
      TourListController.new,
    );

final tourByIdProvider = FutureProvider.family<Tour, String>((ref, id) async {
  final repo = ref.watch(tourRepositoryProvider);
  final result = await repo.getTourById(id);
  return result.when(success: (t) => t, failure: (f) => throw f);
});

final toursByDestinationProvider = FutureProvider.family<List<Tour>, String>((
  ref,
  destinationId,
) async {
  final repo = ref.watch(tourRepositoryProvider);
  final result = await repo.getTours(destinationId: destinationId);
  return result.when(success: (t) => t, failure: (f) => throw f);
});
