import 'package:cricket_mate/core/state/view_state.dart';
import 'package:cricket_mate/features/players/data/models/player.dart';
import 'package:cricket_mate/features/players/domain/overlap_window.dart';
import 'package:cricket_mate/features/players/state/players_controller.dart';
import 'package:cricket_mate/features/sessions/domain/ball_type.dart';
import 'package:cricket_mate/features/sessions/domain/conditions_scorer.dart';
import 'package:cricket_mate/features/sessions/domain/reason_chip.dart';
import 'package:cricket_mate/features/sessions/domain/session_candidate.dart';
import 'package:cricket_mate/features/sessions/domain/weather_scorer.dart';
import 'package:cricket_mate/features/sessions/ui/session_detail_screen.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/hourly_conditions_strip.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/players_attendance_section.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/score_breakdown_bars.dart';
import 'package:cricket_mate/features/sessions/ui/widgets/score_ring.dart';
import 'package:cricket_mate/features/weather/data/cache_store.dart';
import 'package:cricket_mate/features/weather/repository/weather_repository.dart';
import 'package:cricket_mate/features/weather/state/place_controller.dart';
import 'package:cricket_mate/features/weather/state/weather_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final player1 = Player(id: 'p1', name: 'Rohit Sharma');
  final player2 = Player(id: 'p2', name: 'Virat Kohli');
  final player3 = Player(id: 'p3', name: 'Jasprit Bumrah');
  final player4 = Player(id: 'p4', name: 'KL Rahul');
  final player5 = Player(id: 'p5', name: 'Shubman Gill');

  final availableSquad = [player1, player2, player3];
  final allSquad = [player1, player2, player3, player4, player5];

  final windowStart = DateTime(2026, 9, 30, 15, 0);
  final windowEnd = DateTime(2026, 9, 30, 18, 0);

  final testWindow = OverlapWindow(
    start: windowStart,
    end: windowEnd,
    players: availableSquad,
  );

  const testWeatherScores = WeatherSubScores(
    rain: 95.0,
    temperature: 88.0,
    wind: 80.0,
    humidity: 75.0,
    uv: 90.0,
    total: 87.5,
  );

  const testConditionsScores = ConditionsSubScores(
    wetOutfield: 90.0,
    dewRisk: 85.0,
    daylight: 100.0,
    total: 91.5,
  );

  final testCandidate = SessionCandidate(
    window: testWindow,
    score: 84.5,
    rating: SessionRating.good,
    weatherScores: testWeatherScores,
    conditionsScores: testConditionsScores,
    availabilityScore: 80.0,
    ballType: BallType.leather,
    reasonChips: const [
      ReasonChip.positive('Low rain chance (< 10%)'),
      ReasonChip.positive('Ideal batting temperature (23°C)'),
      ReasonChip.warning('Moderate wind gusts possible'),
    ],
  );

  final vetoCandidate = SessionCandidate(
    window: testWindow,
    score: 25.0,
    rating: SessionRating.notRecommended,
    weatherScores: testWeatherScores,
    conditionsScores: testConditionsScores,
    availabilityScore: 20.0,
    ballType: BallType.leather,
    reasonChips: const [ReasonChip.negative('Thunderstorm danger imminent')],
    vetoReasons: const [
      'High rain probability (85%) during match window',
      'Thunderstorm alert (WMO code 95)',
    ],
  );

  final hourlyWeather = List.generate(24, (hour) {
    return HourlyWeather(
      time: DateTime(2026, 9, 30, hour, 0),
      temperature2m: 21.0 + (hour % 5),
      apparentTemperature: 21.5 + (hour % 5),
      precipitationProbability: hour == 16 ? 15 : 5,
      precipitation: 0.0,
      windSpeed10m: 10.0,
      windGusts10m: 15.0,
      relativeHumidity2m: 50,
      uvIndex: 4.5,
      weatherCode: 0,
      isDay: hour >= 6 && hour <= 19,
      dewPoint2m: 11.0,
    );
  });

  final dailyAstro = [
    DailyAstro(
      date: matchDate,
      sunrise: DateTime(2026, 9, 30, 6, 55),
      sunset: DateTime(2026, 9, 30, 18, 42),
    ),
  ];

  final testForecast = WeatherForecast(
    latitude: 51.5298,
    longitude: -0.1722,
    timezone: 'Europe/London',
    utcOffsetSeconds: 0,
    hourly: hourlyWeather,
    dailyAstro: dailyAstro,
  );

  Widget createSubject({
    required SharedPreferences prefs,
    required SessionCandidate candidate,
    String? placeName,
    List<Override> additionalOverrides = const [],
    Size size = const Size(400, 850),
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        squadPlayersProvider.overrideWithValue(allSquad),
        weatherControllerProvider.overrideWith(
          (ref) => _FakeWeatherController(
            ViewState.success(
              testForecast,
              updatedAt: DateTime.now(),
              fromCache: false,
            ),
          ),
        ),
        selectedPlaceProvider.overrideWithValue(testPlace),
        ...additionalOverrides,
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: SessionDetailScreen(
            candidate: candidate,
            placeName: placeName,
          ),
        ),
      ),
    );
  }

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SessionDetailScreen Widget Tests', () {
    testWidgets(
      'renders Hero header with window, score, venue, and ball type',
      (tester) async {
        await tester.pumpWidget(
          createSubject(
            prefs: prefs,
            candidate: testCandidate,
            placeName: "Lord's Cricket Ground",
          ),
        );
        await tester.pumpAndSettle();

        // Screen title
        expect(find.text('Session Details'), findsOneWidget);

        // Hero header
        expect(find.text("Lord's Cricket Ground"), findsOneWidget);
        expect(find.text('Leather Ball'), findsOneWidget);
        expect(find.text('3 confirmed available'), findsOneWidget);

        // Animated Score ring exists
        expect(find.byType(ScoreRing), findsOneWidget);
        expect(find.text('85'), findsOneWidget); // Score 84.5 rounds to 85
      },
    );

    testWidgets('renders "Why this time?" breakdown bars and ReasonChips', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(prefs: prefs, candidate: testCandidate),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScoreBreakdownBars), findsOneWidget);
      expect(find.text('Why this time?'), findsOneWidget);
      expect(find.text('Weather & Comfort'), findsOneWidget);
      expect(find.text('(60% weight)'), findsOneWidget);
      expect(find.text('(30% weight)'), findsOneWidget);
      expect(find.text('Ground & Daylight Conditions'), findsOneWidget);
      expect(find.text('(10% weight)'), findsOneWidget);

      // Reason chips
      expect(find.text('Low rain chance (< 10%)'), findsOneWidget);
      expect(find.text('Ideal batting temperature (23°C)'), findsOneWidget);
      expect(find.text('Moderate wind gusts possible'), findsOneWidget);
    });

    testWidgets('renders veto warning banner when candidate has hard vetoes', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(prefs: prefs, candidate: vetoCandidate),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session Viability Veto Triggered'), findsOneWidget);
      expect(
        find.textContaining('High rain probability (85%)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Thunderstorm alert (WMO code 95)'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders Squad Attendance section with confirmed & missing members',
      (tester) async {
        await tester.pumpWidget(
          createSubject(prefs: prefs, candidate: testCandidate),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlayersAttendanceSection), findsOneWidget);
        expect(find.text('Squad Attendance'), findsWidgets);
        expect(find.text('3/5 available'), findsOneWidget);

        // Confirmed players
        expect(find.text('Confirmed Available (3)'), findsOneWidget);
        expect(find.text('Rohit Sharma'), findsOneWidget);
        expect(find.text('Virat Kohli'), findsOneWidget);
        expect(find.text('Jasprit Bumrah'), findsOneWidget);

        // Missing players
        expect(find.text('Unavailable / Missing (2)'), findsOneWidget);
        expect(find.text('KL Rahul'), findsOneWidget);
        expect(find.text('Shubman Gill'), findsOneWidget);
      },
    );

    testWidgets('renders Hourly Forecast strip with CustomPainter and legend', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(prefs: prefs, candidate: testCandidate),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HourlyConditionsStrip), findsOneWidget);
      expect(find.text('Hourly Forecast'), findsOneWidget);
      expect(find.text('Window ± 2h'), findsOneWidget);
      expect(find.text('Temp (°C)'), findsOneWidget);
      expect(find.text('Rain %'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);

      // Verify custom painter is present
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders Open-Meteo attribution notice', (tester) async {
      await tester.pumpWidget(
        createSubject(prefs: prefs, candidate: testCandidate),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weather data by Open-Meteo.com'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at narrow 320dp width', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          prefs: prefs,
          candidate: testCandidate,
          size: const Size(320, 700),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SessionDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 200% text scale', (
      tester,
    ) async {
      FlutterErrorDetails? caught;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caught = details;
        originalOnError?.call(details);
      };

      try {
        await tester.pumpWidget(
          createSubject(prefs: prefs, candidate: testCandidate, textScale: 2.0),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SessionDetailScreen), findsOneWidget);
        if (caught != null) {
          debugPrint('CAUGHT CONTEXT: ${caught?.context?.toDescription()}');
          debugPrint('CAUGHT SUMMARY: ${caught?.summary.toDescription()}');
          for (final d
              in caught?.informationCollector?.call() ?? <DiagnosticsNode>[]) {
            debugPrint('INFO: ${d.toDescription()}');
          }
        }
        expect(tester.takeException(), isNull);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('renders two-pane layout in landscape mode without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          prefs: prefs,
          candidate: testCandidate,
          size: const Size(900, 500),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SessionDetailScreen), findsOneWidget);
      expect(find.text('Why this time?'), findsOneWidget);
      expect(find.text('Hourly Forecast'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('buildInviteText constructs well-formatted WhatsApp message', () {
      final invite = SessionDetailScreen.buildInviteText(
        candidate: testCandidate,
        placeName: "Lord's Cricket Ground",
        allPlayers: allSquad,
      );

      expect(invite, contains('🏏 *Cricket Match Invitation!*'));
      expect(invite, contains("📍 *Venue:* Lord's Cricket Ground"));
      expect(invite, contains('⏰ *Time:*'));
      expect(invite, contains('⭐ *Viability Score:* 85/100 (Good)'));
      expect(invite, contains('🎯 *Ball Type:* Leather Ball'));
      expect(invite, contains('🌤️ *Why this time:*'));
      expect(invite, contains('• Low rain chance (< 10%)'));
      expect(invite, contains('👥 *Confirmed Lineup (3):*'));
      expect(invite, contains('✅ Rohit Sharma'));
      expect(invite, contains('✅ Virat Kohli'));
      expect(invite, contains('✅ Jasprit Bumrah'));
      expect(invite, contains("Let's play cricket! 🏏"));
    });
  });
}

class _FakeWeatherRepository implements WeatherRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWeatherController extends WeatherController {
  _FakeWeatherController(ViewState<WeatherForecast> initial)
    : super(_FakeWeatherRepository()) {
    state = initial;
  }
}
