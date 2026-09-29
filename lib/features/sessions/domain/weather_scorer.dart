import 'dart:math' as math;

import '../../weather/data/models/hourly_weather.dart';
import 'ball_type.dart';

/// Immutable container for weather sub-scores (each scaled 0.0 - 100.0).
class WeatherSubScores {
  const WeatherSubScores({
    required this.rain,
    required this.temperature,
    required this.wind,
    required this.humidity,
    required this.uv,
    required this.total,
  });

  /// Rain score considering precipitation probability and volume (40% weight).
  final double rain;

  /// Thermal comfort based on apparent temperature (25% weight).
  final double temperature;

  /// Wind score adjusted by ball type aerodynamic tolerance (15% weight).
  final double wind;

  /// Humidity / oppressive heat-index score (10% weight).
  final double humidity;

  /// UV radiation hazard score, active only during daylight (10% weight).
  final double uv;

  /// Weighted aggregate score (0.0 - 100.0).
  final double total;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherSubScores &&
        other.rain == rain &&
        other.temperature == temperature &&
        other.wind == wind &&
        other.humidity == humidity &&
        other.uv == uv &&
        other.total == total;
  }

  @override
  int get hashCode => Object.hash(rain, temperature, wind, humidity, uv, total);

  @override
  String toString() =>
      'WeatherSubScores(total: ${total.toStringAsFixed(1)}, rain: ${rain.toStringAsFixed(1)}, temp: ${temperature.toStringAsFixed(1)}, wind: ${wind.toStringAsFixed(1)}, humidity: ${humidity.toStringAsFixed(1)}, uv: ${uv.toStringAsFixed(1)})';
}

/// Evaluates meteorological data into calibrated sub-scores for cricket playability.
///
/// Weighting:
/// - Rain: 40%
/// - Temperature: 25%
/// - Wind: 15%
/// - Humidity: 10%
/// - UV Index: 10%
abstract final class WeatherScorer {
  static const double rainWeight = 0.40;
  static const double tempWeight = 0.25;
  static const double windWeight = 0.15;
  static const double humidityWeight = 0.10;
  static const double uvWeight = 0.10;

  /// Evaluates an individual [hour] of weather for a specified [ballType].
  static WeatherSubScores scoreHour(
    HourlyWeather hour, {
    BallType ballType = BallType.tennis,
  }) {
    final rain = calculateRainScore(hour);
    final temp = calculateTemperatureScore(hour);
    final wind = calculateWindScore(hour, ballType: ballType);
    final humidity = calculateHumidityScore(hour);
    final uv = calculateUvScore(hour);

    final total =
        (rain * rainWeight) +
        (temp * tempWeight) +
        (wind * windWeight) +
        (humidity * humidityWeight) +
        (uv * uvWeight);

    return WeatherSubScores(
      rain: rain,
      temperature: temp,
      wind: wind,
      humidity: humidity,
      uv: uv,
      total: total.clamp(0.0, 100.0),
    );
  }

  /// Calculates rain sub-score (0-100) combining probability and volume.
  static double calculateRainScore(HourlyWeather hour) {
    final prob = (hour.precipitationProbability ?? 0).clamp(0, 100);
    final mm = math.max(0.0, hour.precipitation ?? 0.0);

    // Probability factor: 0% -> 100, 100% -> 0
    final probScore = (100.0 - prob).clamp(0.0, 100.0);

    // Rain accumulation factor: 0mm -> 1.0, 2mm -> 0.0
    final volumeMultiplier = (1.0 - (mm / 2.0)).clamp(0.0, 1.0);

    return (probScore * volumeMultiplier).clamp(0.0, 100.0);
  }

  /// Calculates temperature comfort sub-score (0-100) using apparent temperature.
  /// Optimal cricket playing range: ~20°C to 28°C.
  static double calculateTemperatureScore(HourlyWeather hour) {
    final temp = hour.apparentTemperature ?? hour.temperature2m ?? 24.0;

    if (temp >= 20.0 && temp <= 28.0) {
      return 100.0;
    }

    if (temp < 20.0) {
      // Linear penalty below 20°C: 15°C -> 75, 10°C -> 50, 0°C -> 0
      final score = 100.0 - ((20.0 - temp) * 5.0);
      return score.clamp(0.0, 100.0);
    } else {
      // Linear penalty above 28°C: 33°C -> 70, 38°C -> 40, 44°C -> 0
      final score = 100.0 - ((temp - 28.0) * 6.0);
      return score.clamp(0.0, 100.0);
    }
  }

  /// Calculates wind sub-score (0-100) considering sustained speed and peak gusts,
  /// adjusted by ball type aerodynamic mass and tolerance.
  static double calculateWindScore(
    HourlyWeather hour, {
    BallType ballType = BallType.tennis,
  }) {
    final speed = math.max(0.0, hour.windSpeed10m ?? 8.0);
    final gusts = math.max(0.0, hour.windGusts10m ?? speed);

    // Weighted effective wind: 70% sustained, 30% gusts
    final effectiveWind = (speed * 0.70) + (gusts * 0.30);

    // Adjust for ball type aerodynamics
    final adjustedWind = effectiveWind / ballType.windToleranceFactor;

    // Up to 15 km/h is benign for cricket (100 score)
    if (adjustedWind <= 15.0) {
      return 100.0;
    }

    // 15 to 55 km/h drops towards 0
    final score = 100.0 - ((adjustedWind - 15.0) * 2.5);
    return score.clamp(0.0, 100.0);
  }

  /// Calculates humidity and oppressive heat comfort sub-score (0-100).
  /// Optimal range: 40% - 65%.
  static double calculateHumidityScore(HourlyWeather hour) {
    final rh = (hour.relativeHumidity2m ?? 50).clamp(0, 100);

    if (rh >= 40 && rh <= 65) {
      return 100.0;
    }

    if (rh > 65) {
      // Oppressive humidity: 80% -> 70, 90% -> 40, 100% -> 10
      final score = 100.0 - ((rh - 65) * 3.0);
      return score.clamp(0.0, 100.0);
    } else {
      // Very arid/dry conditions: 20% -> 80
      final score = 100.0 - ((40 - rh) * 2.0);
      return score.clamp(0.0, 100.0);
    }
  }

  /// Calculates UV radiation hazard score (0-100).
  /// Active exclusively during daylight hours. Night/evening receives 100.0.
  static double calculateUvScore(HourlyWeather hour) {
    if (hour.isDay == false) {
      return 100.0;
    }

    final uv = hour.uvIndex ?? 0.0;

    if (uv <= 2.5) return 100.0;
    if (uv <= 5.5) return 85.0;
    if (uv <= 7.5) return 65.0;
    if (uv <= 10.5) return 40.0;
    return 20.0;
  }
}
