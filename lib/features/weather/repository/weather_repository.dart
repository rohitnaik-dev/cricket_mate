import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/cache_store.dart';
import '../data/models/place.dart';
import '../data/models/weather_forecast.dart';
import '../data/weather_remote_data_source.dart';

export '../data/models/daily_astro.dart';
export '../data/models/hourly_weather.dart';
export '../data/models/place.dart';
export '../data/models/weather_forecast.dart';

/// Immutable container holding loaded domain data alongside cache metadata.
@immutable
class Loaded<T> {
  const Loaded(this.data, this.updatedAt, {required this.fromCache});

  /// The domain payload.
  final T data;

  /// Timestamp when the data was saved or updated.
  final DateTime updatedAt;

  /// True if served from local storage/cache, false if freshly fetched from the network.
  final bool fromCache;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Loaded<T> &&
        other.data == data &&
        other.updatedAt == updatedAt &&
        other.fromCache == fromCache;
  }

  @override
  int get hashCode => Object.hash(data, updatedAt, fromCache);

  @override
  String toString() =>
      'Loaded(fromCache: $fromCache, updatedAt: $updatedAt, data: $data)';
}

/// Specialized type alias for weather forecast results.
typedef WeatherLoaded = Loaded<WeatherForecast>;

/// Abstract contract for weather operations, bridging remote data sources and local caching.
abstract interface class WeatherRepository {
  /// Searches for matching cricket grounds or cities by name.
  Future<List<Place>> searchPlaces(String query);

  /// Fetches weather forecast for [place].
  /// Network success -> caches raw JSON and returns Loaded(data, updatedAt, fromCache: false).
  /// Network failure -> returns cached data with fromCache: true and its savedAt;
  /// if no cache -> rethrows AppException.
  Future<Loaded<WeatherForecast>> getForecast(Place place);

  /// Persists the user's selected [place].
  Future<void> saveSelectedPlace(Place place);

  /// Retrieves the persisted selected [Place], or null if none saved.
  Place? getSelectedPlace();
}

/// Production implementation of [WeatherRepository] adhering to the cache-fallback strategy.
class WeatherRepositoryImpl implements WeatherRepository {
  const WeatherRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheStore,
  });

  final WeatherRemoteDataSource remoteDataSource;
  final CacheStore cacheStore;

  @override
  Future<List<Place>> searchPlaces(String query) {
    return remoteDataSource.searchPlaces(query);
  }

  @override
  Future<Loaded<WeatherForecast>> getForecast(Place place) async {
    final cacheKey = CacheStore.cacheKeyForPlace(place);

    try {
      final forecast = await remoteDataSource.getForecast(
        latitude: place.latitude,
        longitude: place.longitude,
      );

      final now = DateTime.now();

      // On network success: serialize and write raw JSON to persistent cache
      await cacheStore.putJson(cacheKey, forecast.toJson(), savedAt: now);

      return Loaded(forecast, now, fromCache: false);
    } on AppException catch (appError) {
      // On network or app failure: fall back to cached data if present
      final cached = cacheStore.getJson(cacheKey);
      if (cached != null) {
        try {
          final cachedForecast = WeatherForecast.fromJson(cached.data);
          return Loaded(cachedForecast, cached.savedAt, fromCache: true);
        } catch (_) {
          // If cached JSON payload was corrupted, throw original network exception
          throw appError;
        }
      }
      rethrow;
    } catch (e) {
      // For any unmapped error, map to AppException first
      final mapped = ApiClient.mapError(e);
      final cached = cacheStore.getJson(cacheKey);
      if (cached != null) {
        try {
          final cachedForecast = WeatherForecast.fromJson(cached.data);
          return Loaded(cachedForecast, cached.savedAt, fromCache: true);
        } catch (_) {
          throw mapped;
        }
      }
      throw mapped;
    }
  }

  @override
  Future<void> saveSelectedPlace(Place place) {
    return cacheStore.saveSelectedPlace(place);
  }

  @override
  Place? getSelectedPlace() {
    return cacheStore.getSelectedPlace();
  }
}

/// Riverpod provider for [WeatherRepository].
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final remoteDataSource = ref.watch(weatherRemoteDataSourceProvider);
  final cacheStore = ref.watch(cacheStoreProvider);
  return WeatherRepositoryImpl(
    remoteDataSource: remoteDataSource,
    cacheStore: cacheStore,
  );
});
