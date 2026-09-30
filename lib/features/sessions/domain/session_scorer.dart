import 'dart:math' as math;

import '../../players/domain/overlap_window.dart';
import '../../weather/data/models/hourly_weather.dart';
import 'availability_scorer.dart';
import 'ball_type.dart';
import 'conditions_scorer.dart';
import 'reason_chip.dart';
import 'session_candidate.dart';
import 'weather_scorer.dart';

/// Aggregates weather, squad availability, and ground conditions into a unified cricket session score.
///
/// Weighting:
/// - Weather: 60%
/// - Availability: 30%
/// - Conditions: 10%
///
/// Hard Vetoes (Cap score at <= 30.0):
/// 1. Thunderstorms (WMO codes 95-99).
/// 2. Rain probability > 70% in any hour of the window.
/// 3. Attendance below quorum.
/// 4. Leather ball in total darkness.
abstract final class SessionScorer {
  static const double weatherWeight = 0.60;
  static const double availabilityWeight = 0.30;
  static const double conditionsWeight = 0.10;
  static const double vetoScoreCap = 30.0;

  /// Scores a single candidate playing [window].
  static SessionCandidate score({
    required OverlapWindow window,
    required List<HourlyWeather> allHourlyWeather,
    required int totalSquad,
    BallType ballType = BallType.tennis,
    int quorum = AvailabilityScorer.defaultQuorum,
  }) {
    // 1. Identify weather hours intersecting the window
    final windowHours = allHourlyWeather.where((h) {
      final isAfterOrAtStart =
          h.time.isAfter(window.start) || h.time.isAtSameMomentAs(window.start);
      final isBeforeEnd = h.time.isBefore(window.end);
      return isAfterOrAtStart && isBeforeEnd;
    }).toList();

    // 2. Weather scoring (averaged across window hours)
    final WeatherSubScores weatherScores;
    if (windowHours.isNotEmpty) {
      double rainSum = 0.0;
      double tempSum = 0.0;
      double windSum = 0.0;
      double humiditySum = 0.0;
      double uvSum = 0.0;

      for (final hour in windowHours) {
        final sub = WeatherScorer.scoreHour(hour, ballType: ballType);
        rainSum += sub.rain;
        tempSum += sub.temperature;
        windSum += sub.wind;
        humiditySum += sub.humidity;
        uvSum += sub.uv;
      }

      final count = windowHours.length.toDouble();
      final avgRain = rainSum / count;
      final avgTemp = tempSum / count;
      final avgWind = windSum / count;
      final avgHumidity = humiditySum / count;
      final avgUv = uvSum / count;

      final totalWeather =
          (avgRain * WeatherScorer.rainWeight) +
          (avgTemp * WeatherScorer.tempWeight) +
          (avgWind * WeatherScorer.windWeight) +
          (avgHumidity * WeatherScorer.humidityWeight) +
          (avgUv * WeatherScorer.uvWeight);

      weatherScores = WeatherSubScores(
        rain: avgRain,
        temperature: avgTemp,
        wind: avgWind,
        humidity: avgHumidity,
        uv: avgUv,
        total: totalWeather.clamp(0.0, 100.0),
      );
    } else {
      // Graceful fallback for empty/sparse forecast
      weatherScores = const WeatherSubScores(
        rain: 50.0,
        temperature: 50.0,
        wind: 50.0,
        humidity: 50.0,
        uv: 50.0,
        total: 50.0,
      );
    }

    // 3. Ground & ambient conditions scoring
    final conditionsScores = ConditionsScorer.scoreWindow(
      windowStart: window.start,
      windowEnd: window.end,
      allHourlyWeather: allHourlyWeather,
      ballType: ballType,
    );

    // 4. Squad availability scoring
    final availabilityScore = AvailabilityScorer.score(
      attending: window.playerCount,
      totalSquad: totalSquad,
      quorum: quorum,
    );

    // 5. Evaluate hard veto rules
    final vetoReasons = <String>[];

    // Veto 1: Thunderstorms (WMO 95-99)
    final hasThunderstorm = windowHours.any((h) {
      final code = h.weatherCode ?? 0;
      return code >= 95 && code <= 99;
    });
    if (hasThunderstorm) {
      vetoReasons.add('Thunderstorm hazard (lightning danger)');
    }

    // Veto 2: Rain probability > 70%
    final maxRainProb = windowHours.fold<int>(
      0,
      (max, h) => math.max(max, h.precipitationProbability ?? 0),
    );
    if (maxRainProb > 70) {
      vetoReasons.add('High rain probability ($maxRainProb%)');
    }

    // Veto 3: Below quorum
    if (window.playerCount < quorum) {
      vetoReasons.add(
        'Below squad quorum (${window.playerCount}/$quorum required players)',
      );
    }

    // Veto 4: Leather ball in total darkness
    if (ballType.requiresDaylight && conditionsScores.daylightFraction <= 0.0) {
      vetoReasons.add('Leather ball requires natural daylight');
    }

    // 6. Aggregate score calculation
    final rawScore =
        (weatherScores.total * weatherWeight) +
        (availabilityScore * availabilityWeight) +
        (conditionsScores.total * conditionsWeight);

    final finalScore = vetoReasons.isNotEmpty
        ? math.min(rawScore, vetoScoreCap)
        : rawScore.clamp(0.0, 100.0);

    final rating = SessionRating.fromScore(finalScore);

    // 7. Reason chips generation
    final reasonChips = _generateReasonChips(
      window: window,
      windowHours: windowHours,
      weatherScores: weatherScores,
      conditionsScores: conditionsScores,
      availabilityScore: availabilityScore,
      ballType: ballType,
      quorum: quorum,
      vetoReasons: vetoReasons,
    );

    return SessionCandidate(
      window: window,
      score: finalScore,
      rating: rating,
      weatherScores: weatherScores,
      conditionsScores: conditionsScores,
      availabilityScore: availabilityScore,
      ballType: ballType,
      reasonChips: reasonChips,
      vetoReasons: vetoReasons,
    );
  }

