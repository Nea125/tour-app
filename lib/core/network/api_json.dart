import 'package:dio/dio.dart';

import '../constants/keycloak_config.dart';
import '../storage/token_storage.dart';


class ApiJson {
  ApiJson._();

  static String id(dynamic value) => value?.toString() ?? '';

  static int? toId(String? value) =>
      value == null || value.isEmpty ? null : int.tryParse(value);

  static DateTime date(dynamic value, [DateTime? fallback]) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }
    return fallback ?? DateTime.now();
  }
  static DateTime? localDateTime(dynamic value) {
  if (value == null) return null;

  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }

  return null;
}

 
  static String localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static int integer(dynamic value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;

  static double decimal(dynamic value, [double fallback = 0]) =>
      (value as num?)?.toDouble() ?? fallback;

  static String string(dynamic value) => value as String? ?? '';

  static bool flag(Map<String, dynamic> json, String name) {
    final value =
        json['is${name[0].toUpperCase()}${name.substring(1)}'] ?? json[name];
    return value == true;
  }

  static String enumName(dynamic value) =>
      (value as String? ?? '').toLowerCase();

  /// Image served by `GET /{resource}/{ownerId}/media/{imageId}`.
  static String mediaUrl(String resource, String ownerId, dynamic imageId) =>
      '${KeycloakConfig.apiBaseUrl}/$resource/$ownerId/media/$imageId';

  static Map<String, String>? imageHeaders(String url) {
    final token = TokenStorage.currentAccessToken;
    if (token == null ||
        !url.startsWith('http://${KeycloakConfig.host}:1403')) {
      return null;
    }
    return {'Authorization': 'Bearer $token'};
  }

  static bool isLocalFile(String path) =>
      path.isNotEmpty && !path.startsWith('http');

  static Future<MultipartFile> file(String path) =>
      MultipartFile.fromFile(path, filename: path.split('/').last);
}
