import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'models/place.dart';
import 'models/weather_forecast.dart';

/// Abstract contract for fetching weather and geocoding data from remote services.
abstract interface class WeatherRemoteDataSource {
  /// Searches for matching locations by name.
  Future<List<Place>> searchPlaces(String query);

  /// Fetches weather forecast and solar astronomy for given coordinates.
  Future<WeatherForecast> getForecast({
    required double latitude,
    required double longitude,
  });
}

/// Open-Meteo implementation of [WeatherRemoteDataSource].
/// Enforces non-commercial usage rules: requests only required variables,
/// uses auto timezone, and limits forecast window.
class OpenMeteoRemoteDataSource implements WeatherRemoteDataSource {
  OpenMeteoRemoteDataSource({
    required this.apiClient,
    this.geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search',
    this.forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast',
  });

  final ApiClient apiClient;
  final String geocodingBaseUrl;
  final String forecastBaseUrl;

  /// Required hourly variables for cricket suitability analysis.
  static const String hourlyVariables =
      'temperature_2m,apparent_temperature,relative_humidity_2m,dew_point_2m,'
      'precipitation_probability,precipitation,wind_speed_10m,wind_gusts_10m,'
      'uv_index,weather_code,is_day';

  /// Required daily solar variables for match scheduling.
  static const String dailyVariables = 'sunrise,sunset';

  @override
  Future<List<Place>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <Place>[];

    final json = await apiClient.getJson(
      geocodingBaseUrl,
      queryParameters: <String, dynamic>{
        'name': trimmed,
        'count': 10,
        'language': 'en',
        'format': 'json',
      },
    );

    final dynamic rawResults = json['results'];
    if (rawResults is! List) return const <Place>[];

    final places = <Place>[];
    for (final item in rawResults) {
      if (item is Map) {
        places.add(Place.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return List<Place>.unmodifiable(places);
  }

  @override
  Future<WeatherForecast> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    final json = await apiClient.getJson(
      forecastBaseUrl,
      queryParameters: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'timezone': 'auto',
        'past_days': 1,
        'forecast_days': 3,
        'hourly': hourlyVariables,
        'daily': dailyVariables,
      },
    );

    return WeatherForecast.fromJson(json);
  }
}

/// Riverpod provider for the [WeatherRemoteDataSource].
final weatherRemoteDataSourceProvider = Provider<WeatherRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return OpenMeteoRemoteDataSource(apiClient: apiClient);
});
