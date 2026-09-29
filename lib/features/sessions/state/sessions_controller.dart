import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/view_state.dart';
import '../../players/domain/find_overlaps.dart';
import '../../players/state/players_controller.dart';
import '../../settings/state/settings_controller.dart';
import '../../weather/state/weather_controller.dart';
import '../domain/ball_type.dart';
import '../domain/session_candidate.dart';
import '../domain/session_scorer.dart';

/// Available sorting modes for recommended cricket sessions.
enum SessionSortBy {
  /// Ranks highest session score first (default).
  score,

  /// Ranks chronologically by earliest session start time.
  time,

  /// Ranks by highest number of confirmed available squad players.
  attendance;

  String get label => switch (this) {
    SessionSortBy.score => 'Highest Score',
    SessionSortBy.time => 'Earliest Time',
    SessionSortBy.attendance => 'Most Players',
  };
}

/// State container holding ranked sessions and active filter/sort criteria.
@immutable
class SessionsState {
  const SessionsState({
    this.candidatesState = const ViewState.empty(),
    this.selectedDate,
    this.customDuration,
    this.customBallType,
    this.minPlayersFilter,
    this.minScoreFilter = 0.0,
    this.sortBy = SessionSortBy.score,
  });

  /// ViewState containing the ranked list of session recommendations.
  final ViewState<List<SessionCandidate>> candidatesState;

  /// Custom match date (or falls back to players selected date).
  final DateTime? selectedDate;

  /// Optional override for session duration.
  final Duration? customDuration;

  /// Optional override for ball type.
  final BallType? customBallType;

  /// Optional filter for minimum attending players.
  final int? minPlayersFilter;

  /// Minimum score threshold filter (0.0 - 100.0).
  final double minScoreFilter;

  /// Active sorting strategy.
  final SessionSortBy sortBy;

