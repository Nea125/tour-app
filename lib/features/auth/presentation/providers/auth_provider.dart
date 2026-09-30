import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/entities/app_user.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(
    keycloak: ref.watch(keycloakAuthServiceProvider),
    client: ref.watch(dioClientProvider),
    api: ref.watch(baseApiServiceProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

/// Holds the current session. `null` data means signed-out; `AsyncLoading`
/// covers app-launch session restoration and in-flight auth calls.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    // A refresh token rejected mid-session (revoked, idle timeout) signs
    // the user out and lets the router send them back to login.
    ref.read(dioClientProvider).onSessionExpired = () {
      state = const AsyncData(null);
    };
    final repo = ref.watch(authRepositoryProvider);
    final result = await repo.restoreSession();
    return result.when(success: (user) => user, failure: (_) => null);
  }

  Future<String?> login({String? loginHint}) {
    return _signIn((repo) => repo.login(loginHint: loginHint));
  }

  Future<String?> register({
    required String userName,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) {
    return _signIn(
      (repo) => repo.register(
        userName: userName,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      ),
    );
  }

  /// Google/Facebook are brokered by Keycloak (`kc_idp_hint`), so the
  /// resulting token is one the backend accepts. The alias must match the
  /// identity provider's alias in the `tour-system` realm.
  Future<String?> loginWithGoogle() {
    return _signIn((repo) => repo.login(identityProvider: 'google'));
  }

  Future<String?> loginWithFacebook() {
    return _signIn((repo) => repo.login(identityProvider: 'facebook'));
  }

  /// Returns an error message, or `null` on success/cancellation.
  Future<String?> _signIn(
    Future<Result<AppUser?>> Function(AuthRepository repo) action,
  ) async {
    state = const AsyncLoading();
    final result = await action(ref.read(authRepositoryProvider));
    return result.when(
      success: (user) {
        state = AsyncData(user);
        return null;
      },
      failure: (failure) {
        state = const AsyncData(null);
        return failure.message;
      },
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> refreshToken() async {
    if (state.valueOrNull == null) return;
    await ref.read(authRepositoryProvider).refreshToken();
  }

  void updateUser(AppUser user) {
    state = AsyncData(user);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

/// Convenience sync accessor for the current user, `null` while
/// loading/signed-out.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).valueOrNull;
});
