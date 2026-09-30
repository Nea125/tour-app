import 'package:dio/dio.dart';

import '../constants/keycloak_config.dart';
import '../storage/token_storage.dart';
import 'dio_helper.dart';
import 'keycloak_auth_service.dart';

/// Centralized Dio client for the tour-management REST API. Attaches the
/// Keycloak access token to every request, refreshes it when it's expired
/// (or the API answers 401) and retries once.
class DioClient {
  DioClient({required this.tokenStorage, required this.authService}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: KeycloakConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Queued so concurrent requests share a single refresh instead of each
    // spending the (possibly single-use) refresh token.
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        // onRequest: (options, handler) async {
        //   if (options.extra[skipAuthKey] == true) return handler.next(options);
        //   var tokens = await tokenStorage.read();
        //   if (tokens != null && tokens.isAccessTokenExpired) {
        //     tokens = await _refresh(tokens);
        //   }
        //   if (tokens != null) {
        //     options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
        //   }
        //   handler.next(options);
        // },

        onRequest: (options, handler) async {
  if (options.extra[skipAuthKey] == true) {
    print('⏭️ Auth skipped: ${options.path}');
    return handler.next(options);
  }

  var tokens = await tokenStorage.read();

  if (tokens != null && tokens.isAccessTokenExpired) {
    print('🔄 Access token expired, refreshing...');
    tokens = await _refresh(tokens);
  }

  if (tokens != null) {
    options.headers['Authorization'] =
        'Bearer ${tokens.accessToken}';

    print('✅ TOKEN ATTACHED');
    print('➡️ ${options.method} ${options.path}');
    print('➡️ Token length: ${tokens.accessToken.length}');
  } else {
    print('❌ NO TOKEN FOUND');
    print('➡️ ${options.method} ${options.path}');
  }

  handler.next(options);
},
        onError: (error, handler) async {
  print('❌ API ERROR');
  print('Status: ${error.response?.statusCode}');
  print('Path: ${error.requestOptions.path}');
  print('Response: ${error.response?.data}');

  final request = error.requestOptions;

  if (error.response?.statusCode != 401 ||
      request.extra[skipAuthKey] == true ||
      request.extra[_retriedKey] == true) {
    return handler.next(error);
  }

  final tokens = await tokenStorage.read();
  final refreshed = tokens == null ? null : await _refresh(tokens);

  if (refreshed == null) {
    return handler.next(error);
  }

  try {
    request.extra[_retriedKey] = true;
    request.headers['Authorization'] =
        'Bearer ${refreshed.accessToken}';

    handler.resolve(await _dio.fetch(request));
  } on DioException catch (e) {
    handler.next(e);
  }
},
      ),
    );
    _dio.interceptors.add(DIOHelper.i.defaultInterceptor);
  }

  /// Set in `RequestOptions.extra` to send a request without the stored
  /// access token (public endpoints, or a caller-supplied token).
  static const skipAuthKey = 'skip_auth';
  static const _retriedKey = 'auth_retried';

  final TokenStorage tokenStorage;
  final KeycloakAuthService authService;

  late final Dio _dio;
  Dio get dio => _dio;

  /// Called when the refresh token itself is rejected, so the auth layer
  /// can sign the user out.
  void Function()? onSessionExpired;

  Future<AuthTokens?> _refresh(AuthTokens tokens) async {
    try {
      final refreshed = await authService.refresh(tokens.refreshToken);
      await tokenStorage.save(refreshed);
      return refreshed;
    } on DioException catch (e) {
      // Only a rejected grant means the session is over; a network blip
      // shouldn't sign the user out.
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        await tokenStorage.clear();
        onSessionExpired?.call();
      }
      return null;
    }
  }
}
