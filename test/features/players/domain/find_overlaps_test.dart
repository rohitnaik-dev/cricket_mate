import 'package:cricket_mate/features/players/data/models/availability_slot.dart';
import 'package:cricket_mate/features/players/data/models/player.dart';
import 'package:cricket_mate/features/players/domain/find_overlaps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 9, 30);

  group('findOverlaps', () {
    test(
      'full overlap: all players available for the entire window are included',
      () {
        final p1 = Player(
          id: '1',
          name: 'Rohit',
          availability: [
            AvailabilitySlot(
              start: DateTime(2026, 9, 30, 10, 0),
              end: DateTime(2026, 9, 30, 13, 0),
            ),
          ],
        );
        final p2 = Player(
          id: '2',
          name: 'Virat',
          availability: [
            AvailabilitySlot(
              start: DateTime(2026, 9, 30, 10, 0),
              end: DateTime(2026, 9, 30, 13, 0),
            ),
          ],
        );

        final windows = findOverlaps([p1, p2], day, const Duration(hours: 2));

        // Windows expected: 10:00-12:00, 10:30-12:30, 11:00-13:00
        expect(windows.length, equals(3));
        for (final window in windows) {
          expect(window.playerCount, equals(2));
          expect(
            window.players.map((p) => p.name),
            containsAll(['Rohit', 'Virat']),
          );
        }

        expect(windows.first.start, equals(DateTime(2026, 9, 30, 10, 0)));
        expect(windows.first.end, equals(DateTime(2026, 9, 30, 12, 0)));
        expect(windows.last.start, equals(DateTime(2026, 9, 30, 11, 0)));
        expect(windows.last.end, equals(DateTime(2026, 9, 30, 13, 0)));
      },
    );

    test('partial overlap: only players available for the entire window are counted', () {
      // p1 is free 10:00 to 12:00
      final p1 = Player(
        id: '1',
        name: 'Rohit',
        availability: [
          AvailabilitySlot(
            start: DateTime(2026, 9, 30, 10, 0),
            end: DateTime(2026, 9, 30, 12, 0),
          ),
        ],
      );

      // p2 is free 11:00 to 13:00
      final p2 = Player(
        id: '2',
        name: 'Virat',
        availability: [
          AvailabilitySlot(
            start: DateTime(2026, 9, 30, 11, 0),
            end: DateTime(2026, 9, 30, 13, 0),
          ),
        ],
      );

      // Desired 1-hour session duration
      final windows = findOverlaps([p1, p2], day, const Duration(hours: 1));

      // 10:00 - 11:00: only Rohit (p1)
      final w1000 = windows.firstWhere(
        (w) => w.start == DateTime(2026, 9, 30, 10, 0),
      );
      expect(w1000.players, equals([p1]));

      // 10:30 - 11:30: only Rohit (Virat starts at 11:00, not free for entire window)
      final w1030 = windows.firstWhere(
        (w) => w.start == DateTime(2026, 9, 30, 10, 30),
      );
      expect(w1030.players, equals([p1]));

      // 11:00 - 12:00: both Rohit & Virat are free for the ENTIRE 1-hour window!
      final w1100 = windows.firstWhere(
        (w) => w.start == DateTime(2026, 9, 30, 11, 0),
      );
      expect(w1100.playerCount, equals(2));
      expect(w1100.players, containsAll([p1, p2]));

      // 11:30 - 12:30: only Virat (Rohit leaves at 12:00)
      final w1130 = windows.firstWhere(
        (w) => w.start == DateTime(2026, 9, 30, 11, 30),
      );
      expect(w1130.players, equals([p2]));

      // 12:00 - 13:00: only Virat
      final w1200 = windows.firstWhere(
        (w) => w.start == DateTime(2026, 9, 30, 12, 0),
      );
      expect(w1200.players, equals([p2]));
    });

    test(
      'no availability: returns empty candidate list when squad has no slots',
      () {
        final p1 = Player(id: '1', name: 'Rohit');
        final p2 = Player(id: '2', name: 'Virat');

        final windows = findOverlaps([p1, p2], day, const Duration(hours: 2));
        expect(windows, isEmpty);

        // When minPlayers is 0, sweeping windows are returned but each has 0 players
        final allWindows = findOverlaps(
          [p1, p2],
          day,
          const Duration(hours: 2),
          minPlayers: 0,
        );
        expect(allWindows, isNotEmpty);
        expect(allWindows.every((w) => w.players.isEmpty), isTrue);
      },
    );

    test(
      'a single player: identifies valid windows for a solo squad member',
      () {
        final solo = Player(
          id: '1',
          name: 'Jasprit',
          availability: [
            AvailabilitySlot(
              start: DateTime(2026, 9, 30, 16, 0),
              end: DateTime(2026, 9, 30, 18, 0),
            ),
          ],
        );

        final windows = findOverlaps([solo], day, const Duration(hours: 1));

        expect(windows.length, equals(3));
        expect(windows[0].start, equals(DateTime(2026, 9, 30, 16, 0)));
        expect(windows[0].end, equals(DateTime(2026, 9, 30, 17, 0)));
        expect(windows[1].start, equals(DateTime(2026, 9, 30, 16, 30)));
        expect(windows[1].end, equals(DateTime(2026, 9, 30, 17, 30)));
        expect(windows[2].start, equals(DateTime(2026, 9, 30, 17, 0)));
        expect(windows[2].end, equals(DateTime(2026, 9, 30, 18, 0)));

        for (final window in windows) {
          expect(window.players, equals([solo]));
        }
      },
    );

    test('boundary times: handles 00:00 midnight start, 24:00 end, and exact slot matches', () {
      final nightOwl = Player(
        id: '1',
        name: 'Ashwin',
        availability: [
          // Earliest possible slot: 00:00 to 01:00
          AvailabilitySlot(
            start: DateTime(2026, 9, 30, 0, 0),
            end: DateTime(2026, 9, 30, 1, 0),
          ),
          // Latest possible slot: 22:30 to 24:00 (midnight next day)
          AvailabilitySlot(
            start: DateTime(2026, 9, 30, 22, 30),
            end: DateTime(2026, 10, 1, 0, 0),
          ),
        ],
      );

      final windows = findOverlaps([nightOwl], day, const Duration(hours: 1));

      // Window at 00:00
      expect(
        windows.any(
          (w) =>
              w.start == DateTime(2026, 9, 30, 0, 0) &&
              w.end == DateTime(2026, 9, 30, 1, 0),
        ),
        isTrue,
      );

      // Latest window ending at 24:00 (2026-10-01 00:00)
      expect(
        windows.any(
          (w) =>
              w.start == DateTime(2026, 9, 30, 23, 0) &&
              w.end == DateTime(2026, 10, 1, 0, 0),
        ),
        isTrue,
      );

      // Ensure no window spills over beyond midnight next day
      for (final window in windows) {
        expect(
          window.end.isBefore(DateTime(2026, 10, 1, 0, 0)) ||
              window.end.isAtSameMomentAs(DateTime(2026, 10, 1, 0, 0)),
          isTrue,
        );
      }
    });

    test('contiguous slots: multiple consecutive slots for a player cover a long window', () {
      final player = Player(
        id: '1',
        name: 'KL Rahul',
        availability: [
          AvailabilitySlot(
            start: DateTime(2026, 9, 30, 14, 0),
            end: DateTime(2026, 9, 30, 15, 0),
          ),
          AvailabilitySlot(
            start: DateTime(2026, 9, 30, 15, 0),
            end: DateTime(2026, 9, 30, 16, 30),
          ),
        ],
      );

      // 2.5-hour duration from 14:00 to 16:30 is completely covered by contiguous slots
      final windows = findOverlaps(
        [player],
        day,
        const Duration(hours: 2, minutes: 30),
      );

      expect(windows.length, equals(1));
      expect(windows.first.start, equals(DateTime(2026, 9, 30, 14, 0)));
      expect(windows.first.end, equals(DateTime(2026, 9, 30, 16, 30)));
      expect(windows.first.players, equals([player]));
    });

    test('duplicates: throws ArgumentError when duplicate player names are provided', () {
      final p1 = Player(id: '1', name: 'Shubman Gill');
      final p2 = Player(
        id: '2',
        name: 'shubman gill ',
      ); // Case and trim insensitive duplicate

      expect(
        () => findOverlaps([p1, p2], day, const Duration(hours: 1)),
        throwsArgumentError,
      );
    });

    test('validates duration strictly positive and <= 24 hours', () {
      final player = Player(id: '1', name: 'Rohit');

      expect(
        () => findOverlaps([player], day, Duration.zero),
        throwsArgumentError,
      );

      expect(
        () => findOverlaps([player], day, const Duration(minutes: -30)),
        throwsArgumentError,
      );

      expect(
        () => findOverlaps([player], day, const Duration(hours: 25)),
        throwsArgumentError,
      );
    });
  });
}
