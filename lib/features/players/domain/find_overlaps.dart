import '../data/models/player.dart';
import 'overlap_window.dart';

/// Checks whether a [player] has continuous availability covering the ENTIRE window
/// from [windowStart] to [windowEnd].
///
/// Handles single slots, multiple overlapping slots, and contiguous slots seamlessly.
bool isPlayerAvailableForWindow(
  Player player,
  DateTime windowStart,
  DateTime windowEnd,
) {
  if (player.availability.isEmpty) return false;

  // Filter slots that intersect or touch the requested window
  final relevantSlots = player.availability
      .where(
        (slot) =>
            slot.end.isAfter(windowStart) && slot.start.isBefore(windowEnd),
      )
      .toList();

  if (relevantSlots.isEmpty) return false;

  // Sort slots chronologically
  relevantSlots.sort((a, b) => a.start.compareTo(b.start));

  // Merge contiguous and overlapping slots
  final merged = <({DateTime start, DateTime end})>[];
  for (final slot in relevantSlots) {
    if (merged.isEmpty) {
      merged.add((start: slot.start, end: slot.end));
    } else {
      final last = merged.last;
      if (slot.start.isBefore(last.end) ||
          slot.start.isAtSameMomentAs(last.end)) {
        if (slot.end.isAfter(last.end)) {
          merged[merged.length - 1] = (start: last.start, end: slot.end);
        }
      } else {
        merged.add((start: slot.start, end: slot.end));
      }
    }
  }

  // Verify if any merged interval fully spans [windowStart, windowEnd]
  for (final interval in merged) {
    final coversStart =
        interval.start.isBefore(windowStart) ||
        interval.start.isAtSameMomentAs(windowStart);
    final coversEnd =
        interval.end.isAfter(windowEnd) ||
        interval.end.isAtSameMomentAs(windowEnd);

    if (coversStart && coversEnd) {
      return true;
    }
  }

  return false;
}

/// Pure function to find all candidate playing windows on a given [day] for a desired [duration].
///
/// Sweeps across the day in 30-minute intervals. A player is included in a candidate window
/// only if they are available for the **entire** window duration.
///
/// Parameters:
/// - [players]: Squad members to evaluate. Throws [ArgumentError] if duplicate names exist.
/// - [day]: Target date for the match.
/// - [duration]: Desired session length (e.g. 1 hour, 90 minutes, 2 hours). Must be positive.
/// - [minPlayers]: Minimum available players required to return a window (defaults to 1).
///   Set to 0 if all sweeping windows should be returned regardless of player availability.
/// - [startBound]: Optional custom start boundary time for the sweep (defaults to 00:00 of [day]).
/// - [endBound]: Optional custom end boundary time for the sweep (defaults to 24:00 of [day]).
List<OverlapWindow> findOverlaps(
  List<Player> players,
  DateTime day,
  Duration duration, {
  int minPlayers = 1,
  DateTime? startBound,
  DateTime? endBound,
}) {
  if (duration <= Duration.zero) {
    throw ArgumentError(
      'Session duration must be strictly positive (was $duration).',
    );
  }

  if (duration > const Duration(days: 1)) {
    throw ArgumentError(
      'Session duration cannot exceed 24 hours (was $duration).',
    );
  }

  // Validate no duplicate player names (case-insensitive)
  final seenNames = <String>{};
  for (final player in players) {
    final normalized = player.name.trim().toLowerCase();
    if (!seenNames.add(normalized)) {
      throw ArgumentError(
        'Duplicate player name found in squad list: "${player.name}".',
      );
    }
  }

  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = DateTime(day.year, day.month, day.day + 1);

  final sweepStart = startBound ?? dayStart;
  final sweepEnd = endBound ?? dayEnd;

  final candidateWindows = <OverlapWindow>[];
  var currentStart = sweepStart;

  while (currentStart.add(duration).isBefore(sweepEnd) ||
      currentStart.add(duration).isAtSameMomentAs(sweepEnd)) {
    final windowStart = currentStart;
    final windowEnd = currentStart.add(duration);

    final availablePlayers = <Player>[];
    for (final player in players) {
      if (isPlayerAvailableForWindow(player, windowStart, windowEnd)) {
        availablePlayers.add(player);
      }
    }

    if (availablePlayers.length >= minPlayers) {
      candidateWindows.add(
        OverlapWindow(
          start: windowStart,
          end: windowEnd,
          players: availablePlayers,
        ),
      );
    }

    currentStart = currentStart.add(const Duration(minutes: 30));
  }

  return candidateWindows;
}
