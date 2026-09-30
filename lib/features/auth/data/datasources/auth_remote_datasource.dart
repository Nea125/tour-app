// ignore_for_file: constant_identifier_names

import 'package:dio/dio.dart';

import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_exception.dart';
import '../../../../core/network/dio_helper.dart';
import '../../../../core/network/jwt_decoder.dart';
import '../../../../core/network/keycloak_auth_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/app_user_model.dart';

/// Real auth backed by Keycloak (sign-in, refresh, logout) and the
/// tour-management API (`/auth/register`, `/users/{id}`).
class AuthRemoteDataSource {
  static const String _REGISTER = "/auth/register";
  static const String _USERS = "/users";

  final KeycloakAuthService keycloak;
  final DioClient client;
  final BaseApiService api;

  AuthRemoteDataSource({
    required this.keycloak,
    required this.client,
    required this.api,
  });

  TokenStorage get tokenStorage => client.tokenStorage;

  Future<AuthTokens> authorize({
    String? loginHint,
    String? identityProvider,
    String? action,
  }) async {
    final tokens = await keycloak.authorize(
      loginHint: loginHint,
      identityProvider: identityProvider,
      action: action,
    );
    await tokenStorage.save(tokens);
    return tokens;
  }

  /// Throws [DioErrorHttpException]; a `code` of 400/401 means Keycloak
  /// rejected the refresh token (session over).
  Future<AuthTokens> refresh(AuthTokens tokens) async {
    try {
      final refreshed = await keycloak.refresh(tokens.refreshToken);
      await tokenStorage.save(refreshed);
      return refreshed;
    } on DioException catch (e) {
      throw DIOHelper.i.onDioError(e);
    }
  }

  Future<void> logout() async {
    final tokens = await tokenStorage.read();
    await tokenStorage.clear();
    if (tokens == null) return;
    try {
      await keycloak.logout(tokens.refreshToken);
    } on DioException {
      // Local tokens are already gone; an unreachable Keycloak just means
      // its session lingers until it times out.
    }
  }

  /// `POST /auth/register` creates the Keycloak user and its profile row.
  Future<void> register({
    required String userName,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) {
    return api.onRequest(
      path: _REGISTER,
      method: HTTPMethod.POST,
      isNeedToken: false,
      data: {
        'userName': userName,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'confirmPassword': password,
      },
      onSuccess: (_) {},
    );
  }

  /// Loads `/users/{sub}` for the signed-in user. Accounts created directly
  /// in Keycloak have no profile row yet, so fall back to token claims.
  Future<AppUserModel> fetchCurrentUser(AuthTokens tokens) async {
    final roles = JwtDecoder.realmRoles(tokens.accessToken);
    try {
      return await api.onRequest(
        path: '$_USERS/${tokens.userId}',
        method: HTTPMethod.GET,
        onSuccess: (response) => AppUserModel.fromProfileResponse(
          response.data['data'] as Map<String, dynamic>,
          realmRoles: roles,
        ),
      );
    } on DioErrorHttpException catch (e) {
      if (e.code != 404) rethrow;
      final claims = JwtDecoder.decode(tokens.idToken ?? tokens.accessToken);
      return AppUserModel.fromProfileResponse({
        'id': tokens.userId,
        'firstName': claims['given_name'],
        'lastName': claims['family_name'],
        'email': claims['email'],
      }, realmRoles: roles);
    }
  }
}
