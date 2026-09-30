
// class KeycloakConfig {
//   KeycloakConfig._();

// static const String host = String.fromEnvironment(
//   'API_HOST',
//   defaultValue: '10.0.2.2',
// );

//   static const String realm = 'tour-system';
//   static const String clientId = 'tour-mobile-app';

//   static const String clientSecret = String.fromEnvironment(
//     'KC_CLIENT_SECRET',
//     defaultValue: 'lyQLj7Rym0CA6gAbcgMb1eGP2jJaDOit',
//   );

// static const String redirectScheme = 'com.example.travelapp';

// static const String redirectUrl = '$redirectScheme://oauth2redirect';

//   static const List<String> scopes = ['openid', 'profile', 'email'];

//   static const String issuer = 'http://$host:1401/realms/$realm';
//   static const String _oidc = '$issuer/protocol/openid-connect';
//   static const String authorizationEndpoint = '$_oidc/auth';
//   static const String tokenEndpoint = '$_oidc/token';
//   static const String endSessionEndpoint = '$_oidc/logout';

//   static const String apiBaseUrl = 'http://$host:1403/api/v1';
// }


class KeycloakConfig {
  KeycloakConfig._();

  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2',
  );

  static const String realm = 'tour-system';
  static const String clientId = 'tour-mobile-app';

  static const String redirectScheme = 'com.example.travelapp';
  static const String redirectUrl =
      '$redirectScheme://oauth2redirect';

  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
  ];

  static const String issuer =
      'http://$host:1401/realms/$realm';

  static const String _oidc =
      '$issuer/protocol/openid-connect';

  static const String authorizationEndpoint =
      '$_oidc/auth';

  static const String tokenEndpoint =
      '$_oidc/token';

  static const String endSessionEndpoint =
      '$_oidc/logout';

  static const String apiBaseUrl =
      'http://$host:1403/api/v1';
}