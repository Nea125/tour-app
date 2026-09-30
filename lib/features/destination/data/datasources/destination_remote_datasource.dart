// ignore_for_file: constant_identifier_names

import 'package:dio/dio.dart';

import '../../../../core/network/api_json.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/entities/destination.dart';
import '../models/destination_model.dart';

/// `/destinations` endpoints of the tour-management API.
class DestinationRemoteDataSource {
  static const String _DESTINATIONS = "/destinations";
  static const String _SEARCH = "/destinations/search";
  static const String _IMAGES = "/images";

  final BaseApiService api;
  DestinationRemoteDataSource(this.api);

  Future<List<DestinationModel>> getDestinations({String? query}) {
    final q = query?.trim() ?? '';
    return api.getAllPages(
      path: q.isEmpty ? _DESTINATIONS : _SEARCH,
      query: q.isEmpty ? null : {'name': q},
      fromJson: DestinationModel.fromApi,
    );
  }

  Future<DestinationModel> getDestinationById(String id) {
    return api.onRequest(
      path: '$_DESTINATIONS/$id',
      method: HTTPMethod.GET,
      onSuccess: (r) => DestinationModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  /// Multipart: the fields plus an optional `images` file picked on-device.
  Future<DestinationModel> createDestination(Destination d) async {
    final form = FormData.fromMap({
      'name': d.name,
      'description': d.description,
      'province': d.province,
      'country': d.country,
      'latitude': d.latitude,
      'longitude': d.longitude,
    });
    if (ApiJson.isLocalFile(d.imageUrl)) {
      form.files.add(MapEntry('images', await ApiJson.file(d.imageUrl)));
    }
    return api.onRequest(
      path: _DESTINATIONS,
      method: HTTPMethod.POST,
      data: form,
      onSuccess: (r) => DestinationModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  /// Patches the fields, then replaces the cover image when a new one was
  /// picked on-device.
  Future<DestinationModel> updateDestination(Destination d) async {
    final imageIds = await api.onRequest(
      path: '$_DESTINATIONS/${d.id}',
      method: HTTPMethod.PATCH,
      data: {
        'name': d.name,
        'description': d.description,
        'province': d.province,
        'country': d.country,
        'latitude': d.latitude,
        'longitude': d.longitude,
      },
      onSuccess: (r) =>
          BaseApiService.dataOf(r)['imageIds'] as List? ?? const [],
    );
    if (ApiJson.isLocalFile(d.imageUrl)) {
      if (imageIds.isEmpty) {
        throw Exception(
          'This destination has no image to replace; the API only accepts '
          'images when a destination is created',
        );
      }
      await api.onRequest(
        path: '$_DESTINATIONS/${d.id}$_IMAGES/${imageIds.first}',
        method: HTTPMethod.PUT,
        data: FormData.fromMap({'image': await ApiJson.file(d.imageUrl)}),
        onSuccess: (_) {},
      );
    }
    return getDestinationById(d.id);
  }

  Future<void> deleteDestination(String id) {
    return api.onRequest(
      path: '$_DESTINATIONS/$id',
      method: HTTPMethod.DELETE,
      onSuccess: (_) {},
    );
  }
}
