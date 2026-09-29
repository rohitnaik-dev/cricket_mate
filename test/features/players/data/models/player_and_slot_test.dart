import 'package:cricket_mate/features/players/data/models/availability_slot.dart';
import 'package:cricket_mate/features/players/data/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testDate = DateTime(2026, 9, 30);

  group('AvailabilitySlot', () {
    test(
      'constructs successfully with valid 30-minute boundaries within day',
      () {
        final slot = AvailabilitySlot(
          start: DateTime(2026, 9, 30, 9, 0),
          end: DateTime(2026, 9, 30, 11, 30),
        );

        expect(slot.start, equals(DateTime(2026, 9, 30, 9, 0)));
        expect(slot.end, equals(DateTime(2026, 9, 30, 11, 30)));
        expect(slot.duration, equals(const Duration(hours: 2, minutes: 30)));
      },
    );

    test('fromTime factory properly handles 24:00 as midnight next day', () {
      final slot = AvailabilitySlot.fromTime(
        date: testDate,
        startHour: 20,
        startMinute: 30,
        endHour: 24,
        endMinute: 0,
      );

      expect(slot.start, equals(DateTime(2026, 9, 30, 20, 30)));
      expect(slot.end, equals(DateTime(2026, 10, 1, 0, 0)));
      expect(slot.duration, equals(const Duration(hours: 3, minutes: 30)));
    });

    test('throws ArgumentError when end is equal to start', () {
      expect(
        () => AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 0),
          end: DateTime(2026, 9, 30, 10, 0),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when end is before start', () {
      expect(
        () => AvailabilitySlot(
          start: DateTime(2026, 9, 30, 12, 0),
          end: DateTime(2026, 9, 30, 11, 0),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when minutes are not multiples of 30', () {
      expect(
        () => AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 15),
          end: DateTime(2026, 9, 30, 11, 0),
        ),
        throwsArgumentError,
      );

      expect(
        () => AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 0),
          end: DateTime(2026, 9, 30, 11, 45),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when seconds or milliseconds are non-zero', () {
      expect(
        () => AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 0, 5),
          end: DateTime(2026, 9, 30, 11, 0),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when slot spans multiple calendar days', () {
      expect(
        () => AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 0),
          end: DateTime(2026, 10, 1, 10, 0),
        ),
        throwsArgumentError,
      );
    });

    test('serializes to and from JSON map correctly', () {
      final original = AvailabilitySlot(
        start: DateTime(2026, 9, 30, 14, 0),
        end: DateTime(2026, 9, 30, 17, 30),
      );

      final json = original.toJson();
      final restored = AvailabilitySlot.fromJson(json);

      expect(restored, equals(original));
      expect(restored.start, equals(original.start));
      expect(restored.end, equals(original.end));
    });

    test('throws FormatException on malformed JSON payload', () {
      expect(
        () => AvailabilitySlot.fromJson({
          'start': 'invalid-date',
          'end': 'another-bad-date',
        }),
        throwsFormatException,
      );

      expect(
        () => AvailabilitySlot.fromJson({'start': '2026-09-30T10:00:00.000'}),
        throwsFormatException,
      );
    });

    test('converts to and from Dart 3 record seamlessly', () {
      final original = AvailabilitySlot(
        start: DateTime(2026, 9, 30, 8, 30),
        end: DateTime(2026, 9, 30, 10, 0),
      );

      final record = original.toRecord();
      expect(record.start, equals(original.start));
      expect(record.end, equals(original.end));

      final restored = AvailabilitySlot.fromRecord(record);
      expect(restored, equals(original));
    });

    test('coversInterval checks subset boundaries correctly', () {
      final slot = AvailabilitySlot(
        start: DateTime(2026, 9, 30, 10, 0),
        end: DateTime(2026, 9, 30, 13, 0),
      );

      expect(
        slot.coversInterval(
          DateTime(2026, 9, 30, 10, 0),
          DateTime(2026, 9, 30, 13, 0),
        ),
        isTrue,
      );
      expect(
        slot.coversInterval(
          DateTime(2026, 9, 30, 10, 30),
          DateTime(2026, 9, 30, 12, 30),
        ),
        isTrue,
      );
      expect(
        slot.coversInterval(
          DateTime(2026, 9, 30, 9, 30),
          DateTime(2026, 9, 30, 12, 0),
        ),
        isFalse,
      );
      expect(
        slot.coversInterval(
          DateTime(2026, 9, 30, 11, 0),
          DateTime(2026, 9, 30, 13, 30),
        ),
        isFalse,
      );
    });
  });

  group('Player', () {
    test('trims name and sets fields correctly', () {
      final player = Player(id: 'p1', name: '  Rohit Sharma   ');

      expect(player.id, equals('p1'));
      expect(player.name, equals('Rohit Sharma'));
      expect(player.availability, isEmpty);
    });

    test('throws ArgumentError on empty or whitespace-only name', () {
      expect(() => Player(id: 'p1', name: ''), throwsArgumentError);

      expect(() => Player(id: 'p1', name: '   '), throwsArgumentError);
    });

    test('throws ArgumentError on empty or whitespace-only id', () {
      expect(() => Player(id: '', name: 'Rohit'), throwsArgumentError);

      expect(() => Player(id: '   ', name: 'Rohit'), throwsArgumentError);
    });

    test(
      'throws ArgumentError when name exceeds maxNameLength (50 characters)',
      () {
        final longName = 'A' * 51;
        expect(() => Player(id: 'p1', name: longName), throwsArgumentError);

        final validName = 'A' * 50;
        final player = Player(id: 'p1', name: validName);
        expect(player.name.length, equals(50));
      },
    );

    test('serializes to and from JSON with availability', () {
      final slot = AvailabilitySlot(
        start: DateTime(2026, 9, 30, 10, 0),
        end: DateTime(2026, 9, 30, 12, 0),
      );
      final player = Player(
        id: 'p1',
        name: 'Jasprit Bumrah',
        availability: [slot],
      );

      final json = player.toJson(includeAvailability: true);
      final restored = Player.fromJson(json);

      expect(restored, equals(player));
      expect(restored.availability.length, equals(1));
      expect(restored.availability.first, equals(slot));
    });

    test('copyWith updates properties correctly', () {
      final player = Player(id: 'p1', name: 'Virat');
      final updated = player.copyWith(name: 'Virat Kohli');

      expect(updated.id, equals('p1'));
      expect(updated.name, equals('Virat Kohli'));
      expect(player.name, equals('Virat'));
    });
  });
}
