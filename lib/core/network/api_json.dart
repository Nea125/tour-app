import 'package:dio/dio.dart';

import '../constants/keycloak_config.dart';
import '../storage/token_storage.dart';

/// Conversions between the backend's JSON (Long ids, `LocalDate` strings,
/// UPPER_CASE enums) and the app's entities (String ids, [DateTime]s,
/// lower-case enum names).
class ApiJson {
  ApiJson._();

  static String id(dynamic value) => value?.toString() ?? '';

  /// Backend path ids are `Long`s; entity ids are their string form.
  static int? toId(String? value) =>
      value == null || value.isEmpty ? null : int.tryParse(value);

  static DateTime date(dynamic value, [DateTime? fallback]) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }
    return fallback ?? DateTime.now();
  }

  /// `LocalDate` wire format: `yyyy-MM-dd`.
  static String localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static int integer(dynamic value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;

  static double decimal(dynamic value, [double fallback = 0]) =>
      (value as num?)?.toDouble() ?? fallback;

  static String string(dynamic value) => value as String? ?? '';

  /// Record components named `isX` may be serialized as `isX` or `x`.
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

  /// Bearer header for images hosted by the API (every endpoint, media
  /// included, requires a JWT); `null` for third-party URLs.
  static Map<String, String>? imageHeaders(String url) {
    final token = TokenStorage.currentAccessToken;
    if (token == null ||
        !url.startsWith('http://${KeycloakConfig.host}:1403')) {
      return null;
    }
    return {'Authorization': 'Bearer $token'};
  }

  /// True for a file just picked on-device (as opposed to an uploaded,
  /// server-hosted image URL).
  static bool isLocalFile(String path) =>
      path.isNotEmpty && !path.startsWith('http');

  static Future<MultipartFile> file(String path) =>
      MultipartFile.fromFile(path, filename: path.split('/').last);
}
