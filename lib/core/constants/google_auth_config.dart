/// Google Sign-In configuration.
///
/// [serverClientId] must be the project's **Web** OAuth client ID (ends in
/// `.apps.googleusercontent.com`, `client_type: 3` in `google-services.json`).
/// It is created automatically once "Google" is enabled as a sign-in
/// provider under Firebase Console → Authentication → Sign-in method — it is
/// NOT the Android client ID. The `google_sign_in` package's Android
/// implementation (Credential Manager-based) requires it even though sign-in
/// happens on-device with no server involved.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String serverClientId =
      '790124071593-uhiu9p7la1gahrtm432umvpc4qu917q4.apps.googleusercontent.com';
}
