import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/overlap_window.dart';

/// Banner card spotlighting the live best match window computed via [findOverlaps],
/// alongside day toggle selector (Today vs Tomorrow).
class OverlapPreviewCard extends StatelessWidget {
  const OverlapPreviewCard({
    super.key,
    required this.selectedDate,
    required this.bestOverlap,
    required this.totalPlayersCount,
    required this.onDaySelected,
  });

  /// The active planning date (Today or Tomorrow).
  final DateTime selectedDate;

  /// Top overlapping candidate window, if any.
  final OverlapWindow? bestOverlap;

  /// Total count of squad players registered.
  final int totalPlayersCount;

  /// Callback when user toggles between Today and Tomorrow.
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final isTodaySelected =
        selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final formattedRange = bestOverlap != null
        ? DateFormatter.formatSessionRange(bestOverlap!.start, bestOverlap!.end)
        : null;

    final semanticsLabel = bestOverlap != null
        ? 'Live overlap preview: $formattedRange with ${bestOverlap!.playerCount} of $totalPlayersCount players available.'
        : 'Live overlap preview: No common game window found for ${isTodaySelected ? "today" : "tomorrow"}.';

    return Semantics(
      label: semanticsLabel,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                theme.colorScheme.surface,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and Day selector
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE SQUAD OVERLAP',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    segments: const [
                      ButtonSegment<bool>(value: true, label: Text('Today')),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Tomorrow'),
                      ),
                    ],
                    selected: {isTodaySelected},
                    onSelectionChanged: (set) {
                      final selectToday = set.first;
                      onDaySelected(selectToday ? today : tomorrow);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Overlap status content
              if (totalPlayersCount == 0) ...[
                Text(
                  'No players added yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add squad members below to calculate group match availability.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else if (bestOverlap != null) ...[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      formattedRange!,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bestOverlap!.playerCount == totalPlayersCount
                            ? Colors.green.shade700
                            : theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.groups,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${bestOverlap!.playerCount}/$totalPlayersCount players',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  bestOverlap!.playerCount == totalPlayersCount
                      ? 'Full squad is available for this match window!'
                      : '${bestOverlap!.playerCount} players confirmed available for this window.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                Text(
                  'No overlapping time window',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'None of the players have matching hours for ${isTodaySelected ? "today" : "tomorrow"}. Tap on players below to update availability.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
