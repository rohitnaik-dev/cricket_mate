import 'package:cricket_mate/features/players/repository/player_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late PlayerRepository repository;

  final testDate = DateTime(2026, 9, 30);
  final otherDate = DateTime(2026, 10, 1);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = PlayerRepositoryImpl(prefs);
  });

  group('PlayerRepository', () {
    test(
      'starts EMPTY: getPlayers and getAvailability return empty lists',
      () async {
        final players = await repository.getPlayers();
        expect(players, isEmpty);

        final availability = await repository.getAvailability(
          'unknown_id',
          testDate,
        );
        expect(availability, isEmpty);
      },
    );

    test('addPlayer saves player and persists to SharedPreferences', () async {
      final player = Player(id: 'p1', name: 'Rohit Sharma');
      await repository.addPlayer(player);

      final players = await repository.getPlayers();
      expect(players.length, equals(1));
      expect(players.first.id, equals('p1'));
      expect(players.first.name, equals('Rohit Sharma'));

      // Verify persistent across reloaded repository instance
      final newRepo = PlayerRepositoryImpl(prefs);
      final reloaded = await newRepo.getPlayers();
      expect(reloaded.length, equals(1));
      expect(reloaded.first.name, equals('Rohit Sharma'));
    });

    test(
      'addPlayer rejects duplicate player names (case & trim insensitive)',
      () async {
        await repository.addPlayer(Player(id: 'p1', name: 'Virat Kohli'));

        expect(
          () => repository.addPlayer(Player(id: 'p2', name: 'virat kohli')),
          throwsArgumentError,
        );

        expect(
          () => repository.addPlayer(Player(id: 'p3', name: '  Virat Kohli  ')),
          throwsArgumentError,
        );
      },
    );

    test('addPlayer rejects duplicate player IDs', () async {
      await repository.addPlayer(Player(id: 'p1', name: 'Rohit Sharma'));

      expect(
        () => repository.addPlayer(Player(id: 'p1', name: 'Hardik Pandya')),
        throwsArgumentError,
      );
    });

    test(
      'updatePlayer modifies player name and preserves unique constraints',
      () async {
        await repository.addPlayer(Player(id: 'p1', name: 'Surya'));
        await repository.addPlayer(Player(id: 'p2', name: 'Rishabh'));

        await repository.updatePlayer(
          Player(id: 'p1', name: 'Suryakumar Yadav'),
        );

        final players = await repository.getPlayers();
        expect(
          players.firstWhere((p) => p.id == 'p1').name,
          equals('Suryakumar Yadav'),
        );

        // Attempting to update p2 to match p1's name should throw
        expect(
          () => repository.updatePlayer(
            Player(id: 'p2', name: 'Suryakumar Yadav'),
          ),
          throwsArgumentError,
        );

        // Updating a non-existent player should throw
        expect(
          () => repository.updatePlayer(
            Player(id: 'non_existent', name: 'Ghost'),
          ),
          throwsArgumentError,
        );
      },
    );

    test('deletePlayer removes player and cleans up list', () async {
      await repository.addPlayer(Player(id: 'p1', name: 'Rohit'));
      await repository.addPlayer(Player(id: 'p2', name: 'Virat'));

      await repository.deletePlayer('p1');

      final players = await repository.getPlayers();
      expect(players.length, equals(1));
      expect(players.first.id, equals('p2'));
    });

    test(
      'setAvailability and getAvailability persists per-date slots',
      () async {
        final player = Player(id: 'p1', name: 'Bumrah');
        await repository.addPlayer(player);

        final slot1 = AvailabilitySlot(
          start: DateTime(2026, 9, 30, 9, 0),
          end: DateTime(2026, 9, 30, 11, 0),
        );
        final slot2 = AvailabilitySlot(
          start: DateTime(2026, 9, 30, 14, 0),
          end: DateTime(2026, 9, 30, 16, 0),
        );

        await repository.setAvailability('p1', testDate, [slot1, slot2]);

        final retrieved = await repository.getAvailability('p1', testDate);
        expect(retrieved.length, equals(2));
        expect(retrieved[0], equals(slot1));
        expect(retrieved[1], equals(slot2));

        // Different date returns empty
        final otherDateSlots = await repository.getAvailability(
          'p1',
          otherDate,
        );
        expect(otherDateSlots, isEmpty);
      },
    );

    test('setAvailability throws when player not found or slots do not match target date', () async {
      final slot = AvailabilitySlot(
        start: DateTime(2026, 9, 30, 10, 0),
        end: DateTime(2026, 9, 30, 12, 0),
      );

      // Player doesn't exist
      expect(
        () => repository.setAvailability('ghost_id', testDate, [slot]),
        throwsArgumentError,
      );

      await repository.addPlayer(Player(id: 'p1', name: 'Shami'));

      // Slot date (2026-09-30) does not match target date (2026-10-01)
      expect(
        () => repository.setAvailability('p1', otherDate, [slot]),
        throwsArgumentError,
      );
    });

    test(
      'getPlayersWithAvailability populates availability for requested date',
      () async {
        await repository.addPlayer(Player(id: 'p1', name: 'Rohit'));
        await repository.addPlayer(Player(id: 'p2', name: 'Virat'));

        final rohitSlot = AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 0),
          end: DateTime(2026, 9, 30, 12, 0),
        );
        await repository.setAvailability('p1', testDate, [rohitSlot]);

        // When fetched for testDate
        final playersForTestDate = await repository.getPlayersWithAvailability(
          testDate,
        );
        expect(playersForTestDate.length, equals(2));

        final rohitWithSlots = playersForTestDate.firstWhere(
          (p) => p.id == 'p1',
        );
        expect(rohitWithSlots.availability.length, equals(1));
        expect(rohitWithSlots.availability.first, equals(rohitSlot));

        final viratNoSlots = playersForTestDate.firstWhere((p) => p.id == 'p2');
        expect(viratNoSlots.availability, isEmpty);

        // When fetched for another date
        final playersForOtherDate = await repository.getPlayersWithAvailability(
          otherDate,
        );
        expect(
          playersForOtherDate.every((p) => p.availability.isEmpty),
          isTrue,
        );
      },
    );

    test('recovers safely from corrupted raw JSON in storage', () async {
      await prefs.setString(
        PlayerRepositoryImpl.playersStorageKey,
        'not-valid-json',
      );
      final players = await repository.getPlayers();
      expect(players, isEmpty);

      await prefs.setString(
        'cricket_mate_availability_2026-09-30',
        'invalid-map',
      );
      final slots = await repository.getAvailability('p1', testDate);
      expect(slots, isEmpty);
    });

    test('clearAll wipes all players and availability data', () async {
      await repository.addPlayer(Player(id: 'p1', name: 'Rohit'));
      await repository.setAvailability('p1', testDate, [
        AvailabilitySlot(
          start: DateTime(2026, 9, 30, 10, 0),
          end: DateTime(2026, 9, 30, 12, 0),
        ),
      ]);

      await repository.clearAll();

      expect(await repository.getPlayers(), isEmpty);
      expect(await repository.getAvailability('p1', testDate), isEmpty);
    });
  });
}
