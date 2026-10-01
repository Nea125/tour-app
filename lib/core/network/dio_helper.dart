// ignore_for_file: constant_identifier_names
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'dio_exception.dart';

class DIOHelper {
  DIOHelper._init();
  static DIOHelper? _instance;

  static DIOHelper get i => _instance ??= DIOHelper._init();

  static const String SOMETHING_WRONG = 'Something went wrong';
  static const String CONNECTION_ERROR = 'No Internet Connection';
  static const String TIMEOUT_ERROR = 'Request timed out. Please try again';
  static const String UNEXPECTED_ERROR = 'Oops, Something went wrong';
  static const String SERVER_ERROR = 'Server error';


  ServerErrorHttpException onTypeError(
    Object exception,
    StackTrace stackTrace,
  ) {
    debugPrint('Type Error :=> $exception\nStackTrace: $stackTrace');
    return ServerErrorHttpException(SOMETHING_WRONG);
  }

  void logDioError(DioException exception) {
    var errorMessage = 'Dio error :=> ${exception.requestOptions.path}';
    if (exception.response != null) {
      errorMessage += ', Response: => ${exception.response!.data}';
    } else {
      errorMessage += ', ${exception.message}';
    }
    debugPrint('Http Log: Server error :=> $errorMessage');
  }

  DioErrorHttpException onDioError(DioException exception) {
    logDioError(exception);
    if (exception.error is SocketException ||
        exception.type == DioExceptionType.connectionError) {
      // Mostly no internet connection, or the host is unreachable.
      return DioErrorHttpException(CONNECTION_ERROR);
    }
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout) {
      return DioErrorHttpException(TIMEOUT_ERROR);
    }
    if (exception.type == DioExceptionType.badResponse) {
      final statusCode = exception.response?.statusCode;
      if (statusCode == 502 || statusCode == 503) {
        return DioErrorHttpException(SERVER_ERROR, code: statusCode);
      }
      return DioErrorHttpException(
        serverMessage(exception.response?.data),
        code: statusCode,
      );
    }
    return DioErrorHttpException(
      UNEXPECTED_ERROR,
      code: exception.response?.statusCode,
    );
  }

  ServerResponseHttpException onServerResponseException(
    Object exception,
    Response? response,
  ) {
    debugPrint(
      'Http Log: Server error :=> ${response?.requestOptions.path}:=> '
      '$exception',
    );
    return ServerResponseHttpException(exception.toString());
  }

  String serverMessage(dynamic data) {
    if (data is! Map) return UNEXPECTED_ERROR;
    final details = data['errorDetails'];
    if (details is String && details.isNotEmpty) return details;
    if (details is List && details.isNotEmpty) {
      return details
          .whereType<Map>()
          .map((d) => '${d['field']}: ${d['reason']}')
          .join('\n');
    }
    final description = data['error_description'];
    if (description is String && description.isNotEmpty) return description;
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    return UNEXPECTED_ERROR;
  }


  String handleExceptionError(Object error, [String path = '']) {
    debugPrint('Exception caught [${error.runtimeType}][$path]: $error');
    if (error is BaseHttpException) return error.message;
    if (error is DioException) return onDioError(error).message;
    if (error is TypeError) return UNEXPECTED_ERROR;
    return error.toString().replaceFirst('Exception: ', '');
  }

  static const JsonEncoder encoder = JsonEncoder.withIndent('  ');

  final InterceptorsWrapper defaultInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) {
      _logRequest(options);
      handler.next(options);
    },
    onResponse: (response, handler) {
      _logResponse(response);
      handler.next(response);
    },
    onError: (error, handler) => handler.next(error),
  );

  static void _logResponse(Response response) {
    if (!kDebugMode) return;
    httpLog('${response.statusCode}: ${response.requestOptions.path}');
    prettyPrintJson(response.data);
  }

  static void _logRequest(RequestOptions options) {
    httpLog(
      '${options.method}: ${options.path}, '
      'query: ${options.queryParameters}, '
      'data: ${options.data}',
    );
  }

  static void httpLog([dynamic log, dynamic additional = '']) {
    if (kDebugMode) debugPrint('Http request Log: $log $additional');
  }

  static void prettyPrintJson(dynamic input) {
    if (!kDebugMode) return;
    String pretty;
    try {
      pretty = encoder.convert(input);
    } catch (_) {
      // Not JSON-encodable (bytes, streams, FormData...).
      pretty = input.toString();
    }
    pretty.split('\n').forEach(debugPrint);
  }
}
