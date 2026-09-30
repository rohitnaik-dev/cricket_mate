import 'package:cricket_mate/features/players/repository/player_repository.dart';
import 'package:cricket_mate/features/players/state/players_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

void main() {
  late MockPlayerRepository mockRepo;
  late PlayersController controller;

  final testDate = DateTime(2026, 9, 30);
  final player1 = Player(id: 'p1', name: 'Rohit');
  final player2 = Player(id: 'p2', name: 'Virat');

  setUpAll(() {
    registerFallbackValue(player1);
    registerFallbackValue(testDate);
    registerFallbackValue(<AvailabilitySlot>[]);
  });

  setUp(() {
    mockRepo = MockPlayerRepository();
    when(() => mockRepo.getPlayersWithAvailability(any()))
        .thenAnswer((_) async => <Player>[]);
  });

  group('PlayersController', () {
    test('initial load produces ViewEmpty when repository is empty', () async {
      controller = PlayersController(mockRepo, initialDate: testDate);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.playersState.isEmpty, isTrue);
      expect(controller.state.players, isEmpty);
    });

    test('loadPlayers produces ViewSuccess when players exist', () async {
      when(() => mockRepo.getPlayersWithAvailability(any()))
          .thenAnswer((_) async => [player1, player2]);

      controller = PlayersController(mockRepo, initialDate: testDate);
      await controller.loadPlayers();

      expect(controller.state.playersState.isSuccess, isTrue);
      expect(controller.state.players.length, equals(2));
    });

    test('addPlayer persists via repository and reloads squad', () async {
      when(() => mockRepo.addPlayer(any())).thenAnswer((_) async {});
      when(() => mockRepo.getPlayersWithAvailability(any()))
          .thenAnswer((_) async => [player1]);

      controller = PlayersController(mockRepo, initialDate: testDate);
      await controller.addPlayer('Rohit');

      verify(() => mockRepo.addPlayer(any())).called(1);
      expect(controller.state.players.length, equals(1));
    });

    test('removePlayer deletes via repository and reloads squad', () async {
      when(() => mockRepo.deletePlayer('p1')).thenAnswer((_) async {});
      when(() => mockRepo.getPlayersWithAvailability(any()))
          .thenAnswer((_) async => <Player>[]);

      controller = PlayersController(mockRepo, initialDate: testDate);
      await controller.removePlayer('p1');

      verify(() => mockRepo.deletePlayer('p1')).called(1);
      expect(controller.state.players, isEmpty);
    });

    test('setAvailability updates repository and reloads with slots', () async {
      final slot = AvailabilitySlot(
        start: DateTime(2026, 9, 30, 10, 0),
        end: DateTime(2026, 9, 30, 12, 0),
      );

      when(() => mockRepo.setAvailability('p1', testDate, [slot]))
          .thenAnswer((_) async {});
      when(() => mockRepo.getPlayersWithAvailability(testDate)).thenAnswer(
        (_) async => [
          player1.copyWith(availability: [slot]),
        ],
      );

      controller = PlayersController(mockRepo, initialDate: testDate);
      await controller.setAvailability('p1', testDate, [slot]);

      verify(() => mockRepo.setAvailability('p1', testDate, [slot])).called(1);
      expect(controller.state.players.first.availability.length, equals(1));
    });

    test('setAvailability for tomorrow updates tomorrowAvailability without changing selectedDate', () async {
      final tomorrowDate = testDate.add(const Duration(days: 1));
      final slotTomorrow = AvailabilitySlot(
        start: DateTime(2026, 10, 1, 17, 0),
        end: DateTime(2026, 10, 1, 20, 0),
      );

      when(() => mockRepo.setAvailability('p1', tomorrowDate, [slotTomorrow]))
          .thenAnswer((_) async {});
      when(() => mockRepo.getPlayersWithAvailability(testDate))
          .thenAnswer((_) async => [player1]);
      when(() => mockRepo.getAvailability('p1', tomorrowDate))
          .thenAnswer((_) async => [slotTomorrow]);

      controller = PlayersController(mockRepo, initialDate: testDate);
      await controller.setAvailability('p1', tomorrowDate, [slotTomorrow]);

      verify(() => mockRepo.setAvailability('p1', tomorrowDate, [slotTomorrow]))
          .called(1);
      expect(controller.state.selectedDate, equals(testDate));
      expect(controller.state.todayAvailability['p1'], isEmpty);
      expect(controller.state.tomorrowAvailability['p1']?.length, equals(1));
      expect(
        controller.state.tomorrowAvailability['p1']?.first.start.hour,
        equals(17),
      );
    });
  });
}
