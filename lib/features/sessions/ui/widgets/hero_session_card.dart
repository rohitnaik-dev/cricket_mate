import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/reason_chip.dart';
import '../../domain/session_candidate.dart';
import 'score_ring.dart';

/// Featured Hero card spotlighting the #1 recommended cricket session,
/// with an empty-state variant when no players or viable sessions exist.
class HeroSessionCard extends StatelessWidget {
  const HeroSessionCard({
    super.key,
    required this.candidate,
    this.placeName,
    required this.totalSquadCount,
    required this.onViewSession,
    this.onAddPlayers,
  });

  /// The top ranked session candidate (null if no viable session exists).
  final SessionCandidate? candidate;

  /// Name of the cricket ground/city location.
  final String? placeName;

  /// Total number of squad members registered.
  final int totalSquadCount;

  /// Action callback when "View Session" button is tapped.
  final VoidCallback onViewSession;

  /// Action callback to navigate to the Players tab when empty.
  final VoidCallback? onAddPlayers;

  @override
  Widget build(BuildContext context) {
    if (candidate == null || totalSquadCount == 0) {
      return _buildEmptyState(context);
    }

    return _buildHeroContent(context, candidate!);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'No viable cricket session found. Add players to find a session.',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_cricket,
                size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Add players to find a session',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'CricketMate combines weather with your squad schedules to automatically spotlight the best hours to play.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (onAddPlayers != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onAddPlayers,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Add Squad Members',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, SessionCandidate session) {
    final theme = Theme.of(context);
    final window = session.window;
    final locationLabel = placeName ?? 'Selected Ground';
    final dateStr = DateFormatter.formatDayHeader(window.start);
    final timeStr = DateFormatter.formatSessionRange(window.start, window.end);
    final weather = session.weatherScores;

    final heroTag =
        'session_hero_${session.window.start.millisecondsSinceEpoch}_${session.window.end.millisecondsSinceEpoch}';

    return Semantics(
      label:
          'Best time to play cricket: $dateStr, $timeStr at $locationLabel. Score ${session.score.round()} out of 100, ${session.label}. ${window.playerCount} of $totalSquadCount players available.',
      child: Hero(
        tag: heroTag,
        child: Material(
          type: MaterialType.transparency,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge header
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.military_tech,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'BEST TIME TO PLAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$dateStr • $locationLabel',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Time and Score Ring Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeStr,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.groups,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${window.playerCount}/$totalSquadCount players available',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: ScoreRing(
                          score: session.score,
                          rating: session.rating,
                          size: 64,
                          showLabel: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Weather metrics indicators row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _WeatherMetricItem(
                          icon: Icons.thermostat,
                          label: '${weather.temperature.round()}°C',
                          caption: 'Comfort',
                        ),
                        _WeatherMetricItem(
                          icon: Icons.water_drop_outlined,
                          label: '${(100 - weather.rain).round()}%',
                          caption: 'Rain Prob',
                        ),
                        _WeatherMetricItem(
                          icon: Icons.air,
                          label: '${weather.wind.round()} pts',
                          caption: 'Wind',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reason checkmarks / chips
                  if (session.reasonChips.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: session.reasonChips.take(3).map((chip) {
                        final isPos = chip.tone == ReasonTone.positive;
                        final isNeg = chip.tone == ReasonTone.negative;
                        final icon = isPos
                            ? Icons.check_circle
                            : (isNeg ? Icons.cancel : Icons.warning_amber);
                        final color = isPos
                            ? Colors.green.shade800
                            : (isNeg
                                  ? Colors.red.shade800
                                  : Colors.amber.shade900);

                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width - 64,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: color),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  chip.message,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // View Session action button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: onViewSession,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'View Session Details',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherMetricItem extends StatelessWidget {
  const _WeatherMetricItem({
    required this.icon,
    required this.label,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          caption,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
