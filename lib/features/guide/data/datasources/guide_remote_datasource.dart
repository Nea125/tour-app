// ignore_for_file: constant_identifier_names

import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/entities/tour_guide.dart';
import '../models/tour_guide_model.dart';

/// `/tour-guide` endpoints of the tour-management API.
class GuideRemoteDataSource {
  static const String _GUIDES = "/tour-guide";

  final BaseApiService api;
  GuideRemoteDataSource(this.api);

  Future<List<TourGuideModel>> _all() =>
      api.getAllPages(path: _GUIDES, fromJson: TourGuideModel.fromApi);

  /// The API has no guide search, so filter here.
  Future<List<TourGuideModel>> getGuides({String? query}) async {
    final guides = await _all();
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isEmpty) return guides;
    return guides
        .where(
          (g) =>
              g.languages.toLowerCase().contains(q) ||
              g.licenseNumber.toLowerCase().contains(q) ||
              g.bio.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<TourGuideModel> getGuideById(String id) {
    return api.onRequest(
      path: '$_GUIDES/$id',
      method: HTTPMethod.GET,
      onSuccess: (r) => TourGuideModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<TourGuideModel?> getGuideByUserId(String userId) async {
    for (final guide in await _all()) {
      if (guide.userId == userId) return guide;
    }
    return null;
  }

  Map<String, dynamic> _body(TourGuide g) => {
    'userId': g.userId,
    'licenseNumber': g.licenseNumber,
    'experienceYears': g.experienceYears,
    'languages': g.languageList,
    'bio': g.bio,
  };

  Future<TourGuideModel> createGuide(TourGuide guide) {
    return api.onRequest(
      path: _GUIDES,
      method: HTTPMethod.POST,
      data: {..._body(guide), 'status': guide.status.name.toUpperCase()},
      onSuccess: (r) => TourGuideModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<TourGuideModel> updateGuide(TourGuide guide) {
    return api.onRequest(
      path: '$_GUIDES/${guide.id}',
      method: HTTPMethod.PATCH,
      data: _body(guide),
      onSuccess: (r) => TourGuideModel.fromApi(BaseApiService.dataOf(r)),
    );
  }

  Future<void> deleteGuide(String id) {
    return api.onRequest(
      path: '$_GUIDES/$id',
      method: HTTPMethod.DELETE,
      onSuccess: (_) {},
    );
  }
}
