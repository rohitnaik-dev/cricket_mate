import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/overlap_window.dart';
import '../../sessions/ui/widgets/session_shimmer.dart';
import '../data/models/player.dart';
import '../state/players_controller.dart';
import 'widgets/add_player_dialog.dart';
import 'widgets/availability_editor_modal.dart';
import 'widgets/overlap_preview_card.dart';
import 'widgets/player_card.dart';
import 'widgets/players_empty_view.dart';

/// Screen managing cricket squad players and their availability for Today and Tomorrow,
/// featuring live overlap computation, inline validation, and undoable player deletion.
class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersState = ref.watch(playersControllerProvider);
    final bestOverlap = ref.watch(bestOverlapWindowProvider);
    final squad = playersState.players;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Squad & Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Player',
            onPressed: () => AddPlayerDialog.show(context),
          ),
        ],
      ),
      body: _buildBody(
        context,
        ref,
        playersState: playersState,
        squad: squad,
        bestOverlap: bestOverlap,
      ),
      floatingActionButton: squad.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => AddPlayerDialog.show(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Player'),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required PlayersState playersState,
    required List<Player> squad,
    required OverlapWindow? bestOverlap,
  }) {
    if (playersState.playersState.isLoading && squad.isEmpty) {
      return const SkeletonShimmer(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              ShimmerBox(height: 120, borderRadius: 16),
              SizedBox(height: 16),
              ShimmerBox(height: 72, borderRadius: 16),
              SizedBox(height: 12),
              ShimmerBox(height: 72, borderRadius: 16),
            ],
          ),
        ),
      );
    }

    if (squad.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(playersControllerProvider.notifier).loadPlayers(),
        child: ListView(
          children: [
            OverlapPreviewCard(
              selectedDate: playersState.selectedDate,
              bestOverlap: null,
              totalPlayersCount: 0,
              onDaySelected: (date) => ref
                  .read(playersControllerProvider.notifier)
                  .setSelectedDate(date),
            ),
            const SizedBox(height: 32),
            const PlayersEmptyView(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(playersControllerProvider.notifier).loadPlayers(),
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
              playersState: playersState,
              squad: squad,
              bestOverlap: bestOverlap,
            );
          }

          return _buildSingleColumnLayout(
            context,
            ref,
            playersState: playersState,
            squad: squad,
            bestOverlap: bestOverlap,
          );
        },
      ),
    );
  }

  Widget _buildSingleColumnLayout(
    BuildContext context,
    WidgetRef ref, {
    required PlayersState playersState,
    required List<Player> squad,
    required OverlapWindow? bestOverlap,
  }) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 88.0),
      children: [
        // Live Overlap Preview Banner
        OverlapPreviewCard(
          selectedDate: playersState.selectedDate,
          bestOverlap: bestOverlap,
          totalPlayersCount: squad.length,
          onDaySelected: (date) => ref
              .read(playersControllerProvider.notifier)
              .setSelectedDate(date),
        ),

        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Squad Members',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${squad.length} registered',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // List of Player Cards
        ...squad.map((player) {
          final todaySlots = player.availability;
          final tomorrowSlots =
              playersState.tomorrowAvailability[player.id] ?? const [];

          return PlayerCard(
            player: player,
            todaySlots: todaySlots,
            tomorrowSlots: tomorrowSlots,
            onEditAvailability: () => AvailabilityEditorModal.show(
              context: context,
              player: player,
              initialDate: playersState.selectedDate,
              initialSlots: todaySlots,
            ),
            onDelete: () => _handleDeletePlayer(context, ref, player),
          );
        }),
      ],
    );
  }

  Widget _buildTwoColumnLayout(
    BuildContext context,
    WidgetRef ref, {
    required PlayersState playersState,
    required List<Player> squad,
    required OverlapWindow? bestOverlap,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Live Overlap Preview & Summary
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OverlapPreviewCard(
                  selectedDate: playersState.selectedDate,
                  bestOverlap: bestOverlap,
                  totalPlayersCount: squad.length,
                  onDaySelected: (date) => ref
                      .read(playersControllerProvider.notifier)
                      .setSelectedDate(date),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Availability Tips',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Tap any player card on the right to edit their slots.\n'
                            '• Use quick presets like "Evening 5-8" for fast scheduling.\n'
                            '• The overlap preview recalculates game times instantly.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Column: Squad Players List
        Expanded(
          flex: 6,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Squad Members',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${squad.length} registered',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ...squad.map((player) {
                final todaySlots = player.availability;
                final tomorrowSlots =
                    playersState.tomorrowAvailability[player.id] ?? const [];

                return PlayerCard(
                  player: player,
                  todaySlots: todaySlots,
                  tomorrowSlots: tomorrowSlots,
                  onEditAvailability: () => AvailabilityEditorModal.show(
                    context: context,
                    player: player,
                    initialDate: playersState.selectedDate,
                    initialSlots: todaySlots,
                  ),
                  onDelete: () => _handleDeletePlayer(context, ref, player),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleDeletePlayer(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) async {
    final deleted = await ref
        .read(playersControllerProvider.notifier)
        .removePlayer(player.id);

    if (deleted != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name} removed from squad'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref.read(playersControllerProvider.notifier).undoDelete();
            },
          ),
        ),
      );
    }
  }
}
