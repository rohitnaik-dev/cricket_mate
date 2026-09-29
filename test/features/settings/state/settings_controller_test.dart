import 'package:cricket_mate/features/sessions/domain/ball_type.dart';
import 'package:cricket_mate/features/settings/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late SettingsController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    controller = SettingsController(prefs);
  });

  group('SettingsController', () {
    test('initial state uses sensible defaults', () {
      expect(controller.state.ballType, equals(BallType.tennis));
      expect(
        controller.state.sessionDuration,
        equals(const Duration(hours: 2)),
      );
      expect(controller.state.quorum, equals(6));
      expect(controller.state.themeMode, equals(ThemeMode.system));
      expect(controller.state.locale, isNull);
    });

    test('updates ballType and persists across reloads', () async {
      await controller.setBallType(BallType.leather);
      expect(controller.state.ballType, equals(BallType.leather));

      final reloaded = SettingsController(prefs);
      expect(reloaded.state.ballType, equals(BallType.leather));
    });

    test('updates sessionDuration and persists across reloads', () async {
      await controller.setSessionDuration(const Duration(minutes: 90));
      expect(
        controller.state.sessionDuration,
        equals(const Duration(minutes: 90)),
      );

      final reloaded = SettingsController(prefs);
      expect(
        reloaded.state.sessionDuration,
        equals(const Duration(minutes: 90)),
      );
    });

    test('updates quorum and persists across reloads', () async {
      await controller.setQuorum(8);
      expect(controller.state.quorum, equals(8));

      final reloaded = SettingsController(prefs);
      expect(reloaded.state.quorum, equals(8));
    });

    test('updates themeMode and locale and persists across reloads', () async {
      await controller.setThemeMode(ThemeMode.dark);
      await controller.setLocale(const Locale('en'));

      expect(controller.state.themeMode, equals(ThemeMode.dark));
      expect(controller.state.locale, equals(const Locale('en')));

      final reloaded = SettingsController(prefs);
      expect(reloaded.state.themeMode, equals(ThemeMode.dark));
      expect(reloaded.state.locale, equals(const Locale('en')));

      // Clearing locale
      await controller.setLocale(null);
      expect(controller.state.locale, isNull);
    });
  });
}
