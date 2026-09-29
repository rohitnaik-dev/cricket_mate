import 'dart:math' as math;

/// Evaluates player turnout and attendance against a match quorum.
abstract final class AvailabilityScorer {
  /// Default quorum required to play a minimal cricket session.
  static const int defaultQuorum = 6;

  /// Calculates availability score (0.0 - 100.0).
  ///
  /// - If [attending] < [quorum]: penalized score (0.0 to 50.0).
  /// - If [attending] >= [quorum]: baseline 75.0, scaling up to 100.0 as turnout reaches [totalSquad].
  static double score({
    required int attending,
    required int totalSquad,
    int quorum = defaultQuorum,
  }) {
    if (totalSquad <= 0 || attending <= 0) {
      return 0.0;
    }

    final safeQuorum = math.max(1, quorum);
    final safeAttending = attending.clamp(0, totalSquad);

    if (safeAttending < safeQuorum) {
      // Below quorum: scaled strictly under 50.0
      return ((safeAttending / safeQuorum) * 50.0).clamp(0.0, 50.0);
    }

    if (totalSquad <= safeQuorum) {
      return 100.0;
    }

    // Quorum achieved: 75.0 baseline + scaling up to 100.0
    final extraPlayers = safeAttending - safeQuorum;
    final maxExtra = totalSquad - safeQuorum;

    final additionalPoints = (extraPlayers / maxExtra) * 25.0;
    return (75.0 + additionalPoints).clamp(75.0, 100.0);
  }
}
