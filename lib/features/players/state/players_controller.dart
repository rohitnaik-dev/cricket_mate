import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/view_state.dart';
import '../repository/player_repository.dart';

/// Combined state for the players feature, tracking the selected date and squad availability.
@immutable
class PlayersState {
  const PlayersState({
    required this.selectedDate,
    this.playersState = const ViewState.empty(),
  });

  /// The date for which player availability is currently queried.
  final DateTime selectedDate;

  /// ViewState containing the squad members with their availability for [selectedDate].
  final ViewState<List<Player>> playersState;

  /// Convenience getter extracting the list of players if loaded, or empty list.
  List<Player> get players => playersState.dataOrNull ?? const <Player>[];

  /// Creates a copy with optional property overrides.
  PlayersState copyWith({
    DateTime? selectedDate,
    ViewState<List<Player>>? playersState,
  }) {
    return PlayersState(
      selectedDate: selectedDate ?? this.selectedDate,
      playersState: playersState ?? this.playersState,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayersState &&
        other.selectedDate == selectedDate &&
        other.playersState == playersState;
  }

  @override
  int get hashCode => Object.hash(selectedDate, playersState);
}

/// Controller managing squad members, adding/removing players, and recording availability per date.
class PlayersController extends StateNotifier<PlayersState> {
  PlayersController(this._playerRepository, {DateTime? initialDate})
    : super(PlayersState(selectedDate: initialDate ?? DateTime.now())) {
    loadPlayers();
  }

  final PlayerRepository _playerRepository;

  /// Loads all players with their availability populated for [date] (defaults to current [selectedDate]).
  Future<void> loadPlayers({DateTime? date}) async {
    final targetDate = date ?? state.selectedDate;
    state = state.copyWith(
      selectedDate: targetDate,
      playersState: const ViewState.loading(),
    );

    try {
      final players = await _playerRepository.getPlayersWithAvailability(
        targetDate,
      );
      if (players.isEmpty) {
        state = state.copyWith(
          playersState: const ViewState.empty('No squad members added yet.'),
        );
      } else {
        state = state.copyWith(playersState: ViewState.success(players));
      }
    } on AppException catch (e) {
      state = state.copyWith(playersState: ViewState.failure(e));
    } catch (e) {
      state = state.copyWith(
        playersState: ViewState.failure(ApiClient.mapError(e)),
      );
    }
  }

  /// Adds a new player to the squad and reloads the current squad view.
  Future<Player> addPlayer(String name, {String? id}) async {
    final playerId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final player = Player(id: playerId, name: name);
    await _playerRepository.addPlayer(player);
    await loadPlayers();
    return player;
  }

  /// Removes a player by [id] and reloads the current squad view.
  Future<void> removePlayer(String id) async {
    await _playerRepository.deletePlayer(id);
    await loadPlayers();
  }

  /// Sets availability slots for [playerId] on [date] and refreshes the current view.
  Future<void> setAvailability(
    String playerId,
    DateTime date,
    List<AvailabilitySlot> slots,
  ) async {
    await _playerRepository.setAvailability(playerId, date, slots);
    await loadPlayers(date: date);
  }

  /// Updates the target planning date and fetches availability for that day.
  Future<void> setSelectedDate(DateTime date) async {
    await loadPlayers(date: date);
  }
}

/// Riverpod provider for [PlayersController].
final playersControllerProvider =
    StateNotifierProvider<PlayersController, PlayersState>((ref) {
      final repo = ref.watch(playerRepositoryProvider);
      return PlayersController(repo);
    });

/// Convenience provider extracting only the squad players list.
final squadPlayersProvider = Provider<List<Player>>((ref) {
  return ref.watch(playersControllerProvider).players;
});
