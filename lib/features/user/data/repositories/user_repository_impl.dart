import '../../../../core/entities/app_user.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource dataSource;
  UserRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<AppUser>>> getAllUsers({
    String? query,
    UserRole? role,
    UserStatus? status,
  }) => guardResult(
    () => dataSource.getAllUsers(query: query, role: role, status: status),
  );

  @override
  Future<Result<AppUser>> getUserById(String id) =>
      guardResult(() => dataSource.getUserById(id));

  @override
  Future<Result<AppUser>> createUser({
    required String userName,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String role,
    required Gender gender,
    required DateTime dateOfBirth,
  }) => guardResult(
    () => dataSource.createUser(
      userName: userName,
      password: password,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      gender: gender,
      role: role,
      dateOfBirth: dateOfBirth,
    ),
  );

  @override
  Future<Result<AppUser>> updateProfile({
    required String id,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
    Gender? gender,
    DateTime? dateOfBirth,
  }) => guardResult(
    () => dataSource.updateProfile(
      id: id,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      profileImage: profileImage,
      gender: gender,
      dateOfBirth: dateOfBirth,
    ),
  );

  // The API has no endpoint for changing a user's status.
  @override
  Future<Result<void>> setUserStatus(String id, UserStatus status) async =>
      guardResult(() => dataSource.updateUserStatus(id, status));

  @override
  Future<Result<AppUser>> setUserRole(String id, UserRole role) =>
      guardResult(() => dataSource.updateUserRole(id, role));

  @override
  Future<Result<void>> deleteUser(String id) =>
      guardResult(() => dataSource.deleteUser(id));
}
