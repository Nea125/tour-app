import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/base_api_service.dart';
import '../../data/datasources/destination_remote_datasource.dart';
import '../../data/repositories/destination_repository_impl.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_status.dart';
import '../../domain/repositories/destination_repository.dart';

final destinationRemoteDataSourceProvider =
    Provider<DestinationRemoteDataSource>(
      (ref) => DestinationRemoteDataSource(ref.watch(baseApiServiceProvider)),
    );

final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return DestinationRepositoryImpl(
    ref.watch(destinationRemoteDataSourceProvider),
  );
});

final destinationSearchQueryProvider = StateProvider<String>((ref) => '');

class DestinationListController extends AsyncNotifier<List<Destination>> {
  @override
  Future<List<Destination>> build() async {
    final query = ref.watch(destinationSearchQueryProvider);
    final repo = ref.watch(destinationRepositoryProvider);
    final result = await repo.getDestinations(query: query);
    return result.when(success: (data) => data, failure: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<String?> createDestination(Destination destination) async {
    final repo = ref.read(destinationRepositoryProvider);
    final result = await repo.createDestination(destination);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> updateDestination(Destination destination) async {
    final repo = ref.read(destinationRepositoryProvider);
    final result = await repo.updateDestination(destination);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> deleteDestination(String id) async {
    final repo = ref.read(destinationRepositoryProvider);
    final result = await repo.deleteDestination(id);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> setStatus(String id, DestinationStatus status) async {
    final repo = ref.read(destinationRepositoryProvider);
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

final destinationListControllerProvider =
    AsyncNotifierProvider<DestinationListController, List<Destination>>(
      DestinationListController.new,
    );

final destinationByIdProvider = FutureProvider.family<Destination, String>((
  ref,
  id,
) async {
  final repo = ref.watch(destinationRepositoryProvider);
  final result = await repo.getDestinationById(id);
  return result.when(success: (d) => d, failure: (f) => throw f);
});
