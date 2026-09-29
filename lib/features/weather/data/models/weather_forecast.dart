import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import 'daily_astro.dart';
import 'hourly_weather.dart';

/// Immutable aggregate model containing the full weather forecast for a cricket venue,
/// including hourly meteorological data and daily astronomical sunrise/sunset times.
@immutable
class WeatherForecast {
  const WeatherForecast({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.utcOffsetSeconds,
    required this.hourly,
    required this.dailyAstro,
    this.elevation,
  });

  /// Latitude coordinate of the forecast location.
  final double latitude;

  /// Longitude coordinate of the forecast location.
  final double longitude;

  /// Timezone identifier returned by the API (e.g. "Europe/London").
  final String timezone;

  /// UTC offset in seconds.
  final int utcOffsetSeconds;

  /// Elevation of the forecast site in meters above sea level.
  final double? elevation;

  /// Ordered series of hourly weather predictions.
  final List<HourlyWeather> hourly;

  /// Daily astronomical details (sunrise/sunset) for daylight scheduling.
  final List<DailyAstro> dailyAstro;

  /// Deserializes a [WeatherForecast] defensively from Open-Meteo JSON payload.
  /// Throws [ParsingException] only when the payload is fundamentally unusable
  /// (e.g. missing coordinates or non-existent hourly timestamps). Missing, null,
  /// or mismatched arrays are handled gracefully with null values.
  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final num? rawLat = json['latitude'] as num?;
    final num? rawLng = json['longitude'] as num?;

    if (rawLat == null || rawLng == null) {
      throw const ParsingException(
        message: 'Weather forecast is missing valid geographic coordinates.',
      );
    }

    final dynamic rawHourly = json['hourly'];
    if (rawHourly is! Map) {
      throw const ParsingException(
        message: 'Weather forecast is missing the hourly data object.',
      );
    }

    final dynamic rawTimes = rawHourly['time'];
    if (rawTimes is! List || rawTimes.isEmpty) {
      throw const ParsingException(
        message: 'Weather forecast contains no hourly timestamps.',
      );
    }

    final hourlyList = _parseHourlySeries(rawHourly, rawTimes);
    if (hourlyList.isEmpty) {
      throw const ParsingException(
        message:
            'Weather forecast contains no parseable hourly timestamp entries.',
      );
    }

    final dailyList = _parseDailyAstro(json['daily']);

