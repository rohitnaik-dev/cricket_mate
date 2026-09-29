import 'package:cricket_mate/core/state/view_state.dart';
import 'package:cricket_mate/features/players/repository/player_repository.dart';
import 'package:cricket_mate/features/players/state/players_controller.dart';
import 'package:cricket_mate/features/sessions/domain/session_candidate.dart';
import 'package:cricket_mate/features/sessions/state/sessions_controller.dart';
import 'package:cricket_mate/features/weather/data/cache_store.dart';
import 'package:cricket_mate/features/weather/data/models/hourly_weather.dart';
import 'package:cricket_mate/features/weather/data/models/weather_forecast.dart';
import 'package:cricket_mate/features/weather/state/weather_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final matchDate = DateTime(2026, 9, 30);

  // Generate 24 hours of pleasant cricket weather on matchDate
  final hourlyWeather = List.generate(24, (hour) {
    return HourlyWeather(
      time: DateTime(2026, 9, 30, hour, 0),
      temperature2m: 24.0,
      apparentTemperature: 24.0,
      precipitationProbability: 5,
      precipitation: 0.0,
      windSpeed10m: 10.0,
      windGusts10m: 15.0,
      relativeHumidity2m: 50,
      uvIndex: 3.0,
      weatherCode: 0,
      isDay: hour >= 6 && hour <= 19,
      dewPoint2m: 15.0,
    );
  });

  final forecast = WeatherForecast(
    latitude: 51.5074,
    longitude: -0.1278,
    timezone: 'Europe/London',
    utcOffsetSeconds: 0,
    hourly: hourlyWeather,
    dailyAstro: const [],
  );

  group('SessionsController reactive recomputation and filters', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      // Seed weather state with live forecast
      container.read(weatherControllerProvider.notifier).state =
          ViewState.success(forecast, fromCache: false);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'sessions recompute automatically when player availability changes',
      () async {
        final playersController = container.read(
          playersControllerProvider.notifier,
        );
        final sessionsController = container.read(
          sessionsControllerProvider.notifier,
        );
        sessionsController.setSelectedDate(matchDate);

        // 1. Initially, squad has 4 players available from 10:00 to 12:00
        final slot10to12 = AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 0),
          end: DateTime(2026, 9, 30, 12, 0),
        );

        for (int i = 1; i <= 4; i++) {
          final p = await playersController.addPlayer('Player $i', id: 'p$i');
          await playersController.setAvailability(p.id, matchDate, [
            slot10to12,
          ]);
        }

        // Check candidate sessions: Quorum is 6, so only 4 attending triggers below-quorum veto!
        var sessionsState = container.read(sessionsControllerProvider);
        expect(sessionsState.candidatesState.isSuccess, isTrue);

        var candidates = sessionsState.candidatesState.dataOrNull!;
        var window10to12 = candidates.firstWhere(
          (c) => c.window.start == DateTime(2026, 9, 30, 10, 0),
        );
        expect(window10to12.window.playerCount, equals(4));
        expect(window10to12.hasVeto, isTrue);
        expect(window10to12.score, lessThanOrEqualTo(30.0));

        // 2. Now add 2 more players available for the SAME window (reaching quorum of 6!)
        for (int i = 5; i <= 6; i++) {
          final p = await playersController.addPlayer('Player $i', id: 'p$i');
          await playersController.setAvailability(p.id, matchDate, [
            slot10to12,
          ]);
        }

        // 3. Verify SessionsController automatically recomputed!
        sessionsState = container.read(sessionsControllerProvider);
        candidates = sessionsState.candidatesState.dataOrNull!;

        window10to12 = candidates.firstWhere(
          (c) => c.window.start == DateTime(2026, 9, 30, 10, 0),
        );

        // Turnout is now 6/6 quorum -> no veto, score jumps to Excellent!
        expect(window10to12.window.playerCount, equals(6));
        expect(window10to12.hasVeto, isFalse);
        expect(window10to12.score, greaterThanOrEqualTo(85.0));
        expect(window10to12.rating, equals(SessionRating.excellent));
      },
    );

    test(
      'filtering by minScore and minPlayers narrows recommendations',
      () async {
        final playersController = container.read(
          playersControllerProvider.notifier,
        );
        final sessionsController = container.read(
          sessionsControllerProvider.notifier,
        );
        sessionsController.setSelectedDate(matchDate);

        // Add 6 players free 14:00 to 16:00
        for (int i = 1; i <= 6; i++) {
          final p = await playersController.addPlayer('P$i', id: 'p$i');
          await playersController.setAvailability(p.id, matchDate, [
            AvailabilitySlot(
              start: DateTime(2026, 9, 30, 14, 0),
              end: DateTime(2026, 9, 30, 16, 0),
            ),
          ]);
        }

        // Filter: minScore 80
        sessionsController.setMinScoreFilter(80.0);
        var state = container.read(sessionsControllerProvider);
        var list = state.candidatesState.dataOrNull!;
        expect(list.every((c) => c.score >= 80.0), isTrue);

        // Filter: minPlayers 6
        sessionsController.setMinPlayersFilter(6);
        state = container.read(sessionsControllerProvider);
        list = state.candidatesState.dataOrNull!;
        expect(list.every((c) => c.window.playerCount >= 6), isTrue);
      },
    );

    test(
      'sorting by time, score, and attendance orders candidates appropriately',
      () async {
        final playersController = container.read(
          playersControllerProvider.notifier,
        );
        final sessionsController = container.read(
          sessionsControllerProvider.notifier,
        );
        sessionsController.setSelectedDate(matchDate);

        // P1 & P2 free 10-12; P1-P6 free 14-16
        for (int i = 1; i <= 6; i++) {
          final p = await playersController.addPlayer('Player$i', id: 'p$i');
          final slots = <AvailabilitySlot>[
            AvailabilitySlot(
              start: DateTime(2026, 9, 30, 14, 0),
              end: DateTime(2026, 9, 30, 16, 0),
            ),
          ];
          if (i <= 2) {
            slots.add(
              AvailabilitySlot(
                start: DateTime(2026, 9, 30, 10, 0),
                end: DateTime(2026, 9, 30, 12, 0),
              ),
            );
          }
          await playersController.setAvailability(p.id, matchDate, slots);
        }

        // Sort by score
        sessionsController.setSortBy(SessionSortBy.score);
        var list = container
            .read(sessionsControllerProvider)
            .candidatesState
            .dataOrNull!;
        for (int i = 0; i < list.length - 1; i++) {
          expect(list[i].score, greaterThanOrEqualTo(list[i + 1].score));
        }

        // Sort by time
        sessionsController.setSortBy(SessionSortBy.time);
        list = container
            .read(sessionsControllerProvider)
            .candidatesState
            .dataOrNull!;
        for (int i = 0; i < list.length - 1; i++) {
          expect(
            list[i].window.start.isBefore(list[i + 1].window.start) ||
                list[i].window.start.isAtSameMomentAs(list[i + 1].window.start),
            isTrue,
          );
        }
      },
    );
  });
}
