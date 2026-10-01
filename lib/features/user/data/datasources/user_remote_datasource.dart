// ignore_for_file: constant_identifier_names

import 'package:dio/dio.dart';

import '../../../../core/entities/user_role.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/network/base_api_service.dart';
import '../../../../core/network/http_method.dart';
import '../../../auth/data/models/app_user_model.dart';

/// `/users` endpoints of the tour-management API.
///
/// Roles live in Keycloak and aren't returned by the API, so users are
/// customers unless they have a tour-guide profile.
class UserRemoteDataSource {
  static const String _USERS = "/users";
  static const String _IMAGE = "/image";
  static const String _GUIDES = "/tour-guide";

  final BaseApiService api;
  UserRemoteDataSource(this.api);

  AppUserModel _user(Map<String, dynamic> json, {bool isGuide = false}) {
    return AppUserModel.fromProfileResponse(
      json,
      realmRoles: [if (isGuide) 'TOUR_GUIDE'],
    );
  }

  Future<List<AppUserModel>> getAllUsers({
    String? query,
    UserRole? role,
    UserStatus? status,
  }) async {
    final results = await Future.wait([
      api.getAllPages(path: _USERS, fromJson: (json) => json),
      api.getAllPages(
        path: _GUIDES,
        fromJson: (json) => ApiJson.id(json['userId']),
      ),
    ]);
    final guideUserIds = results[1].cast<String>().toSet();
    var list = results[0]
        .cast<Map<String, dynamic>>()
        .map(
          (json) => _user(
            json,
            isGuide: guideUserIds.contains(ApiJson.id(json['id'])),
          ),
        )
        .toList();
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list
          .where(
            (u) =>
                u.fullName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q),
          )
          .toList();
    }
    if (role != null) list = list.where((u) => u.role == role).toList();
    if (status != null) list = list.where((u) => u.status == status).toList();
    return list;
  }

  Future<AppUserModel> getUserById(String id) {
    return api.onRequest(
      path: '$_USERS/$id',
      method: HTTPMethod.GET,
      onSuccess: (r) => _user(BaseApiService.dataOf(r)),
    );
  }

  /// Creates the Keycloak account and its profile row.
  Future<AppUserModel> createUser({
    required String userName,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required Gender gender,
    required String role,
    required DateTime dateOfBirth,
  }) {
    return api.onRequest(
      path: _USERS,
      method: HTTPMethod.POST,
      data: {
        'userName': userName,
        'password': password,
        'confirmPassword': password,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'gender': gender.name.toUpperCase(),
        'dateOfBirth': ApiJson.localDate(dateOfBirth),
        'role': role,
      },
      onSuccess: (r) => _user(BaseApiService.dataOf(r)),
    );
  }

  /// Patches the profile fields, then uploads [profileImage] when it's a
  /// photo just picked on-device.
  Future<AppUserModel> updateProfile({
    required String id,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
    Gender? gender,
    String? role,
    DateTime? dateOfBirth,
  }) async {
    var user = await api.onRequest(
      path: '$_USERS/$id',
      method: HTTPMethod.PATCH,
      data: {
        'firstName': ?firstName,
        'lastName': ?lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (gender != null) 'gender': gender.name.toUpperCase(),
        'role': ?role,
        if (dateOfBirth != null) 'dateOfBirth': ApiJson.localDate(dateOfBirth),
      },
      onSuccess: (r) => BaseApiService.dataOf(r),
    );
    if (profileImage != null && ApiJson.isLocalFile(profileImage)) {
      user = await api.onRequest(
        path: '$_USERS/$id$_IMAGE',
        method: HTTPMethod.PATCH,
        data: FormData.fromMap({'image': await ApiJson.file(profileImage)}),
        onSuccess: (r) => BaseApiService.dataOf(r),
      );
    }
    return _user(user);
  }

  Future<void> deleteUser(String id) {
    return api.onRequest(
      path: '$_USERS/$id',
      method: HTTPMethod.DELETE,
      onSuccess: (_) {},
    );
  }
}