    return WeatherForecast(
      latitude: rawLat.toDouble(),
      longitude: rawLng.toDouble(),
      timezone: json['timezone'] as String? ?? 'UTC',
      utcOffsetSeconds: (json['utc_offset_seconds'] as num?)?.toInt() ?? 0,
      elevation: (json['elevation'] as num?)?.toDouble(),
      hourly: hourlyList,
      dailyAstro: dailyList,
    );
  }

  static List<HourlyWeather> _parseHourlySeries(
    Map<dynamic, dynamic> hourlyMap,
    List<dynamic> times,
  ) {
    final List<dynamic>? tempArr =
        hourlyMap['temperature_2m'] as List<dynamic>?;
    final List<dynamic>? appTempArr =
        hourlyMap['apparent_temperature'] as List<dynamic>?;
    final List<dynamic>? humidityArr =
        hourlyMap['relative_humidity_2m'] as List<dynamic>?;
    final List<dynamic>? dewPointArr =
        hourlyMap['dew_point_2m'] as List<dynamic>?;
    final List<dynamic>? precipProbArr =
        hourlyMap['precipitation_probability'] as List<dynamic>?;
    final List<dynamic>? precipArr =
        hourlyMap['precipitation'] as List<dynamic>?;
    final List<dynamic>? windSpeedArr =
        hourlyMap['wind_speed_10m'] as List<dynamic>?;
    final List<dynamic>? windGustsArr =
        hourlyMap['wind_gusts_10m'] as List<dynamic>?;
    final List<dynamic>? uvIndexArr = hourlyMap['uv_index'] as List<dynamic>?;
    final List<dynamic>? weatherCodeArr =
        hourlyMap['weather_code'] as List<dynamic>?;
    final List<dynamic>? isDayArr = hourlyMap['is_day'] as List<dynamic>?;

    final results = <HourlyWeather>[];

    for (int i = 0; i < times.length; i++) {
      final dynamic rawTime = times[i];
      if (rawTime is! String) continue;

      final DateTime? parsedTime = DateTime.tryParse(rawTime);
      if (parsedTime == null) continue;

      results.add(
        HourlyWeather(
          time: parsedTime,
          temperature2m: _asDouble(tempArr, i),
          apparentTemperature: _asDouble(appTempArr, i),
          relativeHumidity2m: _asInt(humidityArr, i),
          dewPoint2m: _asDouble(dewPointArr, i),
          precipitationProbability: _asInt(precipProbArr, i),
          precipitation: _asDouble(precipArr, i),
          windSpeed10m: _asDouble(windSpeedArr, i),
          windGusts10m: _asDouble(windGustsArr, i),
          uvIndex: _asDouble(uvIndexArr, i),
          weatherCode: _asInt(weatherCodeArr, i),
          isDay: _asBool(isDayArr, i),
        ),
      );
    }

    return List<HourlyWeather>.unmodifiable(results);
  }

  static List<DailyAstro> _parseDailyAstro(dynamic rawDaily) {
    if (rawDaily is! Map) return const <DailyAstro>[];

    final dynamic rawDates = rawDaily['time'];
    if (rawDates is! List) return const <DailyAstro>[];

    final List<dynamic>? sunriseArr = rawDaily['sunrise'] as List<dynamic>?;
    final List<dynamic>? sunsetArr = rawDaily['sunset'] as List<dynamic>?;

    final results = <DailyAstro>[];

    for (int i = 0; i < rawDates.length; i++) {
      final dynamic rawDate = rawDates[i];
      if (rawDate is! String) continue;

      final DateTime? parsedDate = DateTime.tryParse(rawDate);
      if (parsedDate == null) continue;

      final dynamic rawSunrise = (sunriseArr != null && i < sunriseArr.length)
          ? sunriseArr[i]
          : null;
      final dynamic rawSunset = (sunsetArr != null && i < sunsetArr.length)
          ? sunsetArr[i]
          : null;

      results.add(
        DailyAstro(
          date: parsedDate,
          sunrise: rawSunrise is String ? DateTime.tryParse(rawSunrise) : null,
          sunset: rawSunset is String ? DateTime.tryParse(rawSunset) : null,
        ),
      );
    }

    return List<DailyAstro>.unmodifiable(results);
  }

  static double? _asDouble(List<dynamic>? list, int index) {
    if (list == null || index >= list.length) return null;
    final dynamic val = list[index];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  static int? _asInt(List<dynamic>? list, int index) {
    if (list == null || index >= list.length) return null;
    final dynamic val = list[index];
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  static bool? _asBool(List<dynamic>? list, int index) {
    if (list == null || index >= list.length) return null;
    final dynamic val = list[index];
    if (val == 1 || val == true || val == '1') return true;
    if (val == 0 || val == false || val == '0') return false;
    return null;
  }

  /// Converts this [WeatherForecast] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'utc_offset_seconds': utcOffsetSeconds,
      if (elevation != null) 'elevation': elevation,
      'hourly': <String, dynamic>{
        'time': hourly.map((h) => h.time.toIso8601String()).toList(),
        'temperature_2m': hourly.map((h) => h.temperature2m).toList(),
        'apparent_temperature': hourly
            .map((h) => h.apparentTemperature)
            .toList(),
        'relative_humidity_2m': hourly
            .map((h) => h.relativeHumidity2m)
            .toList(),
        'dew_point_2m': hourly.map((h) => h.dewPoint2m).toList(),
        'precipitation_probability': hourly
            .map((h) => h.precipitationProbability)
            .toList(),
        'precipitation': hourly.map((h) => h.precipitation).toList(),
        'wind_speed_10m': hourly.map((h) => h.windSpeed10m).toList(),
        'wind_gusts_10m': hourly.map((h) => h.windGusts10m).toList(),
        'uv_index': hourly.map((h) => h.uvIndex).toList(),
        'weather_code': hourly.map((h) => h.weatherCode).toList(),
        'is_day': hourly
            .map((h) => h.isDay == null ? null : (h.isDay! ? 1 : 0))
            .toList(),
      },
      'daily': <String, dynamic>{
        'time': dailyAstro
            .map((d) => d.date.toIso8601String().split('T').first)
            .toList(),
        'sunrise': dailyAstro.map((d) => d.sunrise?.toIso8601String()).toList(),
        'sunset': dailyAstro.map((d) => d.sunset?.toIso8601String()).toList(),
      },
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherForecast &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timezone == timezone &&
        other.utcOffsetSeconds == utcOffsetSeconds &&
        other.elevation == elevation &&
        listEquals(other.hourly, hourly) &&
        listEquals(other.dailyAstro, dailyAstro);
  }

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    timezone,
    utcOffsetSeconds,
    elevation,
    Object.hashAll(hourly),
    Object.hashAll(dailyAstro),
  );

  @override
  String toString() =>
      'WeatherForecast(lat: $latitude, lng: $longitude, tz: $timezone, hours: ${hourly.length}, days: ${dailyAstro.length})';
}
