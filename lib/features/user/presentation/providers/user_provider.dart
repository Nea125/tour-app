import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/entities/app_user.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/entities/user_status.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/network/base_api_service.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>(
  (ref) => UserRemoteDataSource(ref.watch(baseApiServiceProvider)),
);

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
});

final userSearchQueryProvider = StateProvider<String>((ref) => '');
final userRoleFilterProvider = StateProvider<UserRole?>((ref) => null);
final userStatusFilterProvider = StateProvider<UserStatus?>((ref) => null);

class UserListController extends AsyncNotifier<List<AppUser>> {
  @override
  Future<List<AppUser>> build() async {
    final query = ref.watch(userSearchQueryProvider);
    final role = ref.watch(userRoleFilterProvider);
    final status = ref.watch(userStatusFilterProvider);
    final repo = ref.watch(userRepositoryProvider);
    final result = await repo.getAllUsers(
      query: query,
      role: role,
      status: status,
    );
    return result.when(success: (users) => users, failure: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<String?> createUser({
    required String userName,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required Gender gender,
    required String role,
    required DateTime dateOfBirth,
  }) async {
    if (ref.read(currentUserProvider) == null) return 'You must be signed in';
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.createUser(
      userName: userName,
      password: password,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      gender: gender,
      role: role,
      dateOfBirth: dateOfBirth,
    );
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> setStatus(String id, UserStatus status) async {
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.setUserStatus(id, status);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> changeRole(String id, UserRole role) async {
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.setUserRole(id, role);
    return result.when(
      success: (updated) {
        if (ref.read(currentUserProvider)?.id == updated.id) {
          ref.read(authControllerProvider.notifier).updateUser(updated);
        }
        ref.invalidate(userByIdProvider(id));
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> deleteUser(String id) async {
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.deleteUser(id);
    return result.when(
      success: (_) {
        refresh();
        return null;
      },
      failure: (f) => f.message,
    );
  }
}

final userListControllerProvider =
    AsyncNotifierProvider<UserListController, List<AppUser>>(
      UserListController.new,
    );

final userByIdProvider = FutureProvider.family<AppUser, String>((
  ref,
  id,
) async {
  final repo = ref.watch(userRepositoryProvider);
  final result = await repo.getUserById(id);
  return result.when(success: (u) => u, failure: (f) => throw f);
});
