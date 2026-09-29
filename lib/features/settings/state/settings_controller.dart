import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../sessions/domain/ball_type.dart';
import '../../weather/data/cache_store.dart';

/// Immutable model holding user-configured application and match settings.
@immutable
class SettingsState {
  const SettingsState({
    this.ballType = BallType.tennis,
    this.sessionDuration = const Duration(hours: 2),
    this.quorum = 6,
    this.themeMode = ThemeMode.system,
    this.locale,
  });

  /// Default cricket ball type for sessions planning.
  final BallType ballType;

  /// Default duration for planned cricket matches.
  final Duration sessionDuration;

  /// Minimum squad quorum required for a viable match.
  final int quorum;

  /// Active application theme mode.
  final ThemeMode themeMode;

  /// Active application locale (or system locale if null).
  final Locale? locale;

  /// Copies this state with optional property replacements.
  SettingsState copyWith({
    BallType? ballType,
    Duration? sessionDuration,
    int? quorum,
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
  }) {
    return SettingsState(
      ballType: ballType ?? this.ballType,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      quorum: quorum ?? this.quorum,
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsState &&
        other.ballType == ballType &&
        other.sessionDuration == sessionDuration &&
        other.quorum == quorum &&
        other.themeMode == themeMode &&
        other.locale == locale;
  }

  @override
  int get hashCode =>
      Object.hash(ballType, sessionDuration, quorum, themeMode, locale);
}

/// Controller managing persistent user preferences.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._prefs) : super(const SettingsState()) {
    _loadFromPreferences();
  }

  final SharedPreferences _prefs;

  static const String ballTypeKey = 'cricket_mate_ball_type';
  static const String sessionDurationKey =
      'cricket_mate_session_duration_minutes';
  static const String quorumKey = 'cricket_mate_quorum';
  static const String themeModeKey = 'cricket_mate_theme_mode';
  static const String localeKey = 'cricket_mate_locale';

  void _loadFromPreferences() {
    // 1. Ball type
    final ballStr = _prefs.getString(ballTypeKey);
    final ballType = ballStr != null
        ? BallType.values.firstWhere(
            (b) => b.name == ballStr,
            orElse: () => BallType.tennis,
          )
        : BallType.tennis;

    // 2. Session duration
    final durationMinutes = _prefs.getInt(sessionDurationKey) ?? 120;

    // 3. Quorum
    final quorum = _prefs.getInt(quorumKey) ?? 6;

    // 4. Theme mode
    final themeStr = _prefs.getString(themeModeKey);
    final themeMode = themeStr != null
        ? ThemeMode.values.firstWhere(
            (t) => t.name == themeStr,
            orElse: () => ThemeMode.system,
          )
        : ThemeMode.system;

    // 5. Locale
    final localeStr = _prefs.getString(localeKey);
    final locale = localeStr != null ? Locale(localeStr) : null;

    state = SettingsState(
      ballType: ballType,
      sessionDuration: Duration(minutes: durationMinutes),
      quorum: quorum,
      themeMode: themeMode,
      locale: locale,
    );
  }

  /// Sets preferred [ballType] and saves to preferences.
  Future<void> setBallType(BallType ballType) async {
    state = state.copyWith(ballType: ballType);
    await _prefs.setString(ballTypeKey, ballType.name);
  }

  /// Sets preferred [duration] and saves to preferences.
  Future<void> setSessionDuration(Duration duration) async {
    state = state.copyWith(sessionDuration: duration);
    await _prefs.setInt(sessionDurationKey, duration.inMinutes);
  }

  /// Sets squad [quorum] requirement and saves to preferences.
  Future<void> setQuorum(int quorum) async {
    state = state.copyWith(quorum: quorum);
    await _prefs.setInt(quorumKey, quorum);
  }

  /// Sets application [themeMode] and saves to preferences.
  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _prefs.setString(themeModeKey, themeMode.name);
  }

  /// Sets application [locale] and saves to preferences.
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      state = state.copyWith(clearLocale: true);
      await _prefs.remove(localeKey);
    } else {
      state = state.copyWith(locale: locale);
      await _prefs.setString(localeKey, locale.languageCode);
    }
  }
}

/// Riverpod provider for [SettingsController].
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SettingsController(prefs);
    });
