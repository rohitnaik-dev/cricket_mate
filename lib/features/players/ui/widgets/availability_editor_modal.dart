import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../data/models/availability_slot.dart';
import '../../data/models/player.dart';
import '../../state/players_controller.dart';

/// Modal bottom sheet allowing users to edit player availability for Today and Tomorrow,
/// featuring quick tap-to-select presets and a 30-minute step time range picker.
class AvailabilityEditorModal extends ConsumerStatefulWidget {
  const AvailabilityEditorModal({
    super.key,
    required this.player,
    required this.initialDate,
    this.initialSlots = const [],
    this.todaySlots = const [],
    this.tomorrowSlots = const [],
  });

  /// Player being edited.
  final Player player;

  /// Default date opened (Today or Tomorrow).
  final DateTime initialDate;

  /// Existing slots for the player on [initialDate].
  final List<AvailabilitySlot> initialSlots;

  /// Existing slots for Today.
  final List<AvailabilitySlot> todaySlots;

  /// Existing slots for Tomorrow.
  final List<AvailabilitySlot> tomorrowSlots;

  /// Static helper to display this modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required Player player,
    required DateTime initialDate,
    List<AvailabilitySlot>? initialSlots,
    List<AvailabilitySlot>? todaySlots,
    List<AvailabilitySlot>? tomorrowSlots,
  }) {
    final resolvedToday = todaySlots ?? initialSlots ?? player.availability;
    final resolvedTomorrow = tomorrowSlots ?? const <AvailabilitySlot>[];

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AvailabilityEditorModal(
        player: player,
        initialDate: initialDate,
        initialSlots: initialSlots ?? resolvedToday,
        todaySlots: resolvedToday,
        tomorrowSlots: resolvedTomorrow,
      ),
    );
  }

  @override
  ConsumerState<AvailabilityEditorModal> createState() =>
      _AvailabilityEditorModalState();
}

