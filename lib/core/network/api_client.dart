import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';

export '../errors/app_exception.dart';

/// Provider exposing the singleton [ApiClient] instance.
/// Dio is managed internally with no direct Dio access outside this class.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Thin HTTP client wrapping [Dio] with enforced 10s timeouts,
/// a single [getJson] retrieval method, and consistent mapping to [AppException].
class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              responseType: ResponseType.json,
              headers: const <String, Object?>{'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  /// Performs an HTTP GET request and returns the deserialized JSON object map.
  /// Throws a strongly-typed [AppException] on network, timeout, server, or parsing failure.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is Map) {
        return Map<String, dynamic>.from(data);
      } else if (data == null) {
        throw const FormatException('Received empty or null response body');
      } else {
        throw FormatException(
          'Unexpected response data type: expected JSON object (Map) but got ${data.runtimeType}',
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapError(e);
    } on FormatException catch (e) {
      throw mapError(e);
    } on TypeError catch (e) {
      throw mapError(e);
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Maps errors, [DioException], [FormatException], and [TypeError] into
  /// strongly-typed [AppException] instances with user-facing message keys.
  static AppException mapError(Object error) {
    if (error is AppException) {
      return error;
    }

    if (error is FormatException) {
      return ParsingException(message: error.message, cause: error);
    }

    if (error is TypeError) {
      return ParsingException(message: error.toString(), cause: error);
    }

    if (error is DioException) {
      final Object? underlying = error.error;
      if (underlying is FormatException) {
        return ParsingException(message: underlying.message, cause: error);
      }
      if (underlying is TypeError) {
        return ParsingException(message: underlying.toString(), cause: error);
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          return RequestTimeoutException(
            message:
                error.message ?? 'The request timed out. Please try again.',
            cause: error,
          );
        case DioExceptionType.badResponse:
          final int? statusCode = error.response?.statusCode;
          return ServerException(
            statusCode: statusCode,
            message: 'Server returned error status: $statusCode',
            cause: error,
          );
        case DioExceptionType.cancel:
          return NetworkException(
            message: 'The request was cancelled.',
            cause: error,
          );
        case DioExceptionType.connectionError:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          return NetworkException(
            message: error.message ?? 'Unable to connect to the server.',
            cause: error,
          );
      }
    }

    return NetworkException(message: error.toString(), cause: error);
  }
}
