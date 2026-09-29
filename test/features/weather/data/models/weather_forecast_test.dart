import 'package:cricket_mate/core/errors/app_exception.dart';
import 'package:cricket_mate/features/weather/data/models/weather_forecast.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixture_reader.dart';

void main() {
  group('WeatherForecast model', () {
    test('parses normal complete forecast JSON successfully', () {
      final json = jsonFixture('forecast_normal.json');
      final forecast = WeatherForecast.fromJson(json);

      expect(forecast.latitude, 51.51);
      expect(forecast.longitude, -0.13);
      expect(forecast.timezone, 'Europe/London');
      expect(forecast.utcOffsetSeconds, 3600);
      expect(forecast.elevation, 16.0);
      expect(forecast.hourly.length, 3);
      expect(forecast.dailyAstro.length, 1);

      // Hourly element checks
      final firstHour = forecast.hourly[0];
      expect(firstHour.time, DateTime.parse('2026-09-28T09:00'));
      expect(firstHour.temperature2m, 15.2);
      expect(firstHour.apparentTemperature, 14.8);
      expect(firstHour.relativeHumidity2m, 74);
      expect(firstHour.dewPoint2m, 10.5);
      expect(firstHour.precipitationProbability, 0);
      expect(firstHour.precipitation, 0.0);
      expect(firstHour.windSpeed10m, 7.6);
      expect(firstHour.windGusts10m, 14.2);
      expect(firstHour.uvIndex, 2.5);
      expect(firstHour.weatherCode, 0);
      expect(firstHour.isDay, isTrue);
      expect(firstHour.isDry, isTrue);
      expect(firstHour.weatherDescription, 'Clear Sky');

      // Daily element checks
      final astro = forecast.dailyAstro[0];
      expect(astro.date, DateTime.parse('2026-09-28'));
      expect(astro.sunrise, DateTime.parse('2026-09-28T06:56'));
      expect(astro.sunset, DateTime.parse('2026-09-28T18:45'));

      // Roundtrip toJson equality
      final map = forecast.toJson();
      final roundTrip = WeatherForecast.fromJson(map);
      expect(roundTrip, equals(forecast));
      expect(roundTrip.hashCode, equals(forecast.hashCode));
    });

    test('parses forecast with null values defensively without crashing', () {
      final json = jsonFixture('forecast_null_values.json');
      final forecast = WeatherForecast.fromJson(json);

      expect(forecast.hourly.length, 3);

      final secondHour = forecast.hourly[1];
      expect(secondHour.temperature2m, isNull);
      expect(secondHour.apparentTemperature, 34.2);
      expect(secondHour.relativeHumidity2m, isNull);
      expect(secondHour.dewPoint2m, 21.0);
      expect(secondHour.precipitationProbability, isNull);
      expect(secondHour.precipitation, isNull);
      expect(secondHour.windSpeed10m, 12.0);
      expect(secondHour.uvIndex, isNull);
      expect(secondHour.weatherCode, isNull);
      expect(secondHour.isDay, isNull);
      expect(secondHour.weatherDescription, 'Unknown');

      final astro = forecast.dailyAstro[0];
      expect(astro.sunrise, isNull);
      expect(astro.sunset, DateTime.parse('2026-09-28T18:15'));
    });

    test(
      'parses forecast with mismatched and missing array lengths safely',
      () {
        final json = jsonFixture('forecast_mismatched_arrays.json');
        final forecast = WeatherForecast.fromJson(json);

        // time array has 4 items
        expect(forecast.hourly.length, 4);

        // temperature_2m only had 2 items
        expect(forecast.hourly[0].temperature2m, 19.0);
        expect(forecast.hourly[1].temperature2m, 20.5);
        expect(forecast.hourly[2].temperature2m, isNull);
        expect(forecast.hourly[3].temperature2m, isNull);

        // dew_point_2m was completely absent
        for (final h in forecast.hourly) {
          expect(h.dewPoint2m, isNull);
        }

        // daily has date but missing sunrise/sunset arrays
        expect(forecast.dailyAstro.length, 1);
        expect(forecast.dailyAstro[0].sunrise, isNull);
        expect(forecast.dailyAstro[0].sunset, isNull);
      },
    );

    test('throws ParsingException when latitude or longitude is missing', () {
      expect(
        () => WeatherForecast.fromJson(<String, dynamic>{
          'longitude': 10.0,
          'hourly': <String, dynamic>{
            'time': ['2026-09-28T10:00'],
          },
        }),
        throwsA(isA<ParsingException>()),
      );

      expect(
        () => WeatherForecast.fromJson(<String, dynamic>{
          'latitude': 50.0,
          'hourly': <String, dynamic>{
            'time': ['2026-09-28T10:00'],
          },
        }),
        throwsA(isA<ParsingException>()),
      );
    });

    test(
      'throws ParsingException when hourly object or time array is missing',
      () {
        expect(
          () => WeatherForecast.fromJson(<String, dynamic>{
            'latitude': 50.0,
            'longitude': 10.0,
          }),
          throwsA(isA<ParsingException>()),
        );

        expect(
          () => WeatherForecast.fromJson(<String, dynamic>{
            'latitude': 50.0,
            'longitude': 10.0,
            'hourly': <String, dynamic>{'time': <dynamic>[]},
          }),
          throwsA(isA<ParsingException>()),
        );
      },
    );
  });
}
