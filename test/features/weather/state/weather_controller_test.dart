import 'package:cricket_mate/core/errors/app_exception.dart';
import 'package:cricket_mate/core/state/view_state.dart';
import 'package:cricket_mate/features/weather/repository/weather_repository.dart';
import 'package:cricket_mate/features/weather/state/weather_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late MockWeatherRepository mockRepo;
  late WeatherController controller;

  const testPlace = Place(
    name: 'Sydney',
    country: 'Australia',
    latitude: -33.8688,
    longitude: 151.2093,
    timezone: 'Australia/Sydney',
  );

  final testForecast = WeatherForecast(
    latitude: -33.8688,
    longitude: 151.2093,
    timezone: 'Australia/Sydney',
    utcOffsetSeconds: 36000,
    hourly: [
      HourlyWeather(time: DateTime(2026, 9, 30, 10, 0), temperature2m: 23.0),
    ],
    dailyAstro: const [],
  );

  setUp(() {
    mockRepo = MockWeatherRepository();
    controller = WeatherController(mockRepo);
  });

  group('WeatherController', () {
    test('transitions: Loading -> Success(data, fromCache: false) on fresh network fetch', () async {
      final now = DateTime(2026, 9, 30, 10, 0);
      when(() => mockRepo.getForecast(testPlace))
          .thenAnswer((_) async => Loaded(testForecast, now, fromCache: false));

      final future = controller.fetchForecast(testPlace);
      expect(controller.state.isLoading, isTrue);

      await future;

      expect(controller.state.isSuccess, isTrue);
      final success = controller.state as ViewSuccess<WeatherForecast>;
      expect(success.data, equals(testForecast));
      expect(success.fromCache, isFalse);
      expect(success.updatedAt, equals(now));
    });

    test('transitions: Loading -> Success(data, fromCache: true) when served from cache', () async {
      final cachedTime = DateTime(2026, 9, 30, 8, 0);
      when(() => mockRepo.getForecast(testPlace)).thenAnswer(
        (_) async => Loaded(testForecast, cachedTime, fromCache: true),
      );

      await controller.fetchForecast(testPlace);

      expect(controller.state.isSuccess, isTrue);
      final success = controller.state as ViewSuccess<WeatherForecast>;
      expect(success.fromCache, isTrue);
      expect(success.updatedAt, equals(cachedTime));
    });

    test('transitions: Loading -> Failure on AppException', () async {
      when(() => mockRepo.getForecast(testPlace))
          .thenThrow(const ServerException(statusCode: 503));

      await controller.fetchForecast(testPlace);

      expect(controller.state.isFailure, isTrue);
      final failure = controller.state as ViewFailure<WeatherForecast>;
      expect(failure.exception, isA<ServerException>());
      expect((failure.exception as ServerException).statusCode, equals(503));
    });
  });
}