  /// Scores and ranks candidate windows in descending order of quality.
  static List<SessionCandidate> scoreCandidates({
    required List<OverlapWindow> windows,
    required List<HourlyWeather> allHourlyWeather,
    required int totalSquad,
    BallType ballType = BallType.tennis,
    int quorum = AvailabilityScorer.defaultQuorum,
  }) {
    final candidates = windows
        .map(
          (w) => score(
            window: w,
            allHourlyWeather: allHourlyWeather,
            totalSquad: totalSquad,
            ballType: ballType,
            quorum: quorum,
          ),
        )
        .toList();

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates;
  }

  static List<ReasonChip> _generateReasonChips({
    required OverlapWindow window,
    required List<HourlyWeather> windowHours,
    required WeatherSubScores weatherScores,
    required ConditionsSubScores conditionsScores,
    required double availabilityScore,
    required BallType ballType,
    required int quorum,
    required List<String> vetoReasons,
  }) {
    final chips = <ReasonChip>[];

    // Veto callouts first
    for (final reason in vetoReasons) {
      if (reason.contains('Thunderstorm')) {
        chips.add(
          ReasonChip.negative(reason, messageKey: 'reasonThunderstorm'),
        );
      } else if (reason.contains('rain')) {
        final maxRain = windowHours.fold<int>(
          0,
          (max, h) => math.max(max, h.precipitationProbability ?? 0),
        );
        chips.add(
          ReasonChip.negative(
            reason,
            messageKey: 'reasonRainRisk',
            arguments: {'percent': maxRain},
          ),
        );
      } else if (reason.contains('quorum')) {
        chips.add(
          ReasonChip.negative(
            reason,
            messageKey: 'reasonBelowQuorum',
            arguments: {'count': window.playerCount, 'quorum': quorum},
          ),
        );
      } else if (reason.contains('Leather')) {
        chips.add(
          ReasonChip.negative(reason, messageKey: 'reasonLeatherDaylight'),
        );
      } else {
        chips.add(ReasonChip.negative(reason));
      }
    }

    // Weather positive callouts
    if (weatherScores.rain >= 85.0 &&
        !vetoReasons.any((r) => r.contains('rain'))) {
      chips.add(
        const ReasonChip.positive(
          'Low rain chance',
          messageKey: 'reasonLowRain',
        ),
      );
    }

    if (weatherScores.temperature >= 85.0) {
      chips.add(
        const ReasonChip.positive(
          'Ideal cricket temperature',
          messageKey: 'reasonIdealTemp',
        ),
      );
    } else if (weatherScores.temperature < 40.0) {
      chips.add(
        const ReasonChip.warning(
          'Chilly temperature',
          messageKey: 'reasonChillyTemp',
        ),
      );
    }

    if (weatherScores.wind >= 85.0) {
      chips.add(
        const ReasonChip.positive(
          'Gentle breeze',
          messageKey: 'reasonGentleBreeze',
        ),
      );
    } else if (weatherScores.wind < 40.0) {
      chips.add(
        const ReasonChip.warning(
          'Gusty wind conditions',
          messageKey: 'reasonGustyWind',
        ),
      );
    }

    // Outfield callouts
    if (conditionsScores.past24hPrecipitationMm >= 4.0) {
      final mm = conditionsScores.past24hPrecipitationMm.toStringAsFixed(1);
      chips.add(
        ReasonChip.negative(
          "Wet ground from last night's rain (${mm}mm)",
          messageKey: 'reasonWetGround',
          arguments: {'mm': mm},
        ),
      );
    } else if (conditionsScores.wetOutfield >= 90.0) {
      chips.add(
        const ReasonChip.positive(
          'Dry outfield',
          messageKey: 'reasonDryOutfield',
        ),
      );
    }

    // Dew callouts
    if (conditionsScores.dewRisk < 50.0) {
      chips.add(
        const ReasonChip.warning(
          'Evening dew risk (slippery ball)',
          messageKey: 'reasonDewRisk',
        ),
      );
    }

    // Availability callouts
    if (window.playerCount >= quorum) {
      chips.add(
        ReasonChip.positive(
          'Squad quorum reached (${window.playerCount}/$quorum players)',
          messageKey: 'reasonQuorumReached',
          arguments: {'count': window.playerCount, 'quorum': quorum},
        ),
      );
    }

    return chips;
  }
}
