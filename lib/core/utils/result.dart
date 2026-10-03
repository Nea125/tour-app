import '../error/failures.dart';
import '../network/dio_exception.dart';
import '../network/dio_helper.dart';


sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Error<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Error<T>) return failure(self.failure);
    throw StateError('Unreachable');
  }

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  Failure? get failureOrNull =>
      this is Error<T> ? (this as Error<T>).failure : null;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}

Future<Result<T>> guardResult<T>(Future<T> Function() body) async {
  try {
    return Success(await body());
  } catch (e) {
    final message = DIOHelper.i.handleExceptionError(e);
    if (e is DioErrorHttpException) {
      final code = e.code;
      if (code == 404) return Error(NotFoundFailure(message));
      if (code != null && code >= 400 && code < 500) {
        return Error(ValidationFailure(message));
      }
      return Error(ServerFailure(message));
    }
    if (e is BaseHttpException) return Error(ServerFailure(message));
    return Error(ValidationFailure(message));
  }
}
