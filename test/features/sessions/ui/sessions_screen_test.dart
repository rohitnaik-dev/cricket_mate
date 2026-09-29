import 'package:cricket_mate/app.dart';
import 'package:cricket_mate/core/state/view_state.dart';
import 'package:cricket_mate/features/players/repository/player_repository.dart';
import 'package:cricket_mate/features/players/state/players_controller.dart';
import 'package:cricket_mate/features/sessions/state/sessions_controller.dart';
import 'package:cricket_mate/features/sessions/ui/sessions_screen.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/candidate_session_card.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/hero_session_card.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/last_updated_badge.dart';
import 'package:cricket_mate/features/sessions/ui/session_detail_screen.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/session_filter_bar.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/session_shimmer.dart';
import 'package:cricket_mate/features/weather/data/cache_store.dart';
import 'package:cricket_mate/features/weather/repository/weather_repository.dart';
import 'package:cricket_mate/features/weather/state/place_controller.dart';
import 'package:cricket_mate/features/weather/state/weather_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final matchDate = DateTime(2026, 9, 30);
  const testPlace = Place(
    name: 'Lord\'s Cricket Ground',
    admin1: 'London',
    country: 'United Kingdom',
    latitude: 51.5298,
    longitude: -0.1722,
    timezone: 'Europe/London',
  );

  final hourlyWeather = List.generate(24, (hour) {
    return HourlyWeather(
      time: DateTime(2026, 9, 30, hour, 0),
      temperature2m: 23.0,
      apparentTemperature: 23.0,
      precipitationProbability: 0,
      precipitation: 0.0,
      windSpeed10m: 8.0,
      windGusts10m: 12.0,
      relativeHumidity2m: 45,
      uvIndex: 4.0,
      weatherCode: 0,
      isDay: hour >= 6 && hour <= 19,
      dewPoint2m: 10.0,
    );
  });

  final testForecast = WeatherForecast(
    latitude: 51.5298,
    longitude: -0.1722,
    timezone: 'Europe/London',
    utcOffsetSeconds: 0,
    hourly: hourlyWeather,
    dailyAstro: const [],
  );

  Widget createSubject({
    required SharedPreferences prefs,
    List<Override> additionalOverrides = const [],
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...additionalOverrides,
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(body: SessionsScreen()),
        ),
      ),
    );
  }

  group('SessionsScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
      'displays Hero card empty-state variant with CTA when squad has no players',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            prefs: prefs,
            additionalOverrides: [
              placeControllerProvider.overrideWith(
                (ref) =>
                    PlaceController(ref.watch(weatherRepositoryProvider))
                      ..selectPlace(testPlace),
              ),
              weatherControllerProvider.overrideWith(
                (ref) => WeatherController(ref.watch(weatherRepositoryProvider))
                  ..state = ViewState.success(
                    testForecast,
                    updatedAt: DateTime.now(),
                    fromCache: false,
                  ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HeroSessionCard), findsOneWidget);
        expect(find.text('Add players to find a session'), findsOneWidget);
        expect(find.text('Add Squad Members'), findsOneWidget);
        expect(find.byType(SessionFilterBar), findsOneWidget);

        // Tap "Add Squad Members" CTA button
        await tester.tap(find.text('Add Squad Members'));
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(SessionsScreen)),
        );
        expect(container.read(navigationIndexProvider), 1);
      },
    );

    testWidgets(
      'displays Hero card and candidate sessions when squad and weather exist',
      (tester) async {
        final slot = AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 0),
          end: DateTime(2026, 9, 30, 14, 0),
        );

        await tester.pumpWidget(
          createSubject(
            prefs: prefs,
            additionalOverrides: [
              placeControllerProvider.overrideWith(
                (ref) =>
                    PlaceController(ref.watch(weatherRepositoryProvider))
                      ..selectPlace(testPlace),
              ),
              weatherControllerProvider.overrideWith(
                (ref) => WeatherController(ref.watch(weatherRepositoryProvider))
                  ..state = ViewState.success(
                    testForecast,
                    updatedAt: DateTime.now(),
                    fromCache: false,
                  ),
              ),
            ],
          ),
        );
        await tester.pump();

        // Inject players with availability slots
        final element = tester.element(find.byType(SessionsScreen));
        final container = ProviderScope.containerOf(element);

        final playerRepo = container.read(playerRepositoryProvider);
        for (var i = 0; i < 8; i++) {
          final player = Player(id: 'p$i', name: 'Player $i');
          await playerRepo.addPlayer(player);
          await playerRepo.setAvailability(player.id, matchDate, [slot]);
        }
        await container
            .read(playersControllerProvider.notifier)
            .setSelectedDate(matchDate);
        await container.read(playersControllerProvider.notifier).loadPlayers();
        container
            .read(sessionsControllerProvider.notifier)
            .setSelectedDate(matchDate);
        container.read(sessionsControllerProvider.notifier).recompute();
        await tester.pumpAndSettle();

        // Verify Hero Spotlight Card
        expect(find.byType(HeroSessionCard), findsOneWidget);
        expect(find.text('BEST TIME TO PLAY'), findsOneWidget);
        expect(find.text('8/8 players available'), findsWidgets);
        expect(find.text('View Session Details'), findsOneWidget);

        // Verify Secondary Candidate cards (#2, #3, etc.)
        expect(find.byType(CandidateSessionCard), findsWidgets);
        expect(find.text('Other Playing Windows'), findsOneWidget);

        // Tap "View Session Details" to navigate to full SessionDetailScreen
        await tester.tap(find.text('View Session Details'));
        await tester.pumpAndSettle();

        expect(find.byType(SessionDetailScreen), findsOneWidget);
        expect(find.text('Why this time?'), findsOneWidget);
        expect(find.text('Hourly Forecast'), findsOneWidget);
        expect(find.text('Squad Attendance'), findsWidgets);
      },
    );

    testWidgets(
      'displays Offline cache badge when weather is from local storage',
      (tester) async {
        final now = DateTime.now().subtract(const Duration(minutes: 10));

        await tester.pumpWidget(
          createSubject(
            prefs: prefs,
            additionalOverrides: [
              placeControllerProvider.overrideWith(
                (ref) =>
                    PlaceController(ref.watch(weatherRepositoryProvider))
                      ..selectPlace(testPlace),
              ),
              weatherControllerProvider.overrideWith(
                (ref) => WeatherController(ref.watch(weatherRepositoryProvider))
                  ..state = ViewState.success(
                    testForecast,
                    updatedAt: now,
                    fromCache: true,
                  ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LastUpdatedBadge), findsOneWidget);
        expect(
          find.textContaining('Offline • Updated 10m ago'),
          findsOneWidget,
        );
      },
    );

    testWidgets('displays skeleton shimmer during loading state', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          prefs: prefs,
          additionalOverrides: [
            placeControllerProvider.overrideWith(
              (ref) =>
                  PlaceController(ref.watch(weatherRepositoryProvider))
                    ..selectPlace(testPlace),
            ),
            weatherControllerProvider.overrideWith(
              (ref) =>
                  WeatherController(ref.watch(weatherRepositoryProvider))
                    ..state = const ViewState.loading(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(SessionScreenShimmer), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at narrow 320dp width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createSubject(
          prefs: prefs,
          additionalOverrides: [
            placeControllerProvider.overrideWith(
              (ref) =>
                  PlaceController(ref.watch(weatherRepositoryProvider))
                    ..selectPlace(testPlace),
            ),
            weatherControllerProvider.overrideWith(
              (ref) => WeatherController(ref.watch(weatherRepositoryProvider))
                ..state = ViewState.success(
                  testForecast,
                  updatedAt: DateTime.now(),
                  fromCache: false,
                ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HeroSessionCard), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 200% text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createSubject(
          prefs: prefs,
          textScale: 2.0,
          additionalOverrides: [
            placeControllerProvider.overrideWith(
              (ref) =>
                  PlaceController(ref.watch(weatherRepositoryProvider))
                    ..selectPlace(testPlace),
            ),
            weatherControllerProvider.overrideWith(
              (ref) => WeatherController(ref.watch(weatherRepositoryProvider))
                ..state = ViewState.success(
                  testForecast,
                  updatedAt: DateTime.now(),
                  fromCache: false,
                ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HeroSessionCard), findsOneWidget);
    });

    testWidgets('renders two-column layout in landscape orientation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createSubject(
          prefs: prefs,
          additionalOverrides: [
            placeControllerProvider.overrideWith(
              (ref) =>
                  PlaceController(ref.watch(weatherRepositoryProvider))
                    ..selectPlace(testPlace),
            ),
            weatherControllerProvider.overrideWith(
              (ref) => WeatherController(ref.watch(weatherRepositoryProvider))
                ..state = ViewState.success(
                  testForecast,
                  updatedAt: DateTime.now(),
                  fromCache: false,
                ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HeroSessionCard), findsOneWidget);
      expect(find.byType(SessionFilterBar), findsOneWidget);
    });
  });
}
