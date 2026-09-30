import '../../../../core/entities/app_user.dart';
import '../../../../core/utils/result.dart';

abstract class AuthRepository {
  /// Signs in through Keycloak's hosted login page (Authorization Code +
  /// PKCE). [identityProvider] jumps straight to a Keycloak-brokered
  /// provider such as `google` or `facebook`. A `Success(null)` means the
  /// user closed the login page.
  Future<Result<AppUser?>> login({String? loginHint, String? identityProvider});

  /// Creates the account via the API, then signs in with it prefilled.
  Future<Result<AppUser?>> register({
    required String userName,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  });

  Future<Result<void>> logout();

  Future<Result<AppUser?>> restoreSession();

  Future<Result<void>> requestPasswordReset(String email);

  /// Opens Keycloak's own "update password" page for the signed-in user.
  Future<Result<void>> changePassword();

  Future<Result<String>> refreshToken();
}
