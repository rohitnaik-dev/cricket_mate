import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/place.dart';

/// Provider for [SharedPreferences], overridden in main/tests.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with an initialized instance.',
  );
});

/// Typed record holding cached JSON payload alongside its storage timestamp.
typedef CachedData = ({Map<String, dynamic> data, DateTime savedAt});

/// Local key-value cache layer backed by [SharedPreferences].
/// Stores raw JSON data along with a `saved_at` timestamp per key/place.
class CacheStore {
  const CacheStore(this._prefs);

  final SharedPreferences _prefs;

  static const String selectedPlaceKey = 'cricket_mate_selected_place';
  static const String keyPrefix = 'weather_cache_';

  /// Generates a standardized cache key based on geographic coordinates.
  static String cacheKeyForCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
  }

  /// Generates a cache key for a given [Place].
  static String cacheKeyForPlace(Place place) {
    return cacheKeyForCoordinates(place.latitude, place.longitude);
  }

  /// Saves a raw JSON [data] map and its timestamp [savedAt] under [key].
  Future<bool> putJson(
    String key,
    Map<String, dynamic> data, {
    DateTime? savedAt,
  }) async {
    final timestamp = savedAt ?? DateTime.now();
    final envelope = <String, dynamic>{
      'saved_at': timestamp.toIso8601String(),
      'data': data,
    };
    return _prefs.setString('$keyPrefix$key', jsonEncode(envelope));
  }

  /// Retrieves cached raw JSON and its `savedAt` timestamp for [key].
  /// Returns null if missing or if the cached payload is corrupt.
  CachedData? getJson(String key) {
    final raw = _prefs.getString('$keyPrefix$key');
    if (raw == null || raw.isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final dynamic rawSavedAt = decoded['saved_at'];
      final dynamic rawData = decoded['data'];

      if (rawSavedAt is! String || rawData is! Map) return null;

      final parsedSavedAt = DateTime.tryParse(rawSavedAt);
      if (parsedSavedAt == null) return null;

      return (data: Map<String, dynamic>.from(rawData), savedAt: parsedSavedAt);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a cached entry for [key].
  Future<bool> remove(String key) async {
    return _prefs.remove('$keyPrefix$key');
  }

  /// Persists the user's currently selected cricket ground [place].
  Future<bool> saveSelectedPlace(Place place) async {
    return _prefs.setString(selectedPlaceKey, jsonEncode(place.toJson()));
  }

  /// Retrieves the persisted [Place], or null if none saved.
  Place? getSelectedPlace() {
    final raw = _prefs.getString(selectedPlaceKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Place.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  /// Clears the persisted selected place.
  Future<bool> clearSelectedPlace() async {
    return _prefs.remove(selectedPlaceKey);
  }
}

/// Riverpod provider for [CacheStore].
final cacheStoreProvider = Provider<CacheStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheStore(prefs);
});
