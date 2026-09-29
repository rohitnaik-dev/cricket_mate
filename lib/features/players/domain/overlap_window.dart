import 'package:flutter/foundation.dart';

import '../data/models/player.dart';

/// Dart 3 record representation of an overlap window.
typedef OverlapWindowRecord = ({
  DateTime start,
  DateTime end,
  List<Player> players,
});

/// Immutable candidate playing window containing the list of players
/// who are available for the entire duration of the window.
@immutable
class OverlapWindow {
  OverlapWindow({
    required this.start,
    required this.end,
    required List<Player> players,
  }) : players = List<Player>.unmodifiable(players) {
    if (!end.isAfter(start)) {
      throw ArgumentError(
        'OverlapWindow end ($end) must be strictly after start ($start).',
      );
    }
  }

  /// Start timestamp of this candidate window.
  final DateTime start;

  /// End timestamp of this candidate window.
  final DateTime end;

  /// List of players who are available for the entire window duration.
  final List<Player> players;

  /// Number of players available for the entire window.
  int get playerCount => players.length;

  /// Duration of this candidate window.
  Duration get duration => end.difference(start);

  /// Converts this window into a Dart 3 record.
  OverlapWindowRecord toRecord() => (start: start, end: end, players: players);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OverlapWindow &&
        other.start.isAtSameMomentAs(start) &&
        other.end.isAtSameMomentAs(end) &&
        listEquals(other.players, players);
  }

  @override
  int get hashCode => Object.hash(start, end, Object.hashAll(players));

  @override
  String toString() =>
      'OverlapWindow(start: $start, end: $end, players: ${players.map((p) => p.name).toList()})';
}

/// Convenience alias for [OverlapWindow].
typedef CandidateWindow = OverlapWindow;
