import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/reason_chip.dart';
import '../../domain/session_candidate.dart';
import 'score_ring.dart';

/// Modal bottom sheet presenting a comprehensive breakdown of weather, conditions, and players for a session.
class SessionDetailModal extends StatelessWidget {
  const SessionDetailModal({super.key, required this.candidate});

  final SessionCandidate candidate;

  static Future<void> show(BuildContext context, SessionCandidate candidate) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SessionDetailModal(candidate: candidate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final window = candidate.window;
    final wScores = candidate.weatherScores;
    final cScores = candidate.conditionsScores;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Score Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormatter.formatSessionRange(
                            window.start,
                            window.end,
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.formatDayHeader(window.start),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScoreRing(
                    score: candidate.score,
                    rating: candidate.rating,
                    size: 58,
                    showLabel: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Reason chips
              if (candidate.reasonChips.isNotEmpty) ...[
                Text(
                  'Factors & Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidate.reasonChips.map((chip) {
                    final isPos = chip.tone == ReasonTone.positive;
                    final isNeg = chip.tone == ReasonTone.negative;
                    final bgColor = isPos
                        ? Colors.green.shade50
                        : (isNeg ? Colors.red.shade50 : Colors.amber.shade50);
                    final fgColor = isPos
                        ? Colors.green.shade900
                        : (isNeg ? Colors.red.shade900 : Colors.amber.shade900);
                    final icon = isPos
                        ? Icons.check_circle
                        : (isNeg ? Icons.cancel : Icons.warning_amber_rounded);

                    return Chip(
                      avatar: Icon(icon, size: 16, color: fgColor),
                      label: Text(chip.message),
                      backgroundColor: bgColor,
                      labelStyle: TextStyle(
                        color: fgColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Weather Sub-scores
              Text(
                'Weather Analysis (60%)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _MetricBar(
                        label: 'Rain Hazard (40%)',
                        score: wScores.rain,
                      ),
                      _MetricBar(
                        label: 'Comfort Temp (25%)',
                        score: wScores.temperature,
                      ),
                      _MetricBar(
                        label: 'Wind Speed (15%)',
                        score: wScores.wind,
                      ),
                      _MetricBar(
                        label: 'Humidity (10%)',
                        score: wScores.humidity,
                      ),
                      _MetricBar(label: 'UV Safety (10%)', score: wScores.uv),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ground Conditions
              Text(
                'Ground & Daylight (10%)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _MetricBar(
                        label:
                            'Dry Outfield (Past Rain: ${cScores.past24hPrecipitationMm.toStringAsFixed(1)}mm)',
                        score: cScores.wetOutfield,
                      ),
                      _MetricBar(
                        label: 'Dew Resilience',
                        score: cScores.dewRisk,
                      ),
                      _MetricBar(
                        label:
                            'Daylight Coverage (${(cScores.daylightFraction * 100).round()}%)',
                        score: cScores.daylight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Player Attendance
              Text(
                'Confirmed Squad (${window.playerCount} Available)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: window.players.map((p) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        p.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    label: Text(p.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.label, required this.score});

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = (score / 100.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, style: theme.textTheme.bodySmall)),
              Text(
                '${score.round()}/100',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: normalized,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              score >= 70
                  ? Colors.green
                  : (score >= 40 ? Colors.amber : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
