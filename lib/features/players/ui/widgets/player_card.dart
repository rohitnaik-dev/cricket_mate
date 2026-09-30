import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../data/models/availability_slot.dart';
import '../../data/models/player.dart';

/// Card item presenting an individual squad member with their today and tomorrow availability chips,
/// and edit / delete quick actions.
class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.player,
    required this.todaySlots,
    required this.tomorrowSlots,
    required this.onEditAvailability,
    required this.onDelete,
  });

  /// Player domain model.
  final Player player;

  /// Player's available slots for Today.
  final List<AvailabilitySlot> todaySlots;

  /// Player's available slots for Tomorrow.
  final List<AvailabilitySlot> tomorrowSlots;

  /// Callback when user taps to open the availability editor.
  final VoidCallback onEditAvailability;

  /// Callback when user taps the delete button.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';

    return Semantics(
      label:
          'Player ${player.name}. Today ${todaySlots.length} slots, Tomorrow ${tomorrowSlots.length} slots.',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEditAvailability,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar, Name, and Actions
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        player.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                      tooltip: 'Edit availability for ${player.name}',
                      onPressed: onEditAvailability,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error.withValues(alpha: 0.8),
                      ),
                      tooltip: 'Remove ${player.name}',
                      onPressed: onDelete,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Availability Time-range Chips (Today & Tomorrow)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Today's availability chips
                    ..._buildDayChips(
                      context,
                      prefix: 'Today',
                      slots: todaySlots,
                      isToday: true,
                    ),
                    // Tomorrow's availability chips
                    ..._buildDayChips(
                      context,
                      prefix: 'Tmrw',
                      slots: tomorrowSlots,
                      isToday: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDayChips(
    BuildContext context, {
    required String prefix,
    required List<AvailabilitySlot> slots,
    required bool isToday,
  }) {
    final theme = Theme.of(context);

    if (slots.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$prefix: No slots',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ];
    }

    return slots.map((slot) {
      final range = DateFormatter.formatSessionRange(slot.start, slot.end);
      final bgColor = isToday
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : theme.colorScheme.secondaryContainer.withValues(alpha: 0.5);
      final fgColor = isToday
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onSecondaryContainer;

      return Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width - 64).clamp(180.0, 300.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 12, color: fgColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$prefix: $range',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
