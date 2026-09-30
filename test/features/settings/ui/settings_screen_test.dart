import 'package:cricket_mate/core/l10n/app_localizations.dart';
import 'package:cricket_mate/core/theme/app_theme.dart';
import 'package:cricket_mate/features/sessions/domain/ball_type.dart';
import 'package:cricket_mate/features/settings/state/settings_controller.dart';
import 'package:cricket_mate/features/settings/ui/settings_screen.dart';
import 'package:cricket_mate/features/weather/data/cache_store.dart';
import 'package:cricket_mate/features/weather/data/models/place.dart';
import 'package:cricket_mate/features/weather/state/place_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  const testPlace = Place(
    name: "Lord's Cricket Ground",
    admin1: 'London',
    country: 'United Kingdom',
    latitude: 51.5298,
    longitude: -0.1722,
    timezone: 'Europe/London',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject({
    required SharedPreferences prefs,
    Size size = const Size(400, 800),
    double textScale = 1.0,
    Locale? initialLocale,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        selectedPlaceProvider.overrideWith((ref) => testPlace),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(settingsControllerProvider);
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale ?? initialLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
              ),
              child: const SettingsScreen(),
            ),
          );
        },
      ),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all preferences and attribution sections', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Titles and sections
      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('Match Preferences'), findsOneWidget);
      expect(find.text('Default Ball Type'), findsOneWidget);
      expect(find.text('Default Match Duration'), findsOneWidget);
      expect(find.text('Minimum Squad Quorum'), findsOneWidget);
      expect(find.text('App Preferences'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('About & Data Sources'), findsOneWidget);
      expect(find.text('Data Attribution'), findsOneWidget);
      expect(
        find.textContaining('Open-Meteo.com under CC BY 4.0'),
        findsOneWidget,
      );
      expect(find.textContaining("Lord's Cricket Ground"), findsOneWidget);
    });

    testWidgets('updates ball type setting upon tap', (tester) async {
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Tap 'Leather' ball segment
      await tester.tap(find.text('Leather'));
      await tester.pumpAndSettle();

      // Verify SharedPreferences persisted
      expect(
        prefs.getString(SettingsController.ballTypeKey),
        equals(BallType.leather.name),
      );
      expect(
        find.textContaining('Traditional red cricket ball'),
        findsOneWidget,
      );

      // Tap 'Box' ball segment
      await tester.tap(find.text('Box'));
      await tester.pumpAndSettle();
      expect(
        prefs.getString(SettingsController.ballTypeKey),
        equals(BallType.box.name),
      );
    });

    testWidgets('updates session duration upon tap', (tester) async {
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Tap '1.5h' (90 min)
      await tester.tap(find.text('1.5h'));
      await tester.pumpAndSettle();

      expect(prefs.getInt(SettingsController.sessionDurationKey), equals(90));

      // Tap '3h' (180 min)
      await tester.tap(find.text('3h'));
      await tester.pumpAndSettle();

      expect(prefs.getInt(SettingsController.sessionDurationKey), equals(180));
    });

    testWidgets('increments and decrements squad quorum with bounds', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Default quorum is 6
      expect(find.text('6'), findsOneWidget);

      // Tap increase (+) button
      await tester.tap(find.byTooltip('Increase quorum'));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(prefs.getInt(SettingsController.quorumKey), equals(7));

      // Tap decrease (-) button twice
      await tester.tap(find.byTooltip('Decrease quorum'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Decrease quorum'));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(prefs.getInt(SettingsController.quorumKey), equals(5));
    });

    testWidgets('switches theme mode between system, light, and dark', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Tap Dark theme
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(
        prefs.getString(SettingsController.themeModeKey),
        equals(ThemeMode.dark.name),
      );

      // Tap Light theme
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(
        prefs.getString(SettingsController.themeModeKey),
        equals(ThemeMode.light.name),
      );
    });

    testWidgets('switches language to Hindi and translates UI', (tester) async {
      await tester.pumpWidget(buildSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Tap 'हिन्दी'
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      // Verify saved to preferences
      expect(prefs.getString(SettingsController.localeKey), equals('hi'));

      // Verify UI translated into Hindi
      expect(find.text('सेटिंग्स और प्राथमिकताएं'), findsOneWidget);
      expect(find.text('मैच प्राथमिकताएं'), findsOneWidget);
      expect(find.text('डिफ़ॉल्ट गेंद का प्रकार'), findsOneWidget);
      expect(find.text('डिफ़ॉल्ट मैच अवधि'), findsOneWidget);
      expect(find.text('न्यूनतम टीम कोरम'), findsOneWidget);
      expect(find.text('ऐप प्राथमिकताएं'), findsOneWidget);
      expect(find.text('थीम'), findsOneWidget);
      expect(find.text('भाषा'), findsOneWidget);
      expect(find.text('ऐप के बारे में और डेटा स्रोत'), findsOneWidget);
      expect(find.text('डेटा श्रेय'), findsOneWidget);

      // Switch back to English
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Settings & Preferences'), findsOneWidget);
    });

    testWidgets(
      'ensures interactive controls meet minimum 48x48dp touch targets',
      (tester) async {
        await tester.pumpWidget(buildSubject(prefs: prefs));
        await tester.pumpAndSettle();

        final decreaseFinder = find.byTooltip('Decrease quorum');
        final increaseFinder = find.byTooltip('Increase quorum');

        final decreaseSize = tester.getSize(decreaseFinder);
        final increaseSize = tester.getSize(increaseFinder);

        expect(
          decreaseSize.width,
          greaterThanOrEqualTo(48.0),
          reason: 'Decrease button width must be >= 48dp',
        );
        expect(
          decreaseSize.height,
          greaterThanOrEqualTo(48.0),
          reason: 'Decrease button height must be >= 48dp',
        );

        expect(
          increaseSize.width,
          greaterThanOrEqualTo(48.0),
          reason: 'Increase button width must be >= 48dp',
        );
        expect(
          increaseSize.height,
          greaterThanOrEqualTo(48.0),
          reason: 'Increase button height must be >= 48dp',
        );
      },
    );

    testWidgets(
      'renders cleanly without overflow at 320x568 width with 200% text scale',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            prefs: prefs,
            size: const Size(320, 568),
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();

        // Verify screen renders and scrolls without any RenderFlex overflow
        expect(find.text('Settings & Preferences'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Scroll down to the bottom
        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders two-column layout in landscape without overflow at 200% text scale',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            prefs: prefs,
            size: const Size(568, 320),
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();

        // Verify two-column side-by-side layout renders
        expect(find.byType(Row), findsWidgets);
        expect(find.text('Settings & Preferences'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Scroll both columns
        final listViews = find.byType(ListView);
        expect(listViews, findsNWidgets(2));

        await tester.drag(listViews.first, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.drag(listViews.last, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
