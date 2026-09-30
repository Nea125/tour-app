abstract class BaseHttpException implements Exception {
  final String message;

  BaseHttpException(this.message);

  @override
  String toString() => message;
}

/// Transport or HTTP-status failure. [code] is the HTTP status when the
/// server answered (e.g. 404, 401), `null` for connection/timeout errors.
class DioErrorHttpException extends BaseHttpException {
  final int? code;

  DioErrorHttpException(super.message, {this.code});
}

/// Unexpected client-side failure (bad JSON shape, type errors, ...).
class ServerErrorHttpException extends BaseHttpException {
  ServerErrorHttpException(super.message);
}

/// The server answered 2xx but the body wasn't usable.
class ServerResponseHttpException extends BaseHttpException {
  ServerResponseHttpException(super.message);
}
