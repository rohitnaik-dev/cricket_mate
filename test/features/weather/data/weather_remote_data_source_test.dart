import 'package:cricket_mate/core/network/api_client.dart';
import 'package:cricket_mate/features/weather/data/models/place.dart';
import 'package:cricket_mate/features/weather/data/models/weather_forecast.dart';
import 'package:cricket_mate/features/weather/data/weather_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixture_reader.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late OpenMeteoRemoteDataSource dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = OpenMeteoRemoteDataSource(apiClient: mockApiClient);
  });

  group('OpenMeteoRemoteDataSource.searchPlaces', () {
    test(
      'returns empty list immediately when query is empty or whitespace',
      () async {
        final result1 = await dataSource.searchPlaces('');
        final result2 = await dataSource.searchPlaces('   ');

        expect(result1, isEmpty);
        expect(result2, isEmpty);
        verifyZeroInteractions(mockApiClient);
      },
    );

    test('calls geocoding endpoint with correct parameters and returns places list', () async {
      final fixture = jsonFixture('geocoding_success.json');
      when(
        () => mockApiClient.getJson(
          dataSource.geocodingBaseUrl,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => fixture);

      final places = await dataSource.searchPlaces('London');

      expect(places.length, 2);
      expect(places[0], isA<Place>());
      expect(places[0].name, 'London');
      expect(places[0].country, 'United Kingdom');
      expect(places[1].country, 'Canada');

      verify(
        () => mockApiClient.getJson(
          dataSource.geocodingBaseUrl,
          queryParameters: <String, dynamic>{
            'name': 'London',
            'count': 10,
            'language': 'en',
            'format': 'json',
          },
        ),
      ).called(1);
    });

    test('returns empty list when geocoding response has no results', () async {
      final fixture = jsonFixture('geocoding_empty.json');
      when(
        () => mockApiClient.getJson(
          dataSource.geocodingBaseUrl,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => fixture);

      final places = await dataSource.searchPlaces('NonExistentPitchXYZ');

      expect(places, isEmpty);
    });
  });

  group('OpenMeteoRemoteDataSource.getForecast', () {
    test('requests strictly required variables with timezone=auto, past_days=1, forecast_days=3', () async {
      final fixture = jsonFixture('forecast_normal.json');
      when(
        () => mockApiClient.getJson(
          dataSource.forecastBaseUrl,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => fixture);

      const lat = 51.51;
      const lng = -0.13;
      final forecast = await dataSource.getForecast(
        latitude: lat,
        longitude: lng,
      );

      expect(forecast, isA<WeatherForecast>());
      expect(forecast.latitude, 51.51);
      expect(forecast.hourly.length, 3);
      expect(forecast.dailyAstro.length, 1);

      verify(
        () => mockApiClient.getJson(
          dataSource.forecastBaseUrl,
          queryParameters: <String, dynamic>{
            'latitude': lat,
            'longitude': lng,
            'timezone': 'auto',
            'past_days': 1,
            'forecast_days': 3,
            'hourly': OpenMeteoRemoteDataSource.hourlyVariables,
            'daily': OpenMeteoRemoteDataSource.dailyVariables,
          },
        ),
      ).called(1);

      // Verify exact variables requested match user requirements
      expect(
        OpenMeteoRemoteDataSource.hourlyVariables,
        'temperature_2m,apparent_temperature,relative_humidity_2m,dew_point_2m,'
        'precipitation_probability,precipitation,wind_speed_10m,wind_gusts_10m,'
        'uv_index,weather_code,is_day',
      );
      expect(OpenMeteoRemoteDataSource.dailyVariables, 'sunrise,sunset');
    });
  });
}
