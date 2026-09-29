import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';

/// Provider exposing the configured [Dio] instance for the application.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: <String, Object?>{'Accept': 'application/json'},
    ),
  );

  return dio;
});

/// Shared network client utility converting Dio responses and errors
/// into typed [AppException] instances.
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  /// Executes an HTTP GET request and returns the parsed JSON response body.
  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        url,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException('Unexpected network error', e);
    }
  }

  AppException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
          'Connection timed out. Please check your network.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return NetworkException(
          'Server returned an error status: $statusCode',
          error,
          statusCode,
        );
      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled.');
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Unable to reach server. Please check your internet connection.',
        );
      case DioExceptionType.badCertificate:
        return const NetworkException(
          'Security certificate verification failed.',
        );
      case DioExceptionType.unknown:
        return NetworkException(
          error.message ?? 'A network communication error occurred.',
          error,
        );
    }
  }
}

/// Provider exposing the [ApiClient] utility.
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
