import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/view_state.dart';
import '../../settings/state/settings_controller.dart';
import '../repository/player_repository.dart';

/// Combined state for the players feature, tracking squad members,
/// today's & tomorrow's availability, and inline validation errors.
@immutable
class PlayersState {
  const PlayersState({
    required this.selectedDate,
    this.playersState = const ViewState.empty(),
    this.tomorrowAvailability = const <String, List<AvailabilitySlot>>{},
    this.nameValidationError,
  });

  /// The date for which player availability is currently queried (Today or Tomorrow).
  final DateTime selectedDate;

  /// ViewState containing the squad members with their availability for [selectedDate].
  final ViewState<List<Player>> playersState;

  /// Map of player ID to availability slots for tomorrow.
  final Map<String, List<AvailabilitySlot>> tomorrowAvailability;

  /// Inline validation error message when adding a player, if any.
  final String? nameValidationError;

  /// Convenience getter extracting the list of players if loaded, or empty list.
  List<Player> get players => playersState.dataOrNull ?? const <Player>[];

  /// Creates a copy with optional property overrides.
  PlayersState copyWith({
    DateTime? selectedDate,
    ViewState<List<Player>>? playersState,
    Map<String, List<AvailabilitySlot>>? tomorrowAvailability,
    String? nameValidationError,
    bool clearNameValidationError = false,
  }) {
    return PlayersState(
      selectedDate: selectedDate ?? this.selectedDate,
      playersState: playersState ?? this.playersState,
      tomorrowAvailability: tomorrowAvailability ?? this.tomorrowAvailability,
      nameValidationError: clearNameValidationError
          ? null
          : (nameValidationError ?? this.nameValidationError),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayersState &&
        other.selectedDate == selectedDate &&
        other.playersState == playersState &&
        mapEquals(other.tomorrowAvailability, tomorrowAvailability) &&
        other.nameValidationError == nameValidationError;
  }

  @override
  int get hashCode => Object.hash(
    selectedDate,
    playersState,
    Object.hashAll(tomorrowAvailability.entries),
    nameValidationError,
  );
}

/// Controller managing squad members, adding/removing players with validation,
/// delete undo, and availability scheduling for today and tomorrow.
class PlayersController extends StateNotifier<PlayersState> {
  PlayersController(this._playerRepository, {DateTime? initialDate})
    : super(PlayersState(selectedDate: initialDate ?? DateTime.now())) {
    loadPlayers();
  }

  final PlayerRepository _playerRepository;

  Player? _lastDeletedPlayer;
  Map<DateTime, List<AvailabilitySlot>>? _lastDeletedAvailability;

  /// Loads all players with availability for [date] as well as tomorrow.
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

      final tomorrowDate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day + 1,
      );
      final tomorrowMap = <String, List<AvailabilitySlot>>{};
      for (final p in players) {
        try {
          final slots = await _playerRepository.getAvailability(
            p.id,
            tomorrowDate,
          );
          tomorrowMap[p.id] = slots;
        } catch (_) {
          tomorrowMap[p.id] = const [];
        }
      }

      if (players.isEmpty) {
        state = state.copyWith(
          playersState: const ViewState.empty('No squad members added yet.'),
          tomorrowAvailability: const {},
        );
      } else {
        state = state.copyWith(
          playersState: ViewState.success(players),
          tomorrowAvailability: tomorrowMap,
        );
      }
    } on AppException catch (e) {
      state = state.copyWith(playersState: ViewState.failure(e));
    } catch (e) {
      state = state.copyWith(
        playersState: ViewState.failure(ApiClient.mapError(e)),
      );
    }
  }

  /// Validates a prospective player name inline against format and duplication rules.
  String? validatePlayerName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Player name cannot be empty.';
    }
    if (trimmed.length > Player.maxNameLength) {
      return 'Player name cannot exceed ${Player.maxNameLength} characters.';
    }
    final isDuplicate = state.players.any(
      (p) => p.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (isDuplicate) {
      return 'A player named "$trimmed" already exists in the squad.';
    }
    return null;
  }

  /// Adds a player after validating name. Sets inline error if invalid.
  Future<Player?> addPlayerValidated(String name) async {
    final error = validatePlayerName(name);
    if (error != null) {
      state = state.copyWith(nameValidationError: error);
      return null;
    }

    state = state.copyWith(clearNameValidationError: true);
    final player = await addPlayer(name.trim());
    return player;
  }

  /// Clears active inline validation error.
  void clearValidationError() {
    if (state.nameValidationError != null) {
      state = state.copyWith(clearNameValidationError: true);
    }
  }

  /// Adds a new player to the squad directly.
  Future<Player> addPlayer(String name, {String? id}) async {
    final playerId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final player = Player(id: playerId, name: name);
    await _playerRepository.addPlayer(player);
    await loadPlayers();
    return player;
  }

  /// Removes a player by [id], stores their availability in the undo cache,
  /// and returns the removed [Player] instance.
  Future<Player?> removePlayer(String id) async {
    final player = state.players.cast<Player?>().firstWhere(
      (p) => p?.id == id,
      orElse: () => null,
    );
    if (player != null) {
      final targetDate = state.selectedDate;
      final today = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final tomorrow = today.add(const Duration(days: 1));

      final todaySlots = player.availability;
      final tomorrowSlots =
          state.tomorrowAvailability[id] ?? <AvailabilitySlot>[];

      _lastDeletedPlayer = player;
      _lastDeletedAvailability = {today: todaySlots, tomorrow: tomorrowSlots};
    }

    await _playerRepository.deletePlayer(id);
    await loadPlayers();
    return player;
  }

  /// Undoes the last player deletion, restoring their data and availability slots.
  Future<void> undoDelete() async {
    final player = _lastDeletedPlayer;
    if (player == null) return;

    final availability = _lastDeletedAvailability;
    _lastDeletedPlayer = null;
    _lastDeletedAvailability = null;

    await _playerRepository.addPlayer(player);
    if (availability != null) {
      for (final entry in availability.entries) {
        if (entry.value.isNotEmpty) {
          await _playerRepository.setAvailability(
            player.id,
            entry.key,
            entry.value,
          );
        }
      }
    }
    await loadPlayers();
  }

  /// Sets availability slots for [playerId] on [date] and refreshes the view.
  Future<void> setAvailability(
    String playerId,
    DateTime date,
    List<AvailabilitySlot> slots,
  ) async {
    await _playerRepository.setAvailability(playerId, date, slots);
    await loadPlayers(date: date);
  }

  /// Updates the target planning date (Today or Tomorrow) and refreshes availability.
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

/// Live overlap windows provider computed using [findOverlaps].
final playerOverlapsProvider = Provider<List<OverlapWindow>>((ref) {
  final playersState = ref.watch(playersControllerProvider);
  final players = playersState.players;
  if (players.isEmpty) return const <OverlapWindow>[];

  final settings = ref.watch(settingsControllerProvider);
  final duration = settings.sessionDuration;

  return findOverlaps(
    players,
    playersState.selectedDate,
    duration,
    minPlayers: 1,
  );
});

/// Top overlapping window for the selected day, if any.
final bestOverlapWindowProvider = Provider<OverlapWindow?>((ref) {
  final overlaps = ref.watch(playerOverlapsProvider);
  if (overlaps.isEmpty) return null;

  final sorted = List<OverlapWindow>.from(overlaps)
    ..sort((a, b) {
      final countCmp = b.playerCount.compareTo(a.playerCount);
      if (countCmp != 0) return countCmp;
      return a.start.compareTo(b.start);
    });

  return sorted.first;
});
