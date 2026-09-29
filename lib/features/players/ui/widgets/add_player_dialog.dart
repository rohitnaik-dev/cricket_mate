import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/players_controller.dart';

/// Modal dialog allowing the user to add a new player to the squad,
/// displaying format and duplication validation errors inline.
class AddPlayerDialog extends ConsumerStatefulWidget {
  const AddPlayerDialog({super.key});

  /// Displays the dialog modally.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const AddPlayerDialog(),
    );
  }

  @override
  ConsumerState<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends ConsumerState<AddPlayerDialog> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _localError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto focus the input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _textController.text.trim();
    final controller = ref.read(playersControllerProvider.notifier);

    final error = controller.validatePlayerName(name);
    if (error != null) {
      setState(() {
        _localError = error;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    final player = await controller.addPlayerValidated(name);
    if (player != null && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      setState(() {
        _isSubmitting = false;
        _localError = ref.read(playersControllerProvider).nameValidationError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.person_add_alt_1, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Add Squad Player'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the name of your cricket group member:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.words,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Player Name',
                hintText: 'e.g. Rohit, Virat, Jasprit',
                errorText: _localError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              onChanged: (_) {
                if (_localError != null) {
                  setState(() {
                    _localError = null;
                  });
                }
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Player'),
        ),
      ],
    );
  }
}
