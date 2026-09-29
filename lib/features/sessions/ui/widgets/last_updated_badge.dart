import 'package:flutter/material.dart';

/// Formats relative time elapsed, e.g. "just now", "5m ago", "2h ago", "1d ago".
String formatTimeAgo(DateTime? dateTime) {
  if (dateTime == null) return 'just now';
  final diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// Visual status badge showing freshness and cache state.
class LastUpdatedBadge extends StatelessWidget {
  const LastUpdatedBadge({
    super.key,
    required this.updatedAt,
    required this.fromCache,
    this.onRefresh,
  });

  /// Timestamp when data was retrieved or cached.
  final DateTime? updatedAt;

  /// Whether data was loaded from persistent offline storage.
  final bool fromCache;

  /// Optional refresh action callback.
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = formatTimeAgo(updatedAt);

    if (fromCache) {
      return Semantics(
        label: 'Showing offline cached weather data, updated $timeStr',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade400),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 16, color: Colors.amber.shade900),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Offline • Updated $timeStr',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onRefresh,
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: 'Weather forecast updated $timeStr',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Updated $timeStr',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
