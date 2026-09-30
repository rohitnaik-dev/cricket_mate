import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app.dart';
import '../../../core/errors/app_exception_localizer.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/state/view_state.dart';
import '../../players/state/players_controller.dart';
import '../../settings/state/settings_controller.dart';
import '../../weather/data/models/weather_forecast.dart';
import '../../weather/state/place_controller.dart';
import '../../weather/state/weather_controller.dart';
import '../domain/ball_type.dart';
import '../domain/session_candidate.dart';
import '../state/sessions_controller.dart';
import 'session_detail_screen.dart';
import 'widgets/candidate_session_card.dart';
import 'widgets/hero_session_card.dart';
import 'widgets/last_updated_badge.dart';
import 'widgets/place_search_field.dart';
import 'widgets/session_empty_view.dart';
import 'widgets/session_filter_bar.dart';
import 'widgets/session_shimmer.dart';

/// Main screen displaying recommended cricket playing sessions,
/// debounced place search, live/offline weather freshness, filter chips,
/// and responsive single-column or two-column landscape layouts.
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherControllerProvider);
    final sessionsState = ref.watch(sessionsControllerProvider);
    final playersState = ref.watch(playersControllerProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final selectedPlace = ref.watch(selectedPlaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: PlaceSearchField(focusNode: _searchFocusNode),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: _buildBody(
        context,
        ref,
        weatherState: weatherState,
        sessionsState: sessionsState,
        playersState: playersState,
        settingsState: settingsState,
        placeName: selectedPlace?.name,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required ViewState<WeatherForecast> weatherState,
    required SessionsState sessionsState,
    required PlayersState playersState,
    required SettingsState settingsState,
    required String? placeName,
  }) {
    // 1. Shimmer loading state when fetching initial weather or calculating sessions
    if (weatherState.isLoading) {
      return const SessionScreenShimmer();
    }

    final l10n = context.l10n;

    // 2. Weather failure state
    if (weatherState case ViewFailure(:final exception)) {
      return SessionEmptyView(
        icon: Icons.cloud_off,
        title: l10n.unableToLoadWeather,
        message: exception.getLocalizedMessage(context),
        actionLabel: l10n.retry,
        onAction: () => ref.read(weatherControllerProvider.notifier).refresh(),
        isError: true,
      );
    }

    // 3. Prompt user if no place is selected yet
    if (ref.watch(selectedPlaceProvider) == null) {
      return SessionEmptyView(
        icon: Icons.location_searching,
        title: l10n.searchPrompt,
        message: l10n.searchPromptSubtitle,
        actionLabel: l10n.searchLocationButton,
        onAction: () {
          FocusScope.of(context).requestFocus(_searchFocusNode);
        },
      );
    }

    // Extract cache timestamp metadata
    final (updatedAt, fromCache) = switch (weatherState) {
      ViewSuccess<WeatherForecast>(:final updatedAt, :final fromCache) => (
        updatedAt,
        fromCache,
      ),
      _ => (null, false),
    };

    // Candidate session evaluation
    final candidatesState = sessionsState.candidatesState;
    if (candidatesState.isLoading) {
      return const SessionScreenShimmer();
    }

    final squad = playersState.players;
    final candidates = candidatesState.dataOrNull ?? const <SessionCandidate>[];
    final topCandidate = candidates.isNotEmpty ? candidates.first : null;
    final secondaryCandidates = candidates.length > 1
        ? candidates.sublist(1)
        : const <SessionCandidate>[];

    final ballType = sessionsState.customBallType ?? settingsState.ballType;
    final duration =
        sessionsState.customDuration ?? settingsState.sessionDuration;

    final emptyMessage = switch (candidatesState) {
      ViewEmpty(:final message) => message,
      _ => null,
    };

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(weatherControllerProvider.notifier).refresh(),
          ref.read(playersControllerProvider.notifier).loadPlayers(),
        ]);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape =
              constraints.maxWidth >= 600 ||
              MediaQuery.orientationOf(context) == Orientation.landscape &&
                  constraints.maxWidth >= 500;

          if (isLandscape) {
            return _buildTwoColumnLayout(
              context,
              ref,
              topCandidate: topCandidate,
              secondaryCandidates: secondaryCandidates,
              placeName: placeName,
              squadCount: squad.length,
              sessionsState: sessionsState,
              ballType: ballType,
              duration: duration,
              updatedAt: updatedAt,
              fromCache: fromCache,
              emptyMessage: emptyMessage,
            );
          }

          return _buildSingleColumnLayout(
            context,
            ref,
            topCandidate: topCandidate,
            secondaryCandidates: secondaryCandidates,
            placeName: placeName,
            squadCount: squad.length,
            sessionsState: sessionsState,
            ballType: ballType,
            duration: duration,
            updatedAt: updatedAt,
            fromCache: fromCache,
            emptyMessage: emptyMessage,
          );
        },
      ),
    );
  }

  Widget _buildSingleColumnLayout(
    BuildContext context,
    WidgetRef ref, {
    required SessionCandidate? topCandidate,
    required List<SessionCandidate> secondaryCandidates,
    required String? placeName,
    required int squadCount,
    required SessionsState sessionsState,
    required BallType ballType,
    required Duration duration,
    required DateTime? updatedAt,
    required bool fromCache,
    required String? emptyMessage,
  }) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32.0),
      children: [
        if (updatedAt != null || fromCache)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                LastUpdatedBadge(
                  updatedAt: updatedAt,
                  fromCache: fromCache,
                  onRefresh: () =>
                      ref.read(weatherControllerProvider.notifier).refresh(),
                ),
                if (topCandidate != null)
                  Text(
                    '${secondaryCandidates.length + 1} options found',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: HeroSessionCard(
            candidate: topCandidate,
            placeName: placeName,
            totalSquadCount: squadCount,
            onViewSession: () {
              if (topCandidate != null) {
                _openSessionDetail(context, topCandidate, placeName: placeName);
              }
            },
            onAddPlayers: () {
              ref.read(navigationIndexProvider.notifier).state = 1;
            },
          ),
        ),
        SessionFilterBar(
          selectedBallType: ballType,
          selectedDuration: duration,
          minPlayers: sessionsState.minPlayersFilter,
          minScore: sessionsState.minScoreFilter,
          sortBy: sessionsState.sortBy,
          onBallTypeSelected: (b) => ref
              .read(sessionsControllerProvider.notifier)
              .setCustomBallType(b),
          onDurationSelected: (d) => ref
              .read(sessionsControllerProvider.notifier)
              .setCustomDuration(d),
          onMinPlayersSelected: (p) => ref
              .read(sessionsControllerProvider.notifier)
              .setMinPlayersFilter(p),
          onMinScoreSelected: (s) => ref
              .read(sessionsControllerProvider.notifier)
              .setMinScoreFilter(s),
          onSortBySelected: (sb) =>
              ref.read(sessionsControllerProvider.notifier).setSortBy(sb),
        ),
        if (secondaryCandidates.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Other Playing Windows',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${secondaryCandidates.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...secondaryCandidates.asMap().entries.map((entry) {
            final index = entry.key;
            final candidate = entry.value;
            return CandidateSessionCard(
              candidate: candidate,
              rank: index + 2,
              totalSquadCount: squadCount,
              onTap: () =>
                  _openSessionDetail(context, candidate, placeName: placeName),
            );
          }),
        ] else if (topCandidate == null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Center(
              child: Text(
                emptyMessage ?? 'No viable cricket sessions found.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTwoColumnLayout(
    BuildContext context,
    WidgetRef ref, {
    required SessionCandidate? topCandidate,
    required List<SessionCandidate> secondaryCandidates,
    required String? placeName,
    required int squadCount,
    required SessionsState sessionsState,
    required BallType ballType,
    required Duration duration,
    required DateTime? updatedAt,
    required bool fromCache,
    required String? emptyMessage,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Spotlight Hero Card + Filters + Freshness status
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (updatedAt != null || fromCache)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: LastUpdatedBadge(
                      updatedAt: updatedAt,
                      fromCache: fromCache,
                      onRefresh: () => ref
                          .read(weatherControllerProvider.notifier)
                          .refresh(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: HeroSessionCard(
                    candidate: topCandidate,
                    placeName: placeName,
                    totalSquadCount: squadCount,
                    onViewSession: () {
                      if (topCandidate != null) {
                        _openSessionDetail(
                          context,
                          topCandidate,
                          placeName: placeName,
                        );
                      }
                    },
                    onAddPlayers: () {
                      ref.read(navigationIndexProvider.notifier).state = 1;
                    },
                  ),
                ),
                SessionFilterBar(
                  selectedBallType: ballType,
                  selectedDuration: duration,
                  minPlayers: sessionsState.minPlayersFilter,
                  minScore: sessionsState.minScoreFilter,
                  sortBy: sessionsState.sortBy,
                  onBallTypeSelected: (b) => ref
                      .read(sessionsControllerProvider.notifier)
                      .setCustomBallType(b),
                  onDurationSelected: (d) => ref
                      .read(sessionsControllerProvider.notifier)
                      .setCustomDuration(d),
                  onMinPlayersSelected: (p) => ref
                      .read(sessionsControllerProvider.notifier)
                      .setMinPlayersFilter(p),
                  onMinScoreSelected: (s) => ref
                      .read(sessionsControllerProvider.notifier)
                      .setMinScoreFilter(s),
                  onSortBySelected: (sb) => ref
                      .read(sessionsControllerProvider.notifier)
                      .setSortBy(sb),
                ),
              ],
            ),
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Column: Secondary candidate windows
        Expanded(
          flex: 6,
          child: secondaryCandidates.isNotEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Other Playing Windows',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${secondaryCandidates.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...secondaryCandidates.asMap().entries.map((entry) {
                      final index = entry.key;
                      final candidate = entry.value;
                      return CandidateSessionCard(
                        candidate: candidate,
                        rank: index + 2,
                        totalSquadCount: squadCount,
                        onTap: () => _openSessionDetail(
                          context,
                          candidate,
                          placeName: placeName,
                        ),
                      );
                    }),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      emptyMessage ?? 'No additional candidate windows found.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _openSessionDetail(
    BuildContext context,
    SessionCandidate candidate, {
    String? placeName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SessionDetailScreen(candidate: candidate, placeName: placeName),
      ),
    );
  }
}
