/// Sealed class hierarchy representing domain and application exceptions.
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Network communication error (HTTP failures, timeouts, offline).
final class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause, this.statusCode]);

  final int? statusCode;
}

/// Data parsing or deserialization error.
final class ParseException extends AppException {
  const ParseException(super.message, [super.cause]);
}

/// Local storage or cache retrieval error.
final class CacheException extends AppException {
  const CacheException(super.message, [super.cause]);
}

/// Fallback unexpected error.
final class UnknownException extends AppException {
  const UnknownException([
    super.message = 'An unexpected error occurred. Please try again.',
    super.cause,
  ]);
}
