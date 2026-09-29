import 'package:cricket_mate/core/errors/app_exception.dart';
import 'package:cricket_mate/features/weather/data/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixture_reader.dart';

void main() {
  group('Place model', () {
    test('parses normal geocoding JSON results successfully', () {
      final json = jsonFixture('geocoding_success.json');
      final results = json['results'] as List<dynamic>;

      final place1 = Place.fromJson(
        Map<String, dynamic>.from(results[0] as Map),
      );
      expect(place1.name, 'London');
      expect(place1.latitude, 51.50853);
      expect(place1.longitude, -0.12574);
      expect(place1.timezone, 'Europe/London');
      expect(place1.country, 'United Kingdom');
      expect(place1.admin1, 'England');
      expect(place1.displayName, "London, England, United Kingdom");

      final place2 = Place.fromJson(
        Map<String, dynamic>.from(results[1] as Map),
      );
      expect(place2.name, 'London');
      expect(place2.latitude, 42.98339);
      expect(place2.longitude, -81.23304);
      expect(place2.timezone, 'America/Toronto');
      expect(place2.country, 'Canada');
      expect(place2.admin1, 'Ontario');
    });

    test('toJson produces expected map and preserves equality', () {
      const place = Place(
        name: "Melbourne Cricket Ground",
        latitude: -37.8199,
        longitude: 144.9834,
        timezone: 'Australia/Melbourne',
        admin1: 'Victoria',
        country: 'Australia',
      );

      final map = place.toJson();
      final roundTrip = Place.fromJson(map);

      expect(roundTrip, equals(place));
      expect(roundTrip.hashCode, equals(place.hashCode));
    });

    test('throws ParsingException when name is missing or empty', () {
      expect(
        () => Place.fromJson(<String, dynamic>{
          'latitude': 10.0,
          'longitude': 20.0,
        }),
        throwsA(isA<ParsingException>()),
      );

      expect(
        () => Place.fromJson(<String, dynamic>{
          'name': '   ',
          'latitude': 10.0,
          'longitude': 20.0,
        }),
        throwsA(isA<ParsingException>()),
      );
    });

    test('throws ParsingException when latitude or longitude is missing', () {
      expect(
        () => Place.fromJson(<String, dynamic>{
          'name': 'Wankhede',
          'longitude': 72.82,
        }),
        throwsA(isA<ParsingException>()),
      );

      expect(
        () => Place.fromJson(<String, dynamic>{
          'name': 'Eden Gardens',
          'latitude': 22.56,
        }),
        throwsA(isA<ParsingException>()),
      );
    });
  });
}
