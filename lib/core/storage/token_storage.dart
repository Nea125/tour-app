import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/jwt_decoder.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String? idToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.idToken,
  });

  /// Keycloak subject — the same id the backend uses for `user_profile.id`.
  String get userId => JwtDecoder.decode(accessToken)['sub'] as String;

  /// Treats the token as expired slightly early so requests don't race the
  /// real expiry.
  bool get isAccessTokenExpired {
    final exp = JwtDecoder.decode(accessToken)['exp'] as int?;
    if (exp == null) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
  }
}

/// Keycloak tokens live in the platform keychain/keystore rather than
/// SharedPreferences, since the refresh token grants long-lived access.
class TokenStorage {
  static const _keyAccess = 'kc_access_token';
  static const _keyRefresh = 'kc_refresh_token';
  static const _keyId = 'kc_id_token';

  final FlutterSecureStorage _storage;
  // TokenStorage([FlutterSecureStorage? storage])
  //   : _storage = storage ?? const FlutterSecureStorage();
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              encryptedSharedPreferences: true,
            ),
          );

  /// Last access token saved or read, for places that need it
  /// synchronously (e.g. auth headers on `Image.network`).
  static String? currentAccessToken;

  Future<void> save(AuthTokens tokens) async {
    currentAccessToken = tokens.accessToken;
    await _storage.write(key: _keyAccess, value: tokens.accessToken);
    await _storage.write(key: _keyRefresh, value: tokens.refreshToken);
    if (tokens.idToken != null) {
      await _storage.write(key: _keyId, value: tokens.idToken);
    }
  }

  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _keyAccess);
    final refresh = await _storage.read(key: _keyRefresh);
    if (access == null || refresh == null) return null;
    currentAccessToken = access;
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      idToken: await _storage.read(key: _keyId),
    );
  }

  Future<void> clear() async {
    currentAccessToken = null;
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
    await _storage.delete(key: _keyId);
  }
}
