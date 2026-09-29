import 'dart:math' as math;

import '../../weather/data/models/hourly_weather.dart';
import 'ball_type.dart';

/// Immutable container for ground condition sub-scores (0.0 - 100.0).
class ConditionsSubScores {
  const ConditionsSubScores({
    required this.wetOutfield,
    required this.dewRisk,
    required this.daylight,
    required this.total,
    this.past24hPrecipitationMm = 0.0,
    this.minDewPointDepression = 10.0,
    this.daylightFraction = 1.0,
  });

  /// Wet outfield score based on past 12-24h cumulative rainfall (40% weight).
  final double wetOutfield;

  /// Dew risk score based on air-to-dew-point spread in evening (30% weight).
  final double dewRisk;

  /// Daylight availability score across the playing window (30% weight).
  final double daylight;

  /// Weighted aggregate conditions score (0.0 - 100.0).
  final double total;

  /// Total millimeters of rain in the 24 hours preceding window start.
  final double past24hPrecipitationMm;

  /// Narrowest difference between temperature and dew point in °C.
  final double minDewPointDepression;

  /// Fraction of window hours occurring during daylight (0.0 - 1.0).
  final double daylightFraction;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConditionsSubScores &&
        other.wetOutfield == wetOutfield &&
        other.dewRisk == dewRisk &&
        other.daylight == daylight &&
        other.total == total;
  }

  @override
  int get hashCode => Object.hash(wetOutfield, dewRisk, daylight, total);

  @override
  String toString() =>
      'ConditionsSubScores(total: ${total.toStringAsFixed(1)}, outfield: ${wetOutfield.toStringAsFixed(1)}, dew: ${dewRisk.toStringAsFixed(1)}, daylight: ${daylight.toStringAsFixed(1)})';
}

/// Evaluates pitch, outfield, and ambient lighting conditions for cricket play.
abstract final class ConditionsScorer {
  static const double wetOutfieldWeight = 0.40;
  static const double dewRiskWeight = 0.30;
  static const double daylightWeight = 0.30;

  /// Evaluates outfield moisture, dew hazard, and daylight for a window.
  static ConditionsSubScores scoreWindow({
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<HourlyWeather> allHourlyWeather,
    BallType ballType = BallType.tennis,
  }) {
    // 1. Wet outfield from precipitation in previous 12-24 hours
    final cutoff24h = windowStart.subtract(const Duration(hours: 24));
    final pastHours = allHourlyWeather.where(
      (h) =>
          (h.time.isAfter(cutoff24h) || h.time.isAtSameMomentAs(cutoff24h)) &&
          h.time.isBefore(windowStart),
    );

    final pastPrecip = pastHours.fold<double>(
      0.0,
      (sum, h) => sum + math.max(0.0, h.precipitation ?? 0.0),
    );

    final outfieldScore = calculateWetOutfieldScore(pastPrecip);

    // 2. Dew risk across window hours
    final windowHours = allHourlyWeather
        .where(
          (h) =>
              (h.time.isAfter(windowStart) ||
                  h.time.isAtSameMomentAs(windowStart)) &&
              h.time.isBefore(windowEnd),
        )
        .toList();

    double minDewDepression = 10.0;
    double dewScoreSum = 0.0;

    if (windowHours.isNotEmpty) {
      for (final h in windowHours) {
        final temp = h.temperature2m ?? h.apparentTemperature ?? 20.0;
        final dew = h.dewPoint2m ?? (temp - 5.0);
        final depression = math.max(0.0, temp - dew);
        if (depression < minDewDepression) minDewDepression = depression;

        dewScoreSum += calculateDewScore(depression, h.isDay, ballType);
      }
    }

    final dewScore = windowHours.isNotEmpty
        ? (dewScoreSum / windowHours.length).clamp(0.0, 100.0)
        : 100.0;

    // 3. Daylight coverage
    final daylightFraction = calculateDaylightFraction(windowHours);
    final daylightScore = calculateDaylightScore(daylightFraction, ballType);

    final total =
        (outfieldScore * wetOutfieldWeight) +
        (dewScore * dewRiskWeight) +
        (daylightScore * daylightWeight);

    return ConditionsSubScores(
      wetOutfield: outfieldScore,
      dewRisk: dewScore,
      daylight: daylightScore,
      total: total.clamp(0.0, 100.0),
      past24hPrecipitationMm: pastPrecip,
      minDewPointDepression: minDewDepression,
      daylightFraction: daylightFraction,
    );
  }

  /// Calculates outfield score based on past 24h rainfall.
  /// 0mm -> 100, 2mm -> 80, 5mm -> 50, >= 10mm -> 0.
  static double calculateWetOutfieldScore(double pastRainMm) {
    if (pastRainMm <= 0.0) return 100.0;
    final score = 100.0 - (pastRainMm * 10.0);
    return score.clamp(0.0, 100.0);
  }

  /// Calculates dew score for an individual hour.
  /// Large depression (>= 6°C) means dry grass (100).
  /// Small depression (< 2°C) in late afternoon/night indicates heavy dew.
  static double calculateDewScore(
    double dewPointDepression,
    bool? isDay,
    BallType ballType,
  ) {
    // Dew primarily forms when sun is down or low (isDay == false or evening)
    final isNight = isDay == false;

    if (!isNight && dewPointDepression >= 4.0) {
      return 100.0;
    }

    // Baseline dew score: depression of 6°C -> 100, 0°C -> 10
    final baseScore = ((dewPointDepression / 6.0) * 100.0).clamp(10.0, 100.0);

    // Apply ball type tolerance / sensitivity
    final penalty = (100.0 - baseScore) * ballType.dewSensitivityFactor;
    return (100.0 - penalty).clamp(0.0, 100.0);
  }

  /// Computes the ratio of window hours occurring during daylight (0.0 - 1.0).
  static double calculateDaylightFraction(List<HourlyWeather> windowHours) {
    if (windowHours.isEmpty) return 1.0;
    final dayHours = windowHours.where((h) => h.isDay != false).length;
    return dayHours / windowHours.length;
  }

  /// Daylight score based on ball type safety requirements.
  /// Leather ball requires 100% daylight. Tennis/box are daylight-tolerant.
  static double calculateDaylightScore(
    double daylightFraction,
    BallType ballType,
  ) {
    if (ballType.requiresDaylight) {
      // Leather ball: severe penalty for low or zero daylight
      return (daylightFraction * 100.0).clamp(0.0, 100.0);
    } else {
      // Tennis and box cricket can be played in evening or floodlit parks
      // 100% daylight -> 100, 0% daylight -> 85 (perfectly playable under street/park lights)
      return (85.0 + (daylightFraction * 15.0)).clamp(0.0, 100.0);
    }
  }
}