class _AvailabilityEditorModalState
    extends ConsumerState<AvailabilityEditorModal> {
  late DateTime _selectedDay;
  late DateTime _today;
  late DateTime _tomorrow;

  late List<AvailabilitySlot> _todaySlots;
  late List<AvailabilitySlot> _tomorrowSlots;
  late List<AvailabilitySlot> _currentSlots;

  // Range picker state (defaults to 17:00 - 20:00 "Evening")
  int _startHour = 17;
  int _startMinute = 0;
  int _endHour = 20;
  int _endMinute = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _tomorrow = _today.add(const Duration(days: 1));

    _todaySlots = List<AvailabilitySlot>.from(widget.todaySlots);
    _tomorrowSlots = List<AvailabilitySlot>.from(widget.tomorrowSlots);

    final isInitialTomorrow =
        widget.initialDate.year == _tomorrow.year &&
        widget.initialDate.month == _tomorrow.month &&
        widget.initialDate.day == _tomorrow.day;

    _selectedDay = isInitialTomorrow ? _tomorrow : _today;
    _currentSlots = List<AvailabilitySlot>.from(
      isInitialTomorrow ? _tomorrowSlots : _todaySlots,
    );
  }

  void _switchDay(DateTime newDay) {
    if (_selectedDay == newDay) return;

    final isLeavingToday =
        _selectedDay.year == _today.year &&
        _selectedDay.month == _today.month &&
        _selectedDay.day == _today.day;

    // Buffer the current day's working changes before switching
    if (isLeavingToday) {
      _todaySlots = List<AvailabilitySlot>.from(_currentSlots);
    } else {
      _tomorrowSlots = List<AvailabilitySlot>.from(_currentSlots);
    }

    setState(() {
      _selectedDay = newDay;
      final isNewDayToday =
          newDay.year == _today.year &&
          newDay.month == _today.month &&
          newDay.day == _today.day;

      _currentSlots = List<AvailabilitySlot>.from(
        isNewDayToday ? _todaySlots : _tomorrowSlots,
      );
    });
  }

  void _applyPreset({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) {
    setState(() {
      _startHour = startHour;
      _startMinute = startMinute;
      _endHour = endHour;
      _endMinute = endMinute;
    });

    _addCurrentSlot();
  }

  void _addCurrentSlot() {
    final slot = AvailabilitySlot.fromTime(
      date: _selectedDay,
      startHour: _startHour,
      startMinute: _startMinute,
      endHour: _endHour,
      endMinute: _endMinute,
    );

    // Prevent identical duplicate slots
    final alreadyExists = _currentSlots.any((s) => s == slot);
    if (!alreadyExists) {
      setState(() {
        _currentSlots.add(slot);
        _currentSlots.sort((a, b) => a.start.compareTo(b.start));
      });
    }
  }

  void _removeSlot(int index) {
    setState(() {
      _currentSlots.removeAt(index);
    });
  }

  Future<void> _saveAndClose() async {
    final isToday =
        _selectedDay.year == _today.year &&
        _selectedDay.month == _today.month &&
        _selectedDay.day == _today.day;

    if (isToday) {
      _todaySlots = List<AvailabilitySlot>.from(_currentSlots);
    } else {
      _tomorrowSlots = List<AvailabilitySlot>.from(_currentSlots);
    }

    final notifier = ref.read(playersControllerProvider.notifier);
    await notifier.setAvailability(
      widget.player.id,
      _selectedDay,
      _currentSlots,
    );

    final otherDay = isToday ? _tomorrow : _today;
    final otherSlots = isToday ? _tomorrowSlots : _todaySlots;
    final originalOtherSlots = isToday
        ? widget.tomorrowSlots
        : widget.todaySlots;
    if (!listEquals(otherSlots, originalOtherSlots)) {
      await notifier.setAvailability(widget.player.id, otherDay, otherSlots);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final isToday =
        _selectedDay.year == today.year &&
        _selectedDay.month == today.month &&
        _selectedDay.day == today.day;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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

              // Title and Player Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Availability',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.player.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Day Selector: Today vs Tomorrow
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Today'),
                    icon: Icon(Icons.today, size: 16),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Tomorrow'),
                    icon: Icon(Icons.event_outlined, size: 16),
                  ),
                ],
                selected: {isToday},
                onSelectionChanged: (set) {
                  _switchDay(set.first ? today : tomorrow);
                },
              ),
              const SizedBox(height: 20),

              // Quick Presets Section
              Text(
                'Quick Presets (Tap to Add)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PresetChip(
                    label: 'Evening 5-8',
                    icon: Icons.nightlight_outlined,
                    onTap: () => _applyPreset(
                      startHour: 17,
                      startMinute: 0,
                      endHour: 20,
                      endMinute: 0,
                    ),
                  ),
                  _PresetChip(
                    label: 'Weekend morning',
                    icon: Icons.wb_sunny_outlined,
                    onTap: () => _applyPreset(
                      startHour: 8,
                      startMinute: 0,
                      endHour: 11,
                      endMinute: 0,
                    ),
                  ),
                  _PresetChip(
                    label: 'Morning 7-10',
                    icon: Icons.alarm,
                    onTap: () => _applyPreset(
                      startHour: 7,
                      startMinute: 0,
                      endHour: 10,
                      endMinute: 0,
                    ),
                  ),
                  _PresetChip(
                    label: 'Afternoon 2-5',
                    icon: Icons.sunny,
                    onTap: () => _applyPreset(
                      startHour: 14,
                      startMinute: 0,
                      endHour: 17,
                      endMinute: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Range Picker Section (30-minute steps)
              Text(
                'Custom Range Picker (30-min steps)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeDropdown(
                              label: 'Start Time',
                              hour: _startHour,
                              minute: _startMinute,
                              isStartTime: true,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.arrow_forward, size: 16),
                          ),
                          Expanded(
                            child: _buildTimeDropdown(
                              label: 'End Time',
                              hour: _endHour,
                              minute: _endMinute,
                              isStartTime: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addCurrentSlot,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Time Range'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Active Slots for this Day
              Text(
                'Scheduled Slots (${_currentSlots.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_currentSlots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No availability recorded for this day yet. Tap a quick preset or add a custom range above.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currentSlots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slot = entry.value;
                    final rangeStr = DateFormatter.formatSessionRange(
                      slot.start,
                      slot.end,
                    );

                    return InputChip(
                      avatar: const Icon(Icons.access_time, size: 16),
                      label: Text(rangeStr),
                      onDeleted: () => _removeSlot(index),
                      deleteIcon: const Icon(Icons.cancel, size: 16),
                      deleteButtonTooltipMessage: 'Remove this slot',
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Save CTA
              FilledButton.icon(
                onPressed: _saveAndClose,
                icon: const Icon(Icons.check, size: 18),
                label: Text(
                  'Save Availability for ${isToday ? "Today" : "Tomorrow"}',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeDropdown({
    required String label,
    required int hour,
    required int minute,
    required bool isStartTime,
  }) {
    final theme = Theme.of(context);
    final times = _generate30MinSlots(isStartTime: isStartTime);

    final currentValue = _timeToMinutes(hour, minute);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: times.any((t) => t.totalMinutes == currentValue)
              ? currentValue
              : times.first.totalMinutes,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: times.map((t) {
            return DropdownMenuItem<int>(
              value: t.totalMinutes,
              child: Text(t.label, style: theme.textTheme.bodyMedium),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              final h = val ~/ 60;
              final m = val % 60;
              if (isStartTime) {
                _startHour = h;
                _startMinute = m;
                // Ensure end time is strictly after start time
                if (_timeToMinutes(_endHour, _endMinute) <= val) {
                  final nextVal = (val + 60).clamp(0, 24 * 60);
                  _endHour = nextVal ~/ 60;
                  _endMinute = nextVal % 60;
                }
              } else {
                _endHour = h;
                _endMinute = m;
                // Ensure start time is strictly before end time
                if (_timeToMinutes(_startHour, _startMinute) >= val) {
                  final prevVal = (val - 60).clamp(0, 24 * 60);
                  _startHour = prevVal ~/ 60;
                  _startMinute = prevVal % 60;
                }
              }
            });
          },
        ),
      ],
    );
  }

  int _timeToMinutes(int hour, int minute) => (hour * 60) + minute;

  List<({int totalMinutes, String label})> _generate30MinSlots({
    required bool isStartTime,
  }) {
    final slots = <({int totalMinutes, String label})>[];
    final maxHour = isStartTime ? 23 : 24;

    for (var h = 6; h <= maxHour; h++) {
      for (final m in [0, 30]) {
        if (h == 24 && m == 30) continue;
        final total = (h * 60) + m;
        final label = _formatSlotTime(h, m);
        slots.add((totalMinutes: total, label: label));
      }
    }
    return slots;
  }

  String _formatSlotTime(int hour, int minute) {
    if (hour == 24 && minute == 0) return 'Midnight (12:00 AM)';
    final dt = DateTime(2026, 1, 1, hour, minute);
    return DateFormatter.formatTime(dt);
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.3,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
