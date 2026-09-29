/// Sealed class hierarchy representing domain, network, and data parsing exceptions.
sealed class AppException implements Exception {
  const AppException({
    required this.messageKey,
    required this.message,
    this.cause,
  });

  /// Translation or localization key for user-facing error presentation.
  final String messageKey;

  /// Human-readable diagnostic description of the error.
  final String message;

  /// Underlying error or exception cause, if any.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message (key: $messageKey)';
}

/// Network communication error (offline, DNS failure, connection dropped).
final class NetworkException extends AppException {
  const NetworkException({
    super.messageKey = 'error_network_connection',
    super.message = 'Unable to connect to the server. Please check your internet connection.',
    super.cause,
  });
}

/// Request timeout error (connection, send, receive, or transform timed out).
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException({
    super.messageKey = 'error_request_timeout',
    super.message = 'The request timed out. Please try again.',
    super.cause,
  });
}

/// Server-side HTTP error response (e.g. 4xx, 5xx status codes).
final class ServerException extends AppException {
  const ServerException({
    this.statusCode,
    super.messageKey = 'error_server',
    super.message = 'The server encountered an error. Please try again later.',
    super.cause,
  });

  /// HTTP status code returned by the server, if available.
  final int? statusCode;

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode): $message (key: $messageKey)';
}

/// Data parsing or type conversion error when decoding response payloads.
final class ParsingException extends AppException {
  const ParsingException({
    super.messageKey = 'error_parsing_failed',
    super.message = 'Failed to process server response data.',
    super.cause,
  });
}
