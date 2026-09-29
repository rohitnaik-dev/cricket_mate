import 'package:flutter/material.dart';

import '../../../players/data/models/player.dart';
import '../../domain/session_candidate.dart';

/// Squad attendance breakdown displaying confirmed available players
/// alongside missing/unavailable registered squad members.
class PlayersAttendanceSection extends StatelessWidget {
  const PlayersAttendanceSection({
    super.key,
    required this.candidate,
    required this.allSquadPlayers,
  });

  final SessionCandidate candidate;
  final List<Player> allSquadPlayers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = candidate.window.players;
    final availableIds = available.map((Player p) => p.id).toSet();
    final missing = allSquadPlayers
        .where((Player p) => !availableIds.contains(p.id))
        .toList();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Squad Attendance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          available.length == allSquadPlayers.length &&
                              allSquadPlayers.isNotEmpty
                          ? Colors.green.shade700
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        allSquadPlayers.isEmpty
                            ? '${available.length} available'
                            : '${available.length}/${allSquadPlayers.length} available',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              available.length == allSquadPlayers.length &&
                                  allSquadPlayers.isNotEmpty
                              ? Colors.white
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Confirmed Available Players
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Confirmed Available (${available.length})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (available.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  'No players confirmed for this window.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: available.map((Player player) {
                  return _PlayerChip(player: player, isAvailable: true);
                }).toList(),
              ),

            // Missing / Unavailable Players
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Unavailable / Missing (${missing.length})',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: missing.map((Player player) {
                  return _PlayerChip(player: player, isAvailable: false);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.player, required this.isAvailable});

  final Player player;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = player.name.trim().isNotEmpty
        ? player.name.trim().characters.first.toUpperCase()
        : '?';

    final bg = isAvailable
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final fg = isAvailable
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
              ? Colors.green.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: isAvailable
                ? Colors.green.shade700
                : theme.colorScheme.outline,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
