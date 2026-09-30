// ignore_for_file: constant_identifier_names

import 'package:dio/dio.dart';

import '../../../../core/network/api_json.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/entities/tour.dart';
import '../models/tour_model.dart';

/// `/tours` endpoints of the tour-management API.
class TourRemoteDataSource {
  static const String _TOURS = "/tours";
  static const String _SEARCH = "/tours/search";
  static const String _BY_DESTINATION = "/tours/destination";
  static const String _IMAGES = "/images";

  final BaseApiService api;
  TourRemoteDataSource(this.api);

  Future<List<TourModel>> getTours({
    String? destinationId,
    String? query,
  }) async {
    final q = query?.trim() ?? '';
    if (destinationId != null) {
      // No combined endpoint: filter the destination's tours by title here.
      final tours = await api.getAllPages(
        path: '$_BY_DESTINATION/$destinationId',
        fromJson: TourModel.fromApi,
      );
      if (q.isEmpty) return tours;
      final lower = q.toLowerCase();
      return tours.where((t) => t.title.toLowerCase().contains(lower)).toList();
    }
    return api.getAllPages(
      path: q.isEmpty ? _TOURS : _SEARCH,
      query: q.isEmpty ? null : {'title': q},
      fromJson: TourModel.fromApi,
    );
  }

  Future<TourModel> getTourById(String id) {
    return api.onRequest(
      path: '$_TOURS/$id',
      method: HTTPMethod.GET,
      onSuccess: (r) => TourModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  /// Multipart: the fields plus at least one `images` file picked
  /// on-device (the API requires images on create).
  Future<TourModel> createTour(Tour tour) async {
    final localImages = tour.images.where(ApiJson.isLocalFile).toList();
    if (localImages.isEmpty) {
      throw Exception('Please choose at least one tour image');
    }
    final form = FormData.fromMap({
      'destinationId': tour.destinationId,
      'title': tour.title,
      'description': tour.description,
      'durationDays': tour.durationDays,
      'durationNights': tour.durationNights,
      'maxParticipants': tour.maxParticipants,
      'price': tour.price,
    });
    for (final path in localImages) {
      form.files.add(MapEntry('images', await ApiJson.file(path)));
    }
    return api.onRequest(
      path: _TOURS,
      method: HTTPMethod.POST,
      data: form,
      onSuccess: (r) => TourModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  /// Patches the fields, then replaces the cover (first) image when a new
  /// one was picked on-device.
  Future<TourModel> updateTour(Tour tour) async {
    final imageIds = await api.onRequest(
      path: '$_TOURS/${tour.id}',
      method: HTTPMethod.PATCH,
      data: {
        'destinationId': ApiJson.toId(tour.destinationId),
        'title': tour.title,
        'description': tour.description,
        'durationDays': tour.durationDays,
        'durationNights': tour.durationNights,
        'maxParticipants': tour.maxParticipants,
        'price': tour.price,
      },
      onSuccess: (r) =>
          BaseApiService.dataOf(r)['imageIds'] as List? ?? const [],
    );
    final cover = tour.images.isEmpty ? '' : tour.images.first;
    if (ApiJson.isLocalFile(cover) && imageIds.isNotEmpty) {
      await api.onRequest(
        path: '$_TOURS/${tour.id}$_IMAGES/${imageIds.first}',
        method: HTTPMethod.PUT,
        data: FormData.fromMap({'image': await ApiJson.file(cover)}),
        onSuccess: (_) {},
      );
    }
    return getTourById(tour.id);
  }

  Future<void> deleteTour(String id) {
    return api.onRequest(
      path: '$_TOURS/$id',
      method: HTTPMethod.DELETE,
      onSuccess: (_) {},
    );
  }
}
