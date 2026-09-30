import 'dart:convert';

/// Reads a JWT's payload without verifying it — verification is the
/// backend's job; the app only needs claims like `sub`, `exp` and roles.
class JwtDecoder {
  JwtDecoder._();

  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return const {};
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// Keycloak realm roles (`realm_access.roles`) — the same claim the
  /// backend's `JwtAuthenticationConverter` maps to authorities.
  static List<String> realmRoles(String token) {
    final realmAccess = decode(token)['realm_access'];
    if (realmAccess is! Map) return const [];
    return (realmAccess['roles'] as List? ?? const []).cast<String>();
  }
}
