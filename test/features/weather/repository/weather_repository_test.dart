import 'package:cricket_mate/core/errors/app_exception.dart';
import 'package:cricket_mate/features/weather/data/cache_store.dart';
import 'package:cricket_mate/features/weather/data/weather_remote_data_source.dart';
import 'package:cricket_mate/features/weather/repository/weather_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixture_reader.dart';

class MockWeatherRemoteDataSource extends Mock
    implements WeatherRemoteDataSource {}

class MockCacheStore extends Mock implements CacheStore {}

void main() {
  late MockWeatherRemoteDataSource mockRemoteDataSource;
  late MockCacheStore mockCacheStore;
  late WeatherRepository repository;

  const testPlace = Place(
    name: "Lord's",
    latitude: 51.5298,
    longitude: -0.1722,
    timezone: 'Europe/London',
  );

  final expectedCacheKey = CacheStore.cacheKeyForPlace(testPlace);
  final sampleForecastJson = jsonFixture('forecast_normal.json');
  final sampleForecast = WeatherForecast.fromJson(sampleForecastJson);

  setUp(() {
    mockRemoteDataSource = MockWeatherRemoteDataSource();
    mockCacheStore = MockCacheStore();
    repository = WeatherRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      cacheStore: mockCacheStore,
    );
  });

  group('WeatherRepository.getForecast', () {
    test('on network success: saves raw JSON to cache and returns Loaded with fromCache: false', () async {
      when(
        () => mockRemoteDataSource.getForecast(
          latitude: testPlace.latitude,
          longitude: testPlace.longitude,
        ),
      ).thenAnswer((_) async => sampleForecast);

      when(
        () => mockCacheStore.putJson(
          expectedCacheKey,
          any(),
          savedAt: any(named: 'savedAt'),
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.getForecast(testPlace);

      expect(result.fromCache, isFalse);
      expect(result.data, equals(sampleForecast));
      expect(result.updatedAt, isNotNull);

      verify(
        () => mockCacheStore.putJson(
          expectedCacheKey,
          any(),
          savedAt: any(named: 'savedAt'),
        ),
      ).called(1);
    });

    test('on network failure: falls back to cached data with fromCache: true and original savedAt', () async {
      final cachedTimestamp = DateTime(2026, 9, 29, 10, 30);

      when(
        () => mockRemoteDataSource.getForecast(
          latitude: testPlace.latitude,
          longitude: testPlace.longitude,
        ),
      ).thenThrow(
        const NetworkException(
          messageKey: 'error_network_connection',
          message: 'Offline',
        ),
      );

      when(() => mockCacheStore.getJson(expectedCacheKey))
          .thenReturn((data: sampleForecastJson, savedAt: cachedTimestamp));

      final result = await repository.getForecast(testPlace);

      expect(result.fromCache, isTrue);
      expect(result.updatedAt, cachedTimestamp);
      expect(result.data.latitude, sampleForecast.latitude);
      expect(result.data.longitude, sampleForecast.longitude);
      expect(result.data.hourly.length, sampleForecast.hourly.length);
    });

    test(
      'on network failure without cache: rethrows the AppException',
      () async {
        when(
          () => mockRemoteDataSource.getForecast(
            latitude: testPlace.latitude,
            longitude: testPlace.longitude,
          ),
        ).thenThrow(
          const NetworkException(
            messageKey: 'error_network_connection',
            message: 'No internet connection',
          ),
        );

        when(() => mockCacheStore.getJson(expectedCacheKey)).thenReturn(null);

        expect(
          () => repository.getForecast(testPlace),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.messageKey,
              'messageKey',
              'error_network_connection',
            ),
          ),
        );
      },
    );

    test('on network failure with corrupted cache: rethrows the original network exception', () async {
      when(
        () => mockRemoteDataSource.getForecast(
          latitude: testPlace.latitude,
          longitude: testPlace.longitude,
        ),
      ).thenThrow(
        const RequestTimeoutException(
          messageKey: 'error_request_timeout',
          message: 'Timed out',
        ),
      );

      // Cache contains corrupted/unusable data
      when(() => mockCacheStore.getJson(expectedCacheKey)).thenReturn((
        data: <String, dynamic>{'invalid': 'no coordinates'},
        savedAt: DateTime.now(),
      ));

      expect(
        () => repository.getForecast(testPlace),
        throwsA(isA<RequestTimeoutException>()),
      );
    });
  });

  group('WeatherRepository delegated operations', () {
    test('searchPlaces forwards query to remote data source', () async {
      when(() => mockRemoteDataSource.searchPlaces('London'))
          .thenAnswer((_) async => [testPlace]);

      final results = await repository.searchPlaces('London');

      expect(results, equals([testPlace]));
      verify(() => mockRemoteDataSource.searchPlaces('London')).called(1);
    });

    test(
      'saveSelectedPlace and getSelectedPlace forward to cacheStore',
      () async {
        when(() => mockCacheStore.saveSelectedPlace(testPlace))
            .thenAnswer((_) async => true);
        when(() => mockCacheStore.getSelectedPlace()).thenReturn(testPlace);

        await repository.saveSelectedPlace(testPlace);
        verify(() => mockCacheStore.saveSelectedPlace(testPlace)).called(1);

        final retrieved = repository.getSelectedPlace();
        expect(retrieved, equals(testPlace));
        verify(() => mockCacheStore.getSelectedPlace()).called(1);
      },
    );
  });
}
