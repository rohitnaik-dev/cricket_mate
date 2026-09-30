import 'dart:async';

import 'package:cricket_mate/app.dart';
import 'package:cricket_mate/core/errors/app_exception.dart';
import 'package:cricket_mate/core/l10n/app_localizations.dart';
import 'package:cricket_mate/core/state/view_state.dart';
import 'package:cricket_mate/features/players/repository/player_repository.dart';
import 'package:cricket_mate/features/players/state/players_controller.dart';
import 'package:cricket_mate/features/sessions/state/sessions_controller.dart';
import 'package:cricket_mate/features/sessions/ui/session_detail_screen.dart';
import 'package:cricket_mate/features/sessions/ui/sessions_screen.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/candidate_session_card.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/hero_session_card.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/last_updated_badge.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/session_empty_view.dart';
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

/// Test double simulating [WeatherRepository] with configurable responses and call tracking.
class FakeWeatherRepository implements WeatherRepository {
  FakeWeatherRepository({
    this.forecastFuture,
    this.onGetForecast,
    this.selectedPlace,
  });

  Future<Loaded<WeatherForecast>>? forecastFuture;
  Future<Loaded<WeatherForecast>> Function()? onGetForecast;
  Place? selectedPlace;
  int getForecastCalls = 0;

  @override
  Future<List<Place>> searchPlaces(String query) async => const [];

  @override
  Future<Loaded<WeatherForecast>> getForecast(Place place) {
    getForecastCalls++;
    if (onGetForecast != null) {
      return onGetForecast!();
    }
    if (forecastFuture != null) {
      return forecastFuture!;
    }
    throw const NetworkException();
  }

  @override
  Place? getSelectedPlace() => selectedPlace;

  @override
  Future<void> saveSelectedPlace(Place place) async {
    selectedPlace = place;
  }

  Future<void> clearSelectedPlace() async {
    selectedPlace = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final matchDate = DateTime(2026, 9, 30);
  const testPlace = Place(
    name: "Lord's Cricket Ground",
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
      'Sessions screen shows skeleton -> list using provider overrides with a fake repository',
      (tester) async {
        final completer = Completer<Loaded<WeatherForecast>>();
        final fakeRepo = FakeWeatherRepository(
          forecastFuture: completer.future,
          selectedPlace: testPlace,
        );

        final slot = AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 0),
          end: DateTime(2026, 9, 30, 14, 0),
        );

        await tester.pumpWidget(
          createSubject(
            prefs: prefs,
            additionalOverrides: [
              weatherRepositoryProvider.overrideWithValue(fakeRepo),
              selectedPlaceProvider.overrideWith((ref) => testPlace),
            ],
          ),
        );

        // 1. Initial state: forecast is loading via completer -> SessionScreenShimmer
        await tester.pump();
        expect(find.byType(SessionScreenShimmer), findsOneWidget);
        expect(find.byType(HeroSessionCard), findsNothing);

        // Seed registered players with matching availability slots
        final element = tester.element(find.byType(SessionsScreen));
        final container = ProviderScope.containerOf(element);
        final playerRepo = container.read(playerRepositoryProvider);
        for (var i = 0; i < 6; i++) {
          final player = Player(id: 'p$i', name: 'Player $i');
          await playerRepo.addPlayer(player);
          await playerRepo.setAvailability(player.id, matchDate, [slot]);
        }
        await container
            .read(playersControllerProvider.notifier)
            .setSelectedDate(matchDate);
        await container.read(playersControllerProvider.notifier).loadPlayers();

        // 2. Complete weather forecast fetch
        completer.complete(
          Loaded(testForecast, DateTime.now(), fromCache: false),
        );
        await tester.pumpAndSettle();

        // 3. Shimmer replaced by loaded candidate list with Hero card
        expect(find.byType(SessionScreenShimmer), findsNothing);
        expect(find.byType(HeroSessionCard), findsOneWidget);
        expect(find.text('BEST TIME TO PLAY'), findsOneWidget);
        expect(find.text('6/6 players available'), findsWidgets);
      },
    );

    testWidgets(
      'error state shows message and Retry works using fake repository',
      (tester) async {
        var shouldFail = true;
        final completerSuccess = Completer<Loaded<WeatherForecast>>();
        completerSuccess.complete(
          Loaded(testForecast, DateTime.now(), fromCache: false),
        );

        final fakeRepo = FakeWeatherRepository(
          selectedPlace: testPlace,
          onGetForecast: () {
            if (shouldFail) {
              throw const NetworkException();
            }
            return completerSuccess.future;
          },
        );

        await tester.pumpWidget(
          createSubject(
            prefs: prefs,
            additionalOverrides: [
              weatherRepositoryProvider.overrideWithValue(fakeRepo),
              selectedPlaceProvider.overrideWith((ref) => testPlace),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // 1. Error view is displayed with localized message and Retry button
        expect(find.byType(SessionEmptyView), findsOneWidget);
        expect(find.text('Unable to Load Weather'), findsOneWidget);
        expect(
          find.text(
            'Unable to connect to the server. Please check your internet connection.',
          ),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
        expect(fakeRepo.getForecastCalls, 1);

        // 2. Recover network and tap Retry
        shouldFail = false;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // 3. Retry invokes fetchForecast and displays loaded screen
        expect(fakeRepo.getForecastCalls, 2);
        expect(find.text('Unable to Load Weather'), findsNothing);
        expect(find.byType(HeroSessionCard), findsOneWidget);
      },
    );

    testWidgets(
      'offline banner with last-updated appears for cached data using fake repository',
      (tester) async {
        final cachedTime = DateTime.now().subtract(const Duration(minutes: 15));
        final fakeRepo = FakeWeatherRepository(
          forecastFuture: Future.value(
            Loaded(testForecast, cachedTime, fromCache: true),
          ),
          selectedPlace: testPlace,
        );

        await tester.pumpWidget(
          createSubject(
            prefs: prefs,
            additionalOverrides: [
              weatherRepositoryProvider.overrideWithValue(fakeRepo),
              selectedPlaceProvider.overrideWith((ref) => testPlace),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Verify LastUpdatedBadge displays offline cache status
        expect(find.byType(LastUpdatedBadge), findsOneWidget);
        expect(
          find.textContaining('Offline • Updated 15m ago'),
          findsOneWidget,
        );
      },
    );

    testWidgets('empty state variant when there are no players in squad', (
      tester,
    ) async {
      final fakeRepo = FakeWeatherRepository(
        forecastFuture: Future.value(
          Loaded(testForecast, DateTime.now(), fromCache: false),
        ),
        selectedPlace: testPlace,
      );

      await tester.pumpWidget(
        createSubject(
          prefs: prefs,
          additionalOverrides: [
            weatherRepositoryProvider.overrideWithValue(fakeRepo),
            selectedPlaceProvider.overrideWith((ref) => testPlace),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Hero Spotlight Card in empty squad mode
      expect(find.byType(HeroSessionCard), findsOneWidget);
      expect(find.text('Add players to find a session'), findsOneWidget);
      expect(find.text('Add Squad Members'), findsOneWidget);
      expect(find.byType(CandidateSessionCard), findsNothing);

      // Tap "Add Squad Members" CTA button navigates to Players tab
      await tester.tap(find.text('Add Squad Members'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SessionsScreen)),
      );
      expect(container.read(navigationIndexProvider), 1);
    });

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
