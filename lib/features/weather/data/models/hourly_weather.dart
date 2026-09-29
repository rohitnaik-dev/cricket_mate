import 'package:flutter/foundation.dart';

/// Immutable model representing weather conditions for a single hour.
/// All meteorological variables are nullable-safe to gracefully tolerate partial or omitted sensor data.
@immutable
class HourlyWeather {
  const HourlyWeather({
    required this.time,
    this.temperature2m,
    this.apparentTemperature,
    this.relativeHumidity2m,
    this.dewPoint2m,
    this.precipitationProbability,
    this.precipitation,
    this.windSpeed10m,
    this.windGusts10m,
    this.uvIndex,
    this.weatherCode,
    this.isDay,
  });

  /// Timestamp for this hour.
  final DateTime time;

  /// Air temperature at 2 meters above ground in °C.
  final double? temperature2m;

  /// Apparent ("feels-like") temperature in °C.
  final double? apparentTemperature;

  /// Relative humidity percentage (0-100%).
  final int? relativeHumidity2m;

  /// Dew point temperature in °C.
  final double? dewPoint2m;

  /// Probability of precipitation (0-100%).
  final int? precipitationProbability;

  /// Total precipitation amount in millimeters (rain, showers, snow).
  final double? precipitation;

  /// Sustained wind speed at 10 meters above ground in km/h.
  final double? windSpeed10m;

  /// Peak wind gust speed at 10 meters above ground in km/h.
  final double? windGusts10m;

  /// Ultraviolet radiation index (0+).
  final double? uvIndex;

  /// WMO weather interpretation code (e.g. 0 = clear sky, 51-67 = rain).
  final int? weatherCode;

  /// Whether this hour falls during daytime (true) or nighttime (false).
  final bool? isDay;

  /// Convenient helper to check if this hour is dry and suitable for fielding.
  bool get isDry => (precipitation ?? 0.0) <= 0.0;

  /// Convenient helper to check if high precipitation is expected.
  bool get isRainLikely =>
      (precipitationProbability ?? 0) >= 50 || (precipitation ?? 0.0) > 0.5;

  /// Human-readable WMO weather description.
  String get weatherDescription {
    final code = weatherCode;
    if (code == null) return 'Unknown';
    return switch (code) {
      0 => 'Clear Sky',
      1 => 'Mainly Clear',
      2 => 'Partly Cloudy',
      3 => 'Overcast',
      45 || 48 => 'Fog',
      51 || 53 || 55 => 'Drizzle',
      56 || 57 => 'Freezing Drizzle',
      61 || 63 || 65 => 'Rain',
      66 || 67 => 'Freezing Rain',
      71 || 73 || 75 || 77 => 'Snow',
      80 || 81 || 82 => 'Rain Showers',
      85 || 86 => 'Snow Showers',
      95 => 'Thunderstorm',
      96 || 99 => 'Thunderstorm with Hail',
      _ => 'Cloudy',
    };
  }

  /// Converts this [HourlyWeather] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'time': time.toIso8601String(),
      if (temperature2m != null) 'temperature_2m': temperature2m,
      if (apparentTemperature != null)
        'apparent_temperature': apparentTemperature,
      if (relativeHumidity2m != null)
        'relative_humidity_2m': relativeHumidity2m,
      if (dewPoint2m != null) 'dew_point_2m': dewPoint2m,
      if (precipitationProbability != null)
        'precipitation_probability': precipitationProbability,
      if (precipitation != null) 'precipitation': precipitation,
      if (windSpeed10m != null) 'wind_speed_10m': windSpeed10m,
      if (windGusts10m != null) 'wind_gusts_10m': windGusts10m,
      if (uvIndex != null) 'uv_index': uvIndex,
      if (weatherCode != null) 'weather_code': weatherCode,
      if (isDay != null) 'is_day': isDay! ? 1 : 0,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HourlyWeather &&
        other.time == time &&
        other.temperature2m == temperature2m &&
        other.apparentTemperature == apparentTemperature &&
        other.relativeHumidity2m == relativeHumidity2m &&
        other.dewPoint2m == dewPoint2m &&
        other.precipitationProbability == precipitationProbability &&
        other.precipitation == precipitation &&
        other.windSpeed10m == windSpeed10m &&
        other.windGusts10m == windGusts10m &&
        other.uvIndex == uvIndex &&
        other.weatherCode == weatherCode &&
        other.isDay == isDay;
  }

  @override
  int get hashCode => Object.hash(
    time,
    temperature2m,
    apparentTemperature,
    relativeHumidity2m,
    dewPoint2m,
    precipitationProbability,
    precipitation,
    windSpeed10m,
    windGusts10m,
    uvIndex,
    weatherCode,
    isDay,
  );

  @override
  String toString() =>
      'HourlyWeather(time: $time, temp: $temperature2m, rainProb: $precipitationProbability%, rain: ${precipitation}mm, code: $weatherCode)';
}