  /// Creates a copy with optional parameter overrides.
  SessionsState copyWith({
    ViewState<List<SessionCandidate>>? candidatesState,
    DateTime? selectedDate,
    Duration? customDuration,
    BallType? customBallType,
    int? minPlayersFilter,
    double? minScoreFilter,
    SessionSortBy? sortBy,
    bool clearCustomDuration = false,
    bool clearCustomBallType = false,
    bool clearMinPlayersFilter = false,
  }) {
    return SessionsState(
      candidatesState: candidatesState ?? this.candidatesState,
      selectedDate: selectedDate ?? this.selectedDate,
      customDuration: clearCustomDuration
          ? null
          : (customDuration ?? this.customDuration),
      customBallType: clearCustomBallType
          ? null
          : (customBallType ?? this.customBallType),
      minPlayersFilter: clearMinPlayersFilter
          ? null
          : (minPlayersFilter ?? this.minPlayersFilter),
      minScoreFilter: minScoreFilter ?? this.minScoreFilter,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionsState &&
        other.candidatesState == candidatesState &&
        other.selectedDate == selectedDate &&
        other.customDuration == customDuration &&
        other.customBallType == customBallType &&
        other.minPlayersFilter == minPlayersFilter &&
        other.minScoreFilter == minScoreFilter &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode => Object.hash(
    candidatesState,
    selectedDate,
    customDuration,
    customBallType,
    minPlayersFilter,
    minScoreFilter,
    sortBy,
  );
}

/// Controller deriving ranked session candidates reactively from weather, squad availability, and settings.
class SessionsController extends StateNotifier<SessionsState> {
  SessionsController(this._ref) : super(const SessionsState()) {
    recompute();
  }

  final Ref _ref;

  /// Recomputes session candidates using current weather, players, and settings providers.
  void recompute() {
    final weatherState = _ref.read(weatherControllerProvider);
    final playersState = _ref.read(playersControllerProvider);
    final settingsState = _ref.read(settingsControllerProvider);

    // 1. Evaluate Weather ViewState
    final forecast = weatherState.dataOrNull;
    if (weatherState.isLoading) {
      state = state.copyWith(candidatesState: const ViewState.loading());
      return;
    }
    if (weatherState.isFailure) {
      final failure = weatherState as ViewFailure;
      state = state.copyWith(
        candidatesState: ViewState.failure(failure.exception),
      );
      return;
    }
    if (forecast == null || forecast.hourly.isEmpty) {
      state = state.copyWith(
        candidatesState: const ViewState.empty(
          'Select a location to check weather and calculate sessions.',
        ),
      );
      return;
    }

    // 2. Evaluate Players ViewState
    if (playersState.playersState.isLoading) {
      state = state.copyWith(candidatesState: const ViewState.loading());
      return;
    }
    final squad = playersState.players;
    if (squad.isEmpty) {
      state = state.copyWith(
        candidatesState: const ViewState.empty(
          'Add squad members to calculate candidate sessions.',
        ),
      );
      return;
    }

    // 3. Resolve planning parameters
    final targetDate = state.selectedDate ?? playersState.selectedDate;
    final duration = state.customDuration ?? settingsState.sessionDuration;
    final ballType = state.customBallType ?? settingsState.ballType;
    final quorum = settingsState.quorum;

    // 4. Calculate candidate windows across 30-min slots
    final windows = findOverlaps(
      squad,
      targetDate,
      duration,
      minPlayers: 0, // Include all candidate windows to evaluate them
    );

    if (windows.isEmpty) {
      state = state.copyWith(
        candidatesState: const ViewState.empty(
          'No time windows found for the chosen date and duration.',
        ),
      );
      return;
    }

    // 5. Score candidate windows
    final allCandidates = SessionScorer.scoreCandidates(
      windows: windows,
      allHourlyWeather: forecast.hourly,
      totalSquad: squad.length,
      ballType: ballType,
      quorum: quorum,
    );

    // 6. Apply user-defined filters
    var filtered = allCandidates;

    if (state.minPlayersFilter != null) {
      filtered = filtered
          .where((c) => c.window.playerCount >= state.minPlayersFilter!)
          .toList();
    }

    if (state.minScoreFilter > 0.0) {
      filtered = filtered
          .where((c) => c.score >= state.minScoreFilter)
          .toList();
    }

    // 7. Apply sorting strategy
    switch (state.sortBy) {
      case SessionSortBy.score:
        filtered.sort((a, b) => b.score.compareTo(a.score));
      case SessionSortBy.time:
        filtered.sort((a, b) => a.window.start.compareTo(b.window.start));
      case SessionSortBy.attendance:
        filtered.sort((a, b) {
          final countCmp = b.window.playerCount.compareTo(a.window.playerCount);
          if (countCmp != 0) return countCmp;
          return b.score.compareTo(a.score);
        });
    }

    if (filtered.isEmpty) {
      state = state.copyWith(
        candidatesState: const ViewState.empty(
          'No playing sessions match your filter criteria.',
        ),
      );
    } else {
      state = state.copyWith(candidatesState: ViewState.success(filtered));
    }
  }

  /// Sets sorting mode.
  void setSortBy(SessionSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
    recompute();
  }

  /// Sets minimum score filter threshold.
  void setMinScoreFilter(double minScore) {
    state = state.copyWith(minScoreFilter: minScore);
    recompute();
  }

  /// Sets minimum player attendance filter.
  void setMinPlayersFilter(int? minPlayers) {
    state = state.copyWith(
      minPlayersFilter: minPlayers,
      clearMinPlayersFilter: minPlayers == null,
    );
    recompute();
  }

  /// Overrides match duration for session recommendations.
  void setCustomDuration(Duration? duration) {
    state = state.copyWith(
      customDuration: duration,
      clearCustomDuration: duration == null,
    );
    recompute();
  }

  /// Overrides ball type for session recommendations.
  void setCustomBallType(BallType? ballType) {
    state = state.copyWith(
      customBallType: ballType,
      clearCustomBallType: ballType == null,
    );
    recompute();
  }

  /// Sets planning date.
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    recompute();
  }
}

/// Riverpod provider for [SessionsController].
/// Listens to weather, players, and settings changes and automatically triggers recomputation.
final sessionsControllerProvider =
    StateNotifierProvider<SessionsController, SessionsState>((ref) {
      final controller = SessionsController(ref);

      // Automatically recompute when dependencies change
      ref.listen(weatherControllerProvider, (_, _) => controller.recompute());
      ref.listen(playersControllerProvider, (_, _) => controller.recompute());
      ref.listen(settingsControllerProvider, (_, _) => controller.recompute());

      return controller;
    });
