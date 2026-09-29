import 'package:cricket_mate/features/players/data/models/player.dart';
import 'package:cricket_mate/features/players/domain/overlap_window.dart';
import 'package:cricket_mate/features/sessions/domain/availability_scorer.dart';
import 'package:cricket_mate/features/sessions/domain/ball_type.dart';
import 'package:cricket_mate/features/sessions/domain/session_candidate.dart';
import 'package:cricket_mate/features/sessions/domain/session_scorer.dart';
import 'package:cricket_mate/features/sessions/domain/weather_scorer.dart';
import 'package:cricket_mate/features/weather/data/models/hourly_weather.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseTime = DateTime(2026, 9, 30, 14, 0); // 2:00 PM
  final windowEnd = DateTime(2026, 9, 30, 16, 0); // 4:00 PM

  List<Player> createPlayers(int count) {
    return List.generate(count, (i) => Player(id: 'p$i', name: 'Player $i'));
  }

  HourlyWeather createHour({
    required DateTime time,
    double temp = 24.0,
    double? apparentTemp,
    int rainProb = 0,
    double precipMm = 0.0,
    double windSpeed = 10.0,
    double windGusts = 15.0,
    int humidity = 50,
    double uv = 3.0,
    int weatherCode = 0,
    bool isDay = true,
    double? dewPoint,
  }) {
    return HourlyWeather(
      time: time,
      temperature2m: temp,
      apparentTemperature: apparentTemp ?? temp,
      precipitationProbability: rainProb,
      precipitation: precipMm,
      windSpeed10m: windSpeed,
      windGusts10m: windGusts,
      relativeHumidity2m: humidity,
      uvIndex: uv,
      weatherCode: weatherCode,
      isDay: isDay,
      dewPoint2m: dewPoint ?? (temp - 6.0),
    );
  }

  group('SessionScorer', () {
    test('1. perfect conditions: mild 24C, 0% rain, light breeze, full squad produces score >= 85 (Excellent)', () {
      final window = OverlapWindow(
        start: baseTime,
        end: windowEnd,
        players: createPlayers(11),
      );

      final hourly = [
        createHour(time: DateTime(2026, 9, 30, 14, 0)),
        createHour(time: DateTime(2026, 9, 30, 15, 0)),
      ];

      final candidate = SessionScorer.score(
        window: window,
        allHourlyWeather: hourly,
        totalSquad: 11,
        ballType: BallType.tennis,
      );

      expect(candidate.score, greaterThanOrEqualTo(85.0));
      expect(candidate.rating, equals(SessionRating.excellent));
      expect(candidate.hasVeto, isFalse);
      expect(candidate.reasonChips.any((c) => c.isPositive), isTrue);
    });

    test(
      '2. rain veto: rain probability > 70% caps session score at <= 30',
      () {
        final window = OverlapWindow(
          start: baseTime,
          end: windowEnd,
          players: createPlayers(11),
        );

        final hourly = [
          createHour(time: DateTime(2026, 9, 30, 14, 0), rainProb: 75),
          createHour(time: DateTime(2026, 9, 30, 15, 0), rainProb: 80),
        ];

        final candidate = SessionScorer.score(
          window: window,
          allHourlyWeather: hourly,
          totalSquad: 11,
        );

        expect(candidate.score, lessThanOrEqualTo(30.0));
        expect(candidate.hasVeto, isTrue);
        expect(candidate.vetoReasons.any((r) => r.contains('rain')), isTrue);
      },
    );

    test(
      '3. thunderstorm veto: WMO codes 95-99 cap session score at <= 30',
      () {
        final window = OverlapWindow(
          start: baseTime,
          end: windowEnd,
          players: createPlayers(10),
        );

        final hourly = [
          createHour(time: DateTime(2026, 9, 30, 14, 0), weatherCode: 95),
          createHour(time: DateTime(2026, 9, 30, 15, 0), weatherCode: 0),
        ];

        final candidate = SessionScorer.score(
          window: window,
          allHourlyWeather: hourly,
          totalSquad: 10,
        );

        expect(candidate.score, lessThanOrEqualTo(30.0));
        expect(candidate.hasVeto, isTrue);
        expect(
          candidate.vetoReasons.any((r) => r.contains('Thunderstorm')),
          isTrue,
        );
      },
    );

    test('4. wet outfield: heavy rain in previous 12-24h severely penalizes conditions', () {
      final window = OverlapWindow(
        start: baseTime,
        end: windowEnd,
        players: createPlayers(8),
      );

      // Rain 8 hours before match start
      final pastRainHour = createHour(
        time: baseTime.subtract(const Duration(hours: 8)),
        precipMm: 7.5,
      );

      final matchHours = [
        createHour(time: DateTime(2026, 9, 30, 14, 0)),
        createHour(time: DateTime(2026, 9, 30, 15, 0)),
      ];

      final candidate = SessionScorer.score(
        window: window,
        allHourlyWeather: [pastRainHour, ...matchHours],
        totalSquad: 8,
      );

      expect(candidate.conditionsScores.wetOutfield, lessThanOrEqualTo(30.0));
      expect(
        candidate.reasonChips.any((c) => c.message.contains('Wet ground')),
        isTrue,
      );
    });

    test('5. dew risk: small temp - dew point gap in evening penalizes dew score, especially for leather', () {
      final eveningStart = DateTime(2026, 9, 30, 19, 0); // 7:00 PM
      final eveningEnd = DateTime(2026, 9, 30, 21, 0);

      final window = OverlapWindow(
        start: eveningStart,
        end: eveningEnd,
        players: createPlayers(8),
      );

      final eveningHours = [
        createHour(
          time: DateTime(2026, 9, 30, 19, 0),
          temp: 18.0,
          dewPoint: 17.5, // 0.5C gap = heavy dew!
          isDay: false,
        ),
        createHour(
          time: DateTime(2026, 9, 30, 20, 0),
          temp: 17.0,
          dewPoint: 16.5,
          isDay: false,
        ),
      ];

      final leatherCandidate = SessionScorer.score(
        window: window,
        allHourlyWeather: eveningHours,
        totalSquad: 8,
        ballType: BallType.leather,
      );

      final tennisCandidate = SessionScorer.score(
        window: window,
        allHourlyWeather: eveningHours,
        totalSquad: 8,
        ballType: BallType.tennis,
      );

      // Leather ball is much more sensitive to dew than tennis ball
      expect(
        leatherCandidate.conditionsScores.dewRisk,
        lessThan(tennisCandidate.conditionsScores.dewRisk),
      );
    });

    test(
      '6. no daylight for leather ball: triggers veto capping score at <= 30',
      () {
        final nightStart = DateTime(2026, 9, 30, 20, 0);
        final nightEnd = DateTime(2026, 9, 30, 22, 0);

        final window = OverlapWindow(
          start: nightStart,
          end: nightEnd,
          players: createPlayers(10),
        );

        final nightHours = [
          createHour(time: DateTime(2026, 9, 30, 20, 0), isDay: false),
          createHour(time: DateTime(2026, 9, 30, 21, 0), isDay: false),
        ];

        final candidate = SessionScorer.score(
          window: window,
          allHourlyWeather: nightHours,
          totalSquad: 10,
          ballType: BallType.leather,
        );

        expect(candidate.score, lessThanOrEqualTo(30.0));
        expect(candidate.hasVeto, isTrue);
        expect(
          candidate.vetoReasons.any((r) => r.contains('daylight')),
          isTrue,
        );
      },
    );

    test('7. daylight tolerant for tennis & box: night play does NOT trigger daylight veto', () {
      final nightStart = DateTime(2026, 9, 30, 20, 0);
      final nightEnd = DateTime(2026, 9, 30, 22, 0);

      final window = OverlapWindow(
        start: nightStart,
        end: nightEnd,
        players: createPlayers(8),
      );

      final nightHours = [
        createHour(time: DateTime(2026, 9, 30, 20, 0), isDay: false),
        createHour(time: DateTime(2026, 9, 30, 21, 0), isDay: false),
      ];

      final candidate = SessionScorer.score(
        window: window,
        allHourlyWeather: nightHours,
        totalSquad: 8,
        ballType: BallType.tennis,
      );

      // Tennis ball is playable at night (under park lights) without daylight veto
      expect(candidate.hasVeto, isFalse);
      expect(candidate.score, greaterThan(50.0));
    });

    test('8. quorum missing: attending < quorum caps final score at <= 30', () {
      // Only 4 players attending, quorum is 6
      final window = OverlapWindow(
        start: baseTime,
        end: windowEnd,
        players: createPlayers(4),
      );

      final hourly = [
        createHour(time: DateTime(2026, 9, 30, 14, 0)),
        createHour(time: DateTime(2026, 9, 30, 15, 0)),
      ];

      final candidate = SessionScorer.score(
        window: window,
        allHourlyWeather: hourly,
        totalSquad: 10,
        quorum: 6,
      );

      expect(candidate.score, lessThanOrEqualTo(30.0));
      expect(candidate.hasVeto, isTrue);
      expect(candidate.vetoReasons.any((r) => r.contains('quorum')), isTrue);
    });

    test('9. boundary scores: sub-scores and final scores clamp safely to [0.0, 100.0]', () {
      final window = OverlapWindow(
        start: baseTime,
        end: windowEnd,
        players: createPlayers(1),
      );

      final extremeCold = [
        createHour(
          time: DateTime(2026, 9, 30, 14, 0),
          temp: -10.0,
          apparentTemp: -18.0,
          windSpeed: 80.0,
          windGusts: 110.0,
          humidity: 100,
          rainProb: 100,
          precipMm: 25.0,
        ),
      ];

      final candidate = SessionScorer.score(
        window: window,
        allHourlyWeather: extremeCold,
        totalSquad: 10,
      );

      expect(candidate.score, greaterThanOrEqualTo(0.0));
      expect(candidate.score, lessThanOrEqualTo(100.0));
      expect(candidate.weatherScores.total, greaterThanOrEqualTo(0.0));
      expect(candidate.weatherScores.total, lessThanOrEqualTo(100.0));
    });

    test(
      '10. empty/sparse forecast: handles missing forecast data defensively',
      () {
        final window = OverlapWindow(
          start: baseTime,
          end: windowEnd,
          players: createPlayers(8),
        );

        final candidate = SessionScorer.score(
          window: window,
          allHourlyWeather: const [],
          totalSquad: 8,
        );

        expect(candidate.score, greaterThan(0.0));
        expect(candidate.weatherScores.total, equals(50.0));
      },
    );

    test('11. extreme heat vs freezing degrades temperature comfort score', () {
      final scorchingHour = createHour(
        time: DateTime(2026, 9, 30, 14, 0),
        temp: 42.0,
        apparentTemp: 44.0,
      );
      final freezingHour = createHour(
        time: DateTime(2026, 9, 30, 14, 0),
        temp: 2.0,
        apparentTemp: 0.0,
      );

      final scorchScore = WeatherScorer.calculateTemperatureScore(
        scorchingHour,
      );
      final freezeScore = WeatherScorer.calculateTemperatureScore(freezingHour);

      expect(scorchScore, lessThan(30.0));
      expect(freezeScore, lessThan(30.0));
    });

    test('12. high wind/gusts penalizes tennis ball significantly more than leather ball', () {
      final windyHour = createHour(
        time: DateTime(2026, 9, 30, 14, 0),
        windSpeed: 38.0,
        windGusts: 52.0,
      );

      final tennisWindScore = WeatherScorer.calculateWindScore(
        windyHour,
        ballType: BallType.tennis,
      );
      final leatherWindScore = WeatherScorer.calculateWindScore(
        windyHour,
        ballType: BallType.leather,
      );

      expect(tennisWindScore, lessThan(leatherWindScore));
    });
  });

  group('AvailabilityScorer standalone', () {
    test('returns 0 when no squad or attending', () {
      expect(
        AvailabilityScorer.score(attending: 0, totalSquad: 10),
        equals(0.0),
      );
    });

    test('attending below quorum scales up to 50', () {
      final score3 = AvailabilityScorer.score(
        attending: 3,
        totalSquad: 10,
        quorum: 6,
      );
      expect(score3, equals(25.0));
    });

    test('attending exactly at quorum scores 75', () {
      final score6 = AvailabilityScorer.score(
        attending: 6,
        totalSquad: 10,
        quorum: 6,
      );
      expect(score6, equals(75.0));
    });

    test('full squad turnout scores 100', () {
      final score10 = AvailabilityScorer.score(
        attending: 10,
        totalSquad: 10,
        quorum: 6,
      );
      expect(score10, equals(100.0));
    });
  });
}
