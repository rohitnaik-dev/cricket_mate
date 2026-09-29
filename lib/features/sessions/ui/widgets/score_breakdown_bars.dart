import 'package:flutter/material.dart';

import '../../domain/reason_chip.dart';
import '../../domain/session_candidate.dart';

/// "Why this time?" breakdown section displaying labeled score progress bars,
/// composite metric sub-scores, veto warnings, and ReasonChips.
class ScoreBreakdownBars extends StatelessWidget {
  const ScoreBreakdownBars({super.key, required this.candidate});

  final SessionCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Icon(
                  Icons.analytics_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Why this time?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Weather breakdown bar (60% weight)
            _BreakdownItem(
              title: 'Weather & Comfort',
              weight: '60% weight',
              score: candidate.weatherScores.total,
              icon: Icons.wb_sunny_outlined,
              color: _scoreColor(candidate.weatherScores.total),
              details:
                  'Rain: ${candidate.weatherScores.rain.round()} • Temp: ${candidate.weatherScores.temperature.round()} • Wind: ${candidate.weatherScores.wind.round()} • Humidity: ${candidate.weatherScores.humidity.round()} • UV: ${candidate.weatherScores.uv.round()}',
            ),
            const SizedBox(height: 12),

            // 2. Attendance breakdown bar (30% weight)
            _BreakdownItem(
              title: 'Squad Attendance',
              weight: '30% weight',
              score: candidate.availabilityScore,
              icon: Icons.groups_outlined,
              color: _scoreColor(candidate.availabilityScore),
              details:
                  '${candidate.window.playerCount} player${candidate.window.playerCount == 1 ? "" : "s"} confirmed available',
            ),
            const SizedBox(height: 12),

            // 3. Ground & Conditions breakdown bar (10% weight)
            _BreakdownItem(
              title: 'Ground & Daylight Conditions',
              weight: '10% weight',
              score: candidate.conditionsScores.total,
              icon: Icons.grass_outlined,
              color: _scoreColor(candidate.conditionsScores.total),
              details:
                  'Outfield: ${candidate.conditionsScores.wetOutfield.round()} • Dew: ${candidate.conditionsScores.dewRisk.round()} • Daylight: ${candidate.conditionsScores.daylight.round()}',
            ),
            const SizedBox(height: 16),

            // Hard Veto Warnings (if any)
            if (candidate.hasVeto) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Session Viability Veto Triggered',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...candidate.vetoReasons.map(
                      (reason) => Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          '• $reason',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ReasonChips
            if (candidate.reasonChips.isNotEmpty) ...[
              Text(
                'Key Factors',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: candidate.reasonChips.map((chip) {
                  final (chipBg, chipFg, icon) = switch (chip.tone) {
                    ReasonTone.positive => (
                      Colors.green.withValues(alpha: 0.15),
                      Colors.green.shade800,
                      Icons.check_circle_outline,
                    ),
                    ReasonTone.warning => (
                      Colors.amber.withValues(alpha: 0.2),
                      Colors.amber.shade900,
                      Icons.warning_amber_rounded,
                    ),
                    ReasonTone.negative => (
                      Colors.red.withValues(alpha: 0.15),
                      Colors.red.shade800,
                      Icons.error_outline,
                    ),
                    ReasonTone.neutral => (
                      theme.colorScheme.surfaceContainerHighest,
                      theme.colorScheme.onSurfaceVariant,
                      Icons.info_outline,
                    ),
                  };

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: chipFg),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            chip.message,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: chipFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 85.0) return const Color(0xFF2E7D32);
    if (score >= 70.0) return const Color(0xFF689F38);
    if (score >= 50.0) return const Color(0xFFFBC02D);
    if (score >= 30.0) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.title,
    required this.weight,
    required this.score,
    required this.icon,
    required this.color,
    required this.details,
  });

  final String title;
  final String weight;
  final double score;
  final IconData icon;
  final Color color;
  final String details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = (score / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              flex: 3,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.round()}/100',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($weight)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          details,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
