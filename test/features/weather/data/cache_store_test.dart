import 'package:cricket_mate/features/weather/data/cache_store.dart';
import 'package:cricket_mate/features/weather/data/models/place.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late CacheStore cacheStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    cacheStore = CacheStore(prefs);
  });

  group('CacheStore', () {
    test(
      'putJson and getJson stores and retrieves raw JSON and savedAt timestamp',
      () async {
        final sampleData = <String, dynamic>{
          'latitude': 51.5,
          'longitude': -0.12,
          'elevation': 16.0,
        };
        final now = DateTime(2026, 9, 29, 12, 0, 0);

        final success = await cacheStore.putJson(
          'london',
          sampleData,
          savedAt: now,
        );
        expect(success, isTrue);

        final cached = cacheStore.getJson('london');
        expect(cached, isNotNull);
        expect(cached!.data['latitude'], 51.5);
        expect(cached.data['longitude'], -0.12);
        expect(cached.savedAt, now);
      },
    );

    test('getJson returns null when key does not exist', () {
      final cached = cacheStore.getJson('non_existent_venue');
      expect(cached, isNull);
    });

    test(
      'getJson returns null when stored data is malformed or invalid',
      () async {
        await prefs.setString(
          '${CacheStore.keyPrefix}broken',
          'not-valid-json',
        );
        expect(cacheStore.getJson('broken'), isNull);

        await prefs.setString(
          '${CacheStore.keyPrefix}missing_saved_at',
          '{"data": {"key": "val"}}',
        );
        expect(cacheStore.getJson('missing_saved_at'), isNull);

        await prefs.setString(
          '${CacheStore.keyPrefix}invalid_saved_at_date',
          '{"saved_at": "not-a-date", "data": {"key": "val"}}',
        );
        expect(cacheStore.getJson('invalid_saved_at_date'), isNull);
      },
    );

    test('remove deletes cached entry', () async {
      await cacheStore.putJson('to_delete', <String, dynamic>{'temp': 20.0});
      expect(cacheStore.getJson('to_delete'), isNotNull);

      await cacheStore.remove('to_delete');
      expect(cacheStore.getJson('to_delete'), isNull);
    });

    test(
      'saveSelectedPlace and getSelectedPlace persist and restore Place',
      () async {
        const place = Place(
          name: "Lord's Cricket Ground",
          latitude: 51.5298,
          longitude: -0.1722,
          timezone: 'Europe/London',
          admin1: 'England',
          country: 'United Kingdom',
        );

        final success = await cacheStore.saveSelectedPlace(place);
        expect(success, isTrue);

        final restored = cacheStore.getSelectedPlace();
        expect(restored, equals(place));
        expect(
          restored?.displayName,
          "Lord's Cricket Ground, England, United Kingdom",
        );
      },
    );

    test('clearSelectedPlace removes persisted place', () async {
      const place = Place(
        name: 'Eden Gardens',
        latitude: 22.5646,
        longitude: 88.3433,
        timezone: 'Asia/Kolkata',
      );
      await cacheStore.saveSelectedPlace(place);
      expect(cacheStore.getSelectedPlace(), isNotNull);

      await cacheStore.clearSelectedPlace();
      expect(cacheStore.getSelectedPlace(), isNull);
    });

    test('cache survives simulated app restart by re-reading from SharedPreferences', () async {
      const place = Place(
        name: 'The Oval',
        latitude: 51.4838,
        longitude: -0.1149,
        timezone: 'Europe/London',
      );
      await cacheStore.saveSelectedPlace(place);
      await cacheStore.putJson('oval_cache', <String, dynamic>{
        'weather': 'sunny',
      }, savedAt: DateTime(2026, 9, 29, 15, 0));

      // Simulate app restart by instantiating new CacheStore with the same SharedPreferences
      final restartedCacheStore = CacheStore(prefs);

      expect(restartedCacheStore.getSelectedPlace(), equals(place));
      final cached = restartedCacheStore.getJson('oval_cache');
      expect(cached, isNotNull);
      expect(cached!.data['weather'], 'sunny');
      expect(cached.savedAt, DateTime(2026, 9, 29, 15, 0));
    });
  });
}
