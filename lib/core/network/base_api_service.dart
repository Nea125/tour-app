import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import 'dio_client.dart';
import 'dio_exception.dart';
import 'dio_helper.dart';
import 'http_method.dart';

final baseApiServiceProvider = Provider<BaseApiService>((ref) {
  return BaseApiService(ref.watch(dioClientProvider).dio);
});

/// Single entry point for API calls. The access token (and its refresh) is
/// handled by [DioClient]'s interceptor; this only shapes the request and
/// turns every failure into a [BaseHttpException].
class BaseApiService {
  final Dio dio;

  BaseApiService(this.dio);

  Future<T> onRequest<T>({
    required String path,
    required String method,
    required T Function(Response response) onSuccess,
    Map<String, dynamic>? query,
    Map<String, dynamic> headers = const {},
    dynamic data,
    String? customToken,
    Dio? customDioClient,
    bool isNeedToken = true,
  }) async {
    Response? response;
    try {
      final options = Options(
        method: method,
        headers: {
          if (customToken != null) 'Authorization': 'Bearer $customToken',
          ...headers,
        },
        extra: {DioClient.skipAuthKey: !isNeedToken || customToken != null},
      );

      response = await (customDioClient ?? dio).request(
        path,
        options: options,
        queryParameters: query,
        data: data,
      );

      if (response.data == null) {
        throw ServerResponseHttpException(DIOHelper.SOMETHING_WRONG);
      }
      return onSuccess(response);
    } on DioException catch (exception) {
      throw DIOHelper.i.onDioError(exception);
    } on ServerResponseHttpException catch (exception) {
      throw DIOHelper.i.onServerResponseException(exception, response);
    } on BaseHttpException {
      rethrow;
    } catch (exception, stackTrace) {
      throw DIOHelper.i.onTypeError(exception, stackTrace);
    }
  }

  /// `data` of the backend's `ApiResponse` envelope, as a JSON object.
  static Map<String, dynamic> dataOf(Response response) =>
      (response.data['data'] as Map).cast<String, dynamic>();

  /// `data` of the backend's `ApiResponse` envelope, as a JSON list.
  static List<Map<String, dynamic>> listOf(Response response) =>
      _maps(response.data['data']);

  static List<Map<String, dynamic>> _maps(dynamic list) =>
      (list as List).map((e) => (e as Map).cast<String, dynamic>()).toList();

  /// Fetches every page of a paged `GET` endpoint. Understands both shapes
  /// the backend returns: `data: {items, totalPages}` and a bare
  /// `data: [...]` with a sibling `pagination: {totalPages}`.
  Future<List<T>> getAllPages<T>({
    required String path,
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, dynamic>? query,
    int pageSize = 100,
  }) async {
    final all = <T>[];
    var page = 0;
    var totalPages = 1;
    while (page < totalPages) {
      final (items, pages) = await onRequest(
        path: path,
        method: HTTPMethod.GET,
        query: {...?query, 'page': page, 'size': pageSize},
        onSuccess: (response) {
          final body = response.data as Map;
          final data = body['data'];
          if (data is Map) {
            return (
              _maps(data['items'] ?? const []),
              (data['totalPages'] as num?)?.toInt() ?? 1,
            );
          }
          final pagination = body['pagination'] as Map?;
          return (
            _maps(data ?? const []),
            (pagination?['totalPages'] as num?)?.toInt() ?? 1,
          );
        },
      );
      all.addAll(items.map(fromJson));
      totalPages = pages;
      page++;
    }
    return all;
  }
}
