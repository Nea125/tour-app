import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/base_api_service.dart';
import '../../data/datasources/guide_remote_datasource.dart';
import '../../data/repositories/guide_repository_impl.dart';
import '../../domain/entities/guide_status.dart';
import '../../domain/entities/tour_guide.dart';
import '../../domain/repositories/guide_repository.dart';

final guideRemoteDataSourceProvider = Provider<GuideRemoteDataSource>(
  (ref) => GuideRemoteDataSource(ref.watch(baseApiServiceProvider)),
);

final guideRepositoryProvider = Provider<GuideRepository>((ref) {
  return GuideRepositoryImpl(ref.watch(guideRemoteDataSourceProvider));
});

final guideSearchQueryProvider = StateProvider<String>((ref) => '');

class GuideListController extends AsyncNotifier<List<TourGuide>> {
  @override
  Future<List<TourGuide>> build() async {
    final query = ref.watch(guideSearchQueryProvider);
    final repo = ref.watch(guideRepositoryProvider);
    final result = await repo.getGuides(query: query);
    return result.when(success: (data) => data, failure: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(guideByIdProvider);
    ref.invalidate(guideByUserIdProvider);
  }

  Future<String?> createGuide(TourGuide guide) async {
    final repo = ref.read(guideRepositoryProvider);
    final result = await repo.createGuide(guide);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> updateGuide(TourGuide guide) async {
    final repo = ref.read(guideRepositoryProvider);
    final result = await repo.updateGuide(guide);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> deleteGuide(String id) async {
    final repo = ref.read(guideRepositoryProvider);
    final result = await repo.deleteGuide(id);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> setStatus(String id, GuideStatus status) async {
    final repo = ref.read(guideRepositoryProvider);
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

final guideListControllerProvider =
    AsyncNotifierProvider<GuideListController, List<TourGuide>>(
      GuideListController.new,
    );

final guideByIdProvider = FutureProvider.family<TourGuide, String>((
  ref,
  id,
) async {
  final repo = ref.watch(guideRepositoryProvider);
  final result = await repo.getGuideById(id);
  return result.when(success: (g) => g, failure: (f) => throw f);
});

final guideByUserIdProvider = FutureProvider.family<TourGuide?, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(guideRepositoryProvider);
  final result = await repo.getGuideByUserId(userId);
  return result.when(success: (g) => g, failure: (f) => throw f);
});
