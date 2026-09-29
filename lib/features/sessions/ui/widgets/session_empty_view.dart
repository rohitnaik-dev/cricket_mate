import 'package:flutter/material.dart';

/// Reusable empty or error state view displaying an illustrative icon,
/// clear messaging, and an optional call-to-action button.
class SessionEmptyView extends StatelessWidget {
  const SessionEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  /// Primary icon representing the state.
  final IconData icon;

  /// Main title text.
  final String title;

  /// Explanatory message.
  final String? message;

  /// Optional label for the call-to-action button.
  final String? actionLabel;

  /// Callback when action button is pressed.
  final VoidCallback? onAction;

  /// Whether this view indicates an error state.
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = isError
        ? theme.colorScheme.error
        : theme.colorScheme.primary.withValues(alpha: 0.7);

    return Semantics(
      label: '$title. ${message ?? ''}',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color:
                      (isError
                              ? theme.colorScheme.errorContainer
                              : theme.colorScheme.primaryContainer)
                          .withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: Icon(
                    isError ? Icons.refresh : Icons.arrow_forward,
                    size: 18,
                  ),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
