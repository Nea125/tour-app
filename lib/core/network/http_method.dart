// ignore_for_file: constant_identifier_names

/// HTTP verbs for [BaseApiService.onRequest]. Dio upper-cases the method
/// before sending, so lower-case values are fine on the wire.
class HTTPMethod {
  HTTPMethod._();
  static const String GET = "get";
  static const String POST = "post";
  static const String PATCH = "patch";
  static const String PUT = "put";
  static const String DELETE = "delete";
}
