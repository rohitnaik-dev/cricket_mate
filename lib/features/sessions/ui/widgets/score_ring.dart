import 'package:flutter/material.dart';

import '../../domain/session_candidate.dart';

/// Circular progress ring displaying numeric score and color-coded recommendation tier.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    required this.rating,
    this.size = 64.0,
    this.strokeWidth = 6.0,
    this.showLabel = false,
  });

  /// Numeric score (0.0 - 100.0).
  final double score;

  /// Categorical recommendation tier.
  final SessionRating rating;

  /// Diameter of the ring.
  final double size;

  /// Stroke width of the circular progress indicator.
  final double strokeWidth;

  /// Whether to show the rating label under the score.
  final bool showLabel;

  Color _scoreColor(BuildContext context) {
    if (score >= 85.0) return const Color(0xFF2E7D32); // Dark Green
    if (score >= 70.0) return const Color(0xFF689F38); // Lime Green
    if (score >= 50.0) return const Color(0xFFFBC02D); // Gold / Amber
    if (score >= 30.0) return const Color(0xFFE65100); // Orange
    return const Color(0xFFC62828); // Red
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context);
    final normalized = (score / 100.0).clamp(0.0, 1.0);

    return Semantics(
      label:
          'Session rating score: ${score.round()} out of 100, ${rating.label}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: normalized,
                  strokeWidth: strokeWidth,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  score.round().toString(),
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rating.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
