import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';

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

  static String mediaUrl(String resource, String ownerId, dynamic imageId) =>
      '${KeycloakConfig.apiBaseUrl}/$resource/$ownerId/media/$imageId';

  /// Media ids of a response, in display order. Reads `images`
  /// (`[{id, sortOrder}]`) and falls back to a flat `imageIds` list.
  static List<dynamic> imageIds(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    if (images == null) return json['imageIds'] as List? ?? const [];
    final sorted = images.whereType<Map>().toList()
      ..sort(
        (a, b) => integer(a['sortOrder']).compareTo(integer(b['sortOrder'])),
      );
    return [for (final image in sorted) image['id']];
  }

  /// Media id at the end of a [mediaUrl].
  static String mediaIdOf(String url) => url.split('/').last;


  static Future<List<String>> addReplacedImages(
    FormData form,
    List<String> images,
    List<String> serverImages,
  ) async {
    final replaced = <String>[];
    for (var i = 0; i < images.length && i < serverImages.length; i++) {
      if (!isLocalFile(images[i])) continue;
      form.fields.add(MapEntry('imageIds', mediaIdOf(serverImages[i])));
      form.files.add(MapEntry('images', await file(images[i])));
      replaced.add(serverImages[i]);
    }
    return replaced;
  }


  static void evictImages(Iterable<String> urls) {
    for (final url in urls) {
      NetworkImage(url).evict();
    }
  }

  // static Map<String, String>? imageHeaders(String url) {
  //   final token = TokenStorage.currentAccessToken;
  //   if (token == null ||
  //       !url.startsWith('http://${KeycloakConfig.host}:1403')) {
  //     return null;
  //   }
  //   return {'Authorization': 'Bearer $token'};
  // }

//   static Map<String, String>? imageHeaders(String url) {
//   final token = TokenStorage.currentAccessToken;

//   if (token == null ||
//       !url.startsWith(KeycloakConfig.apiBaseUrl)) {
//     return null;
//   }

//   return {'Authorization': 'Bearer $token'};
// }

static Map<String, String>? imageHeaders(String url) {
  final token = TokenStorage.currentAccessToken;
  final uri = Uri.tryParse(url);
  final apiUri = Uri.tryParse(KeycloakConfig.apiBaseUrl);

  if (token == null ||
      token.isEmpty ||
      uri == null ||
      apiUri == null ||
      uri.origin != apiUri.origin) {
    return null;
  }

  return {
    'Authorization': 'Bearer $token',
  };
}

  static bool isLocalFile(String path) =>
      path.isNotEmpty && !path.startsWith('http');

  static Future<MultipartFile> file(String path) =>
      MultipartFile.fromFile(path, filename: path.split('/').last);
}
