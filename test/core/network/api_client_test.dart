import 'package:cricket_mate/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ApiClient apiClient;
  final RequestOptions dummyRequestOptions = RequestOptions(path: '/test');

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDio = MockDio();
    apiClient = ApiClient(dio: mockDio);
  });

  TypeError createTypeError() {
    try {
      const dynamic notAnInt = 'not_a_number';
      final int _ = notAnInt as int;
      throw StateError('Unreachable');
    } on TypeError catch (e) {
      return e;
    }
  }

  group('ApiClient.getJson', () {
    test('returns decoded JSON map on 200 response', () async {
      when(
        () => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: dummyRequestOptions,
          statusCode: 200,
          data: <String, Object?>{
            'latitude': 51.5,
            'longitude': -0.12,
            'current': <String, Object?>{'temperature': 20.5},
          },
        ),
      );

      final result = await apiClient.getJson('/test');

      expect(result['latitude'], 51.5);
      expect(result['longitude'], -0.12);
      expect(result['current'], isA<Map<String, dynamic>>());
    });

    test('throws ParsingException when response data is not a Map', () async {
      when(
        () => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: dummyRequestOptions,
          statusCode: 200,
          data: 'invalid json string payload',
        ),
      );

      expect(
        () => apiClient.getJson('/test'),
        throwsA(
          isA<ParsingException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error_parsing_failed',
          ),
        ),
      );
    });

    test('throws ParsingException when response data is null', () async {
      when(
        () => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: dummyRequestOptions,
          statusCode: 200,
          data: null,
        ),
      );

      expect(
        () => apiClient.getJson('/test'),
        throwsA(
          isA<ParsingException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error_parsing_failed',
          ),
        ),
      );
    });

    test('throws RequestTimeoutException on connection timeout', () async {
      when(
        () => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => apiClient.getJson('/test'),
        throwsA(
          isA<RequestTimeoutException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error_request_timeout',
          ),
        ),
      );
    });

    test(
      'throws ServerException with status code on badResponse (500)',
      () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: dummyRequestOptions,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: dummyRequestOptions,
              statusCode: 500,
            ),
          ),
        );

        expect(
          () => apiClient.getJson('/test'),
          throwsA(
            isA<ServerException>()
                .having((e) => e.statusCode, 'statusCode', 500)
                .having((e) => e.messageKey, 'messageKey', 'error_server'),
          ),
        );
      },
    );
  });

  group('ApiClient.mapError', () {
    test('maps connection, receive, send, and transform timeouts to RequestTimeoutException', () {
      final types = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ];

      for (final type in types) {
        final dioException = DioException(
          requestOptions: dummyRequestOptions,
          type: type,
        );
        final mapped = ApiClient.mapError(dioException);

        expect(mapped, isA<RequestTimeoutException>());
        expect(mapped.messageKey, 'error_request_timeout');
      }
    });

    test('maps badResponse to ServerException preserving statusCode', () {
      final dioException = DioException(
        requestOptions: dummyRequestOptions,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: dummyRequestOptions,
          statusCode: 404,
        ),
      );

      final mapped = ApiClient.mapError(dioException);

      expect(mapped, isA<ServerException>());
      final serverEx = mapped as ServerException;
      expect(serverEx.statusCode, 404);
      expect(serverEx.messageKey, 'error_server');
    });

    test('maps connectionError, cancel, badCertificate, and unknown to NetworkException', () {
      final types = [
        DioExceptionType.connectionError,
        DioExceptionType.cancel,
        DioExceptionType.badCertificate,
        DioExceptionType.unknown,
      ];

      for (final type in types) {
        final dioException = DioException(
          requestOptions: dummyRequestOptions,
          type: type,
        );
        final mapped = ApiClient.mapError(dioException);

        expect(mapped, isA<NetworkException>());
        expect(mapped.messageKey, 'error_network_connection');
      }
    });

    test('maps FormatException directly to ParsingException', () {
      const formatException = FormatException('Invalid JSON token');
      final mapped = ApiClient.mapError(formatException);

      expect(mapped, isA<ParsingException>());
      expect(mapped.messageKey, 'error_parsing_failed');
      expect(mapped.message, 'Invalid JSON token');
      expect(mapped.cause, formatException);
    });

    test('maps TypeError directly to ParsingException', () {
      final typeError = createTypeError();
      final mapped = ApiClient.mapError(typeError);

      expect(mapped, isA<ParsingException>());
      expect(mapped.messageKey, 'error_parsing_failed');
      expect(mapped.cause, typeError);
    });

    test('maps DioException wrapping FormatException to ParsingException', () {
      final dioException = DioException(
        requestOptions: dummyRequestOptions,
        error: const FormatException('Malformed payload'),
      );

      final mapped = ApiClient.mapError(dioException);

      expect(mapped, isA<ParsingException>());
      expect(mapped.messageKey, 'error_parsing_failed');
      expect(mapped.message, 'Malformed payload');
    });

    test('maps DioException wrapping TypeError to ParsingException', () {
      final typeError = createTypeError();
      final dioException = DioException(
        requestOptions: dummyRequestOptions,
        error: typeError,
      );

      final mapped = ApiClient.mapError(dioException);

      expect(mapped, isA<ParsingException>());
      expect(mapped.messageKey, 'error_parsing_failed');
    });

    test('returns existing AppException unchanged', () {
      const existing = NetworkException(
        messageKey: 'custom_key',
        message: 'Custom message',
      );
      final mapped = ApiClient.mapError(existing);

      expect(identical(mapped, existing), isTrue);
    });
  });
}
