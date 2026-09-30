import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Extension on [BuildContext] for easy, ergonomic access to [AppLocalizations].
extension LocalizedBuildContext on BuildContext {
  /// Resolves the nearest [AppLocalizations] instance.
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations != null) {
      return localizations;
    }
    // Fallback if accessed in widget tests or before localization delegates load
    return lookupAppLocalizations(const Locale('en'));
  }
}

/// App-level string constants and fallback localization helper.
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
