import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:travel_app/core/network/jwt_decoder.dart';

import '../constants/keycloak_config.dart';
import '../storage/token_storage.dart';

/// Thrown when the user closes the Keycloak browser page without finishing.
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

/// Talks to Keycloak's OpenID Connect endpoints directly — the backend has
/// no login endpoint of its own, it only validates the resulting JWTs.
class KeycloakAuthService {
  final FlutterAppAuth _appAuth;

  /// Separate from the API client so token calls never pass through the
  /// API's auth interceptor (which would recurse on refresh).
  final Dio _dio;

  KeycloakAuthService({FlutterAppAuth? appAuth, Dio? dio})
    : _appAuth = appAuth ?? const FlutterAppAuth(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              contentType: Headers.formUrlEncodedContentType,
            ),
          );

  static const _serviceConfiguration = AuthorizationServiceConfiguration(
    authorizationEndpoint: KeycloakConfig.authorizationEndpoint,
    tokenEndpoint: KeycloakConfig.tokenEndpoint,
    endSessionEndpoint: KeycloakConfig.endSessionEndpoint,
  );

  /// Authorization Code + PKCE (S256): opens Keycloak's login page in the
  /// system browser, then exchanges the returned code (with the generated
  /// code verifier) for tokens. AppAuth generates the verifier/challenge.
  ///
  /// [identityProvider] maps to Keycloak's `kc_idp_hint`, skipping straight
  /// to a brokered provider such as `google` or `facebook`. [action] maps
  /// to `kc_action` (e.g. `UPDATE_PASSWORD`) for application-initiated
  /// account actions.
  Future<AuthTokens> authorize({
    String? loginHint,
    String? identityProvider,
    String? action,
  }) async {
    try {
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          KeycloakConfig.clientId,
          KeycloakConfig.redirectUrl,
          // clientSecret: KeycloakConfig.clientSecret,
          serviceConfiguration: _serviceConfiguration,
          scopes: KeycloakConfig.scopes,
          loginHint: loginHint,
          additionalParameters: {
            if (identityProvider != null) 'kc_idp_hint': identityProvider,
            if (action != null) 'kc_action': action,
          },
          allowInsecureConnections: true,
        ),
      );
      final accessToken = response.accessToken;
      final refreshToken = response.refreshToken;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Keycloak did not return tokens');
      }

      final claims = JwtDecoder.decode(accessToken);

      print('========== JWT ==========');
      print('iss: ${claims['iss']}');
      print('sub: ${claims['sub']}');
      print('aud: ${claims['aud']}');
      print('azp: ${claims['azp']}');
      print('realm_access: ${claims['realm_access']}');
      print('exp: ${claims['exp']}');
      print('=========================');

      return AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: response.idToken,
      );
    } on FlutterAppAuthUserCancelledException {
      throw const AuthCancelledException();
    }
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      KeycloakConfig.tokenEndpoint,
      data: {
        'grant_type': 'refresh_token',
        'client_id': KeycloakConfig.clientId,
        // 'client_secret': KeycloakConfig.clientSecret,
        'refresh_token': refreshToken,
      },
    );
    final data = response.data!;
    return AuthTokens(
      accessToken: data['access_token'] as String,
      // Keycloak may rotate the refresh token; keep the old one otherwise.
      refreshToken: data['refresh_token'] as String? ?? refreshToken,
      idToken: data['id_token'] as String?,
    );
  }

  /// Back-channel logout: ends the Keycloak session without a browser.
  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      KeycloakConfig.endSessionEndpoint,
      data: {
        'client_id': KeycloakConfig.clientId,
        // 'client_secret': KeycloakConfig.clientSecret,
        'refresh_token': refreshToken,
      },
    );
  }
}
