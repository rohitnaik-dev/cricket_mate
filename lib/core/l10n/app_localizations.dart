import 'package:flutter/widgets.dart';

/// App-level string constants and localization helper.
class AppStrings {
  const AppStrings._();

  static const String appTitle = 'CricketMate';
  static const String plannerTitle = 'Cricket Session Planner';
  static const String findSessionPrompt =
      'When should our group play cricket today?';
  static const String weatherTab = 'Weather';
  static const String playersTab = 'Players';
  static const String sessionsTab = 'Sessions';
  static const String settingsTab = 'Settings';
  static const String attributionNotice = 'Weather data by Open-Meteo.com';
  static const String attributionUrl = 'https://open-meteo.com/';
}

/// Baseline localizations delegate for CricketMate.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) {
    return Future.value(const AppStrings._());
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
