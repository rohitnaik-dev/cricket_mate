import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/session_candidate.dart';
import 'score_ring.dart';

/// Card widget displaying secondary ranked candidate playing windows (#2, #3, etc.).
class CandidateSessionCard extends StatelessWidget {
  const CandidateSessionCard({
    super.key,
    required this.candidate,
    required this.rank,
    required this.totalSquadCount,
    required this.onTap,
  });

  /// The candidate playing window data.
  final SessionCandidate candidate;

  /// Rank index (1-based, e.g. 2, 3, 4).
  final int rank;

  /// Total registered squad members.
  final int totalSquadCount;

  /// Callback when user taps to inspect details.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final window = candidate.window;
    final timeStr = DateFormatter.formatSessionRange(window.start, window.end);
    final weather = candidate.weatherScores;

    return Semantics(
      label:
          'Rank #$rank session: $timeStr. Score ${candidate.score.round()}, ${candidate.label}. ${window.playerCount} of $totalSquadCount players available.',
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Rank number badge
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Window details & weather snapshot
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeStr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${window.playerCount}/$totalSquadCount players',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.thermostat_outlined,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${weather.temperature.round()}°C',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Score ring
                ScoreRing(
                  score: candidate.score,
                  rating: candidate.rating,
                  size: 46,
                  strokeWidth: 4.5,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
