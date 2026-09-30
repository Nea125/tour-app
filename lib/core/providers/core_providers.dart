import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../network/keycloak_auth_service.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final keycloakAuthServiceProvider = Provider<KeycloakAuthService>(
  (ref) => KeycloakAuthService(),
);

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    authService: ref.watch(keycloakAuthServiceProvider),
  ),
);
