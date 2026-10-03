import '../../../../core/entities/app_user.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/entities/user_status.dart';
import '../../../../core/utils/result.dart';

abstract class UserRepository {
  Future<Result<List<AppUser>>> getAllUsers({
    String? query,
    UserRole? role,
    UserStatus? status,
  });
  Future<Result<AppUser>> getUserById(String id);
  /// Creates the Keycloak account (with [password]), its profile row and
  /// its realm [role].
  Future<Result<AppUser>> createUser({
    required String userName,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required Gender gender,
    required String role,
    required DateTime dateOfBirth,
  });
  Future<Result<AppUser>> updateProfile({
    required String id,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
    Gender? gender,
    DateTime? dateOfBirth,
  });
  Future<Result<void>> setUserStatus(String id, UserStatus status);
  Future<Result<AppUser>> setUserRole(String id, UserRole role);
  Future<Result<void>> deleteUser(String id);
}
