import 'package:dio/dio.dart';

import '../constants/keycloak_config.dart';
import '../storage/token_storage.dart';
import 'dio_helper.dart';
import 'keycloak_auth_service.dart';


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


    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra[skipAuthKey] == true) return handler.next(options);
          var tokens = await tokenStorage.read();
          if (tokens != null && tokens.isAccessTokenExpired) {
            tokens = await _refresh(tokens);
          }
          if (tokens != null) {
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
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


  static const skipAuthKey = 'skip_auth';
  static const _retriedKey = 'auth_retried';

  final TokenStorage tokenStorage;
  final KeycloakAuthService authService;

  late final Dio _dio;
  Dio get dio => _dio;

  void Function()? onSessionExpired;

  Future<AuthTokens?> _refresh(AuthTokens tokens) async {
    try {
      final refreshed = await authService.refresh(tokens.refreshToken);
      await tokenStorage.save(refreshed);
      return refreshed;
    } on DioException catch (e) {

      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        await tokenStorage.clear();
        onSessionExpired?.call();
      }
      return null;
    }
  }
}
