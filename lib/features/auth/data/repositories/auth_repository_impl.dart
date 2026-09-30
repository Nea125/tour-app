import '../../../../core/entities/app_user.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_exception.dart';
import '../../../../core/network/dio_helper.dart';
import '../../../../core/network/keycloak_auth_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Result<AppUser?>> login({
    String? loginHint,
    String? identityProvider,
  }) async {
    try {
      final tokens = await dataSource.authorize(
        loginHint: loginHint,
        identityProvider: identityProvider,
      );
      final user = await dataSource.fetchCurrentUser(tokens);
      if (user.status != UserStatus.active) {
        await dataSource.logout();
        return Error(
          AuthFailure('This account is ${user.status.name}. Contact support.'),
        );
      }
      return Success(user);
    } on AuthCancelledException {
      return const Success(null);
    } catch (e) {
      await dataSource.tokenStorage.clear();
      return Error(AuthFailure(_message(e)));
    }
  }

  @override
  Future<Result<AppUser?>> register({
    required String userName,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      await dataSource.register(
        userName: userName,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );
    } catch (e) {
      return Error(ValidationFailure(_message(e)));
    }
    // The account exists now; PKCE still requires the password to be
    // entered on Keycloak's page, so prefill the username there.
    return login(loginHint: userName);
  }

  @override
  Future<Result<void>> logout() async {
    await dataSource.logout();
    return const Success(null);
  }

  @override
  Future<Result<AppUser?>> restoreSession() async {
    try {
      var tokens = await dataSource.tokenStorage.read();
      if (tokens == null) return const Success(null);
      if (tokens.isAccessTokenExpired) {
        tokens = await dataSource.refresh(tokens);
      }
      return Success(await dataSource.fetchCurrentUser(tokens));
    } on DioErrorHttpException catch (e) {
      // Expired/revoked refresh token → signed out, not an error.
      if (e.code == 400 || e.code == 401) {
        await dataSource.tokenStorage.clear();
        return const Success(null);
      }
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Result<void>> requestPasswordReset(String email) async {
    // The API has no reset endpoint; Keycloak owns credentials and offers
    // "Forgot password?" on its own login page.
    return const Error(
      ValidationFailure(
        'Tap "Sign In" and use "Forgot password?" on the sign-in page.',
      ),
    );
  }

  @override
  Future<Result<void>> changePassword() async {
    try {
      await dataSource.authorize(action: 'UPDATE_PASSWORD');
      return const Success(null);
    } on AuthCancelledException {
      return const Error(ValidationFailure('Password change cancelled'));
    } catch (e) {
      return Error(AuthFailure(_message(e)));
    }
  }

  @override
  Future<Result<String>> refreshToken() async {
    try {
      final tokens = await dataSource.tokenStorage.read();
      if (tokens == null) return const Error(AuthFailure('Not signed in'));
      final refreshed = await dataSource.refresh(tokens);
      return Success(refreshed.accessToken);
    } catch (e) {
      return const Error(AuthFailure('Session expired'));
    }
  }

  String _message(Object e) => DIOHelper.i.handleExceptionError(e);
}
