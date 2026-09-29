import 'package:flutter/foundation.dart';

/// Dart 3 record representation of an availability slot.
typedef AvailabilitySlotRecord = ({DateTime start, DateTime end});

/// Immutable time slot representing player availability.
///
/// Must satisfy:
/// - [end] strictly after [start].
/// - 30-minute granularity (minute is 0 or 30; second and millisecond are 0).
/// - Within a chosen day (same calendar day, or ending at midnight next day).
@immutable
class AvailabilitySlot {
  AvailabilitySlot({required this.start, required this.end}) {
    if (!end.isAfter(start)) {
      throw ArgumentError(
        'AvailabilitySlot end ($end) must be strictly after start ($start).',
      );
    }

    if (start.minute % 30 != 0 ||
        end.minute % 30 != 0 ||
        start.second != 0 ||
        end.second != 0 ||
        start.millisecond != 0 ||
        end.millisecond != 0) {
      throw ArgumentError(
        'AvailabilitySlot start and end must have 30-minute granularity '
        '(minutes must be :00 or :30, seconds and milliseconds must be 0).',
      );
    }

    final isSameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final isMidnightNextDay =
        end == DateTime(start.year, start.month, start.day + 1);

    if (!isSameDay && !isMidnightNextDay) {
      throw ArgumentError(
        'AvailabilitySlot must be within a single chosen day ($start to $end).',
      );
    }
  }

  /// Convenience factory creating an [AvailabilitySlot] from hours/minutes on a [date].
  ///
  /// Set [endHour] to 24 with [endMinute] 0 to represent midnight of the next day.
  factory AvailabilitySlot.fromTime({
    required DateTime date,
    required int startHour,
    int startMinute = 0,
    required int endHour,
    int endMinute = 0,
  }) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      startHour,
      startMinute,
    );
    final end = endHour == 24 && endMinute == 0
        ? DateTime(date.year, date.month, date.day + 1)
        : DateTime(date.year, date.month, date.day, endHour, endMinute);
    return AvailabilitySlot(start: start, end: end);
  }

  /// Constructs an [AvailabilitySlot] from a Dart 3 record.
  factory AvailabilitySlot.fromRecord(AvailabilitySlotRecord record) {
    return AvailabilitySlot(start: record.start, end: record.end);
  }

  /// Deserializes an [AvailabilitySlot] from JSON.
  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    final rawStart = json['start'] as String?;
    final rawEnd = json['end'] as String?;

    if (rawStart == null || rawEnd == null) {
      throw const FormatException(
        'Missing required start or end timestamp in AvailabilitySlot JSON',
      );
    }

    final parsedStart = DateTime.tryParse(rawStart);
    final parsedEnd = DateTime.tryParse(rawEnd);

    if (parsedStart == null || parsedEnd == null) {
      throw const FormatException(
        'Malformed ISO-8601 timestamp in AvailabilitySlot JSON',
      );
    }

    return AvailabilitySlot(start: parsedStart, end: parsedEnd);
  }

  /// Start timestamp of the availability slot.
  final DateTime start;

  /// End timestamp of the availability slot.
  final DateTime end;

  /// Converts this slot to a Dart 3 record.
  AvailabilitySlotRecord toRecord() => (start: start, end: end);

  /// Duration of the slot.
  Duration get duration => end.difference(start);

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  /// Returns true if this slot entirely covers the given [intervalStart] to [intervalEnd].
  bool coversInterval(DateTime intervalStart, DateTime intervalEnd) {
    return (start.isBefore(intervalStart) ||
            start.isAtSameMomentAs(intervalStart)) &&
        (end.isAfter(intervalEnd) || end.isAtSameMomentAs(intervalEnd));
  }

  /// Creates a copy with optional parameter overrides.
  AvailabilitySlot copyWith({DateTime? start, DateTime? end}) {
    return AvailabilitySlot(start: start ?? this.start, end: end ?? this.end);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AvailabilitySlot &&
        other.start.isAtSameMomentAs(start) && 
        other.end.isAtSameMomentAs(end);
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'AvailabilitySlot(start: $start, end: $end)';
}
