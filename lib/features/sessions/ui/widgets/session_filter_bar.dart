import 'package:flutter/material.dart';

import '../../domain/ball_type.dart';
import '../../state/sessions_controller.dart';

/// Horizontal scrolling bar containing match filter chips and sorting popup menu.
class SessionFilterBar extends StatelessWidget {
  const SessionFilterBar({
    super.key,
    required this.selectedBallType,
    required this.selectedDuration,
    required this.minPlayers,
    required this.minScore,
    required this.sortBy,
    required this.onBallTypeSelected,
    required this.onDurationSelected,
    required this.onMinPlayersSelected,
    required this.onMinScoreSelected,
    required this.onSortBySelected,
  });

  final BallType selectedBallType;
  final Duration selectedDuration;
  final int? minPlayers;
  final double minScore;
  final SessionSortBy sortBy;

  final ValueChanged<BallType> onBallTypeSelected;
  final ValueChanged<Duration> onDurationSelected;
  final ValueChanged<int?> onMinPlayersSelected;
  final ValueChanged<double> onMinScoreSelected;
  final ValueChanged<SessionSortBy> onSortBySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Sort menu button
          PopupMenuButton<SessionSortBy>(
            initialValue: sortBy,
            tooltip: 'Sort sessions',
            onSelected: onSortBySelected,
            child: Chip(
              avatar: const Icon(Icons.sort, size: 16),
              label: Text(sortBy.label),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SessionSortBy.score,
                child: Text('Highest Score'),
              ),
              const PopupMenuItem(
                value: SessionSortBy.time,
                child: Text('Earliest Time'),
              ),
              const PopupMenuItem(
                value: SessionSortBy.attendance,
                child: Text('Most Players'),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Ball type menu
          PopupMenuButton<BallType>(
            initialValue: selectedBallType,
            tooltip: 'Filter by ball type',
            onSelected: onBallTypeSelected,
            child: FilterChip(
              avatar: const Icon(Icons.sports_baseball, size: 16),
              label: Text(selectedBallType.displayName),
              selected: true,
              onSelected: (_) {},
            ),
            itemBuilder: (context) => BallType.values.map((type) {
              return PopupMenuItem(value: type, child: Text(type.displayName));
            }).toList(),
          ),
          const SizedBox(width: 8),

          // Duration menu
          PopupMenuButton<int>(
            tooltip: 'Filter by match duration',
            onSelected: (minutes) {
              onDurationSelected(Duration(minutes: minutes));
            },
            child: FilterChip(
              avatar: const Icon(Icons.timer_outlined, size: 16),
              label: Text('${selectedDuration.inMinutes}m'),
              selected: true,
              onSelected: (_) {},
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 60, child: Text('1 hour (60m)')),
              PopupMenuItem(value: 90, child: Text('1.5 hours (90m)')),
              PopupMenuItem(value: 120, child: Text('2 hours (120m)')),
              PopupMenuItem(value: 180, child: Text('3 hours (180m)')),
            ],
          ),
          const SizedBox(width: 8),

          // Min players menu
          PopupMenuButton<int?>(
            tooltip: 'Filter by minimum squad attendance',
            onSelected: onMinPlayersSelected,
            child: FilterChip(
              avatar: const Icon(Icons.group_outlined, size: 16),
              label: Text(
                minPlayers != null ? '$minPlayers+ players' : 'Any squad',
              ),
              selected: minPlayers != null,
              onSelected: (_) {},
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text('Any squad size')),
              PopupMenuItem(value: 4, child: Text('At least 4 players')),
              PopupMenuItem(
                value: 6,
                child: Text('At least 6 players (Quorum)'),
              ),
              PopupMenuItem(value: 8, child: Text('At least 8 players')),
              PopupMenuItem(value: 11, child: Text('Full side (11+ players)')),
            ],
          ),
          const SizedBox(width: 8),

          // Min score filter
          PopupMenuButton<double>(
            tooltip: 'Filter by minimum session score',
            onSelected: onMinScoreSelected,
            child: FilterChip(
              avatar: const Icon(Icons.star_outline, size: 16),
              label: Text(
                minScore > 0 ? '${minScore.round()}+ Score' : 'All scores',
              ),
              selected: minScore > 0,
              onSelected: (_) {},
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0.0, child: Text('All scores')),
              PopupMenuItem(value: 50.0, child: Text('50+ (Fair & above)')),
              PopupMenuItem(value: 70.0, child: Text('70+ (Good & above)')),
              PopupMenuItem(value: 85.0, child: Text('85+ (Excellent only)')),
            ],
          ),
        ],
      ),
    );
  }
}
