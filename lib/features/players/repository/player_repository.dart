import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_formatter.dart';
import '../../weather/data/cache_store.dart';
import '../data/models/availability_slot.dart';
import '../data/models/player.dart';

export '../data/models/availability_slot.dart';
export '../data/models/player.dart';
export '../domain/find_overlaps.dart';
export '../domain/overlap_window.dart';

/// Abstract contract for squad players and their availability.
///
/// Starts completely EMPTY. Persists changes to local storage.
abstract interface class PlayerRepository {
  /// Fetches all registered squad players. Starts empty.
  Future<List<Player>> getPlayers();

  /// Adds a new [player] to the squad.
  ///
  /// Throws [ArgumentError] if:
  /// - A player with the same ID already exists.
  /// - A player with the same name (case-insensitive) already exists.
  Future<void> addPlayer(Player player);

  /// Updates an existing [player] in the squad.
  ///
  /// Throws [ArgumentError] if:
  /// - The player is not found.
  /// - Another player with the same name already exists.
  Future<void> updatePlayer(Player player);

  /// Removes a player by [id] and cleans up their availability entries.
  Future<void> deletePlayer(String id);

  /// Retrieves availability slots for [playerId] on [date].
  Future<List<AvailabilitySlot>> getAvailability(
    String playerId,
    DateTime date,
  );

  /// Persists availability slots for [playerId] on [date].
  Future<void> setAvailability(
    String playerId,
    DateTime date,
    List<AvailabilitySlot> slots,
  );

  /// Fetches all players with their [Player.availability] populated for [date].
  Future<List<Player>> getPlayersWithAvailability(DateTime date);

  /// Clears all players and availability data (useful for test resets).
  Future<void> clearAll();
}

/// SharedPreferences-backed implementation of [PlayerRepository].
class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String playersStorageKey = 'cricket_mate_players';
  static const String availabilityPrefix = 'cricket_mate_availability_';

  static String _dateKey(DateTime date) {
    return '$availabilityPrefix${DateFormatter.toIsoDateOnly(date)}';
  }

  @override
  Future<List<Player>> getPlayers() async {
    final raw = _prefs.getString(playersStorageKey);
    if (raw == null || raw.isEmpty) return <Player>[];

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <Player>[];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Player.fromJson)
          .toList();
    } catch (_) {
      return <Player>[];
    }
  }

  @override
  Future<void> addPlayer(Player player) async {
    final existing = await getPlayers();

    final normalizedNewName = player.name.trim().toLowerCase();

    // Check duplicate name
    if (existing.any((p) => p.name.trim().toLowerCase() == normalizedNewName)) {
      throw ArgumentError(
        'A player with the name "${player.name}" already exists.',
      );
    }

    // Check duplicate ID
    if (existing.any((p) => p.id == player.id)) {
      throw ArgumentError('A player with ID "${player.id}" already exists.');
    }

    final updated = [...existing, player];
    await _savePlayersList(updated);

    // If initial availability was provided, persist it for their date(s)
    if (player.availability.isNotEmpty) {
      final slotsByDate = <String, List<AvailabilitySlot>>{};
      for (final slot in player.availability) {
        final dKey = DateFormatter.toIsoDateOnly(slot.start);
        slotsByDate.putIfAbsent(dKey, () => <AvailabilitySlot>[]).add(slot);
      }
      for (final entry in slotsByDate.entries) {
        final date = DateTime.parse(entry.key);
        await setAvailability(player.id, date, entry.value);
      }
    }
  }

  @override
  Future<void> updatePlayer(Player player) async {
    final existing = await getPlayers();
    final index = existing.indexWhere((p) => p.id == player.id);

    if (index == -1) {
      throw ArgumentError('Player with ID "${player.id}" not found.');
    }

    final normalizedNewName = player.name.trim().toLowerCase();

    // Ensure no other player has the same name
    if (existing.any(
      (p) =>
          p.id != player.id && p.name.trim().toLowerCase() == normalizedNewName,
    )) {
      throw ArgumentError(
        'Another player with the name "${player.name}" already exists.',
      );
    }

    final updated = [...existing];
    updated[index] = player;
    await _savePlayersList(updated);
  }

  @override
  Future<void> deletePlayer(String id) async {
    final existing = await getPlayers();
    final updated = existing.where((p) => p.id != id).toList();
    await _savePlayersList(updated);
  }

  @override
  Future<List<AvailabilitySlot>> getAvailability(
    String playerId,
    DateTime date,
  ) async {
    final key = _dateKey(date);
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return <AvailabilitySlot>[];

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return <AvailabilitySlot>[];

      final dynamic playerSlotsRaw = decoded[playerId];
      if (playerSlotsRaw is! List) return <AvailabilitySlot>[];

      return playerSlotsRaw
          .whereType<Map<String, dynamic>>()
          .map(AvailabilitySlot.fromJson)
          .toList();
    } catch (_) {
      return <AvailabilitySlot>[];
    }
  }

  @override
  Future<void> setAvailability(
    String playerId,
    DateTime date,
    List<AvailabilitySlot> slots,
  ) async {
    final players = await getPlayers();
    if (!players.any((p) => p.id == playerId)) {
      throw ArgumentError('Player with ID "$playerId" not found.');
    }

    // Validate that all slots match the chosen date
    for (final slot in slots) {
      final isSameDay =
          slot.start.year == date.year &&
          slot.start.month == date.month &&
          slot.start.day == date.day;
      if (!isSameDay) {
        throw ArgumentError(
          'Slot starting at ${slot.start} does not belong to date $date.',
        );
      }
    }

    final key = _dateKey(date);
    final raw = _prefs.getString(key);
    final dateMap = <String, dynamic>{};

    if (raw != null && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          dateMap.addAll(decoded);
        }
      } catch (_) {
        // Recover cleanly from corrupted JSON
      }
    }

    dateMap[playerId] = slots.map((s) => s.toJson()).toList();
    await _prefs.setString(key, jsonEncode(dateMap));
  }

  @override
  Future<List<Player>> getPlayersWithAvailability(DateTime date) async {
    final players = await getPlayers();
    if (players.isEmpty) return <Player>[];

    final key = _dateKey(date);
    final raw = _prefs.getString(key);
    final dateMap = <String, dynamic>{};

    if (raw != null && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          dateMap.addAll(decoded);
        }
      } catch (_) {
        // Fall back to empty map if unparseable
      }
    }

    return players.map((player) {
      final dynamic rawSlots = dateMap[player.id];
      if (rawSlots is! List) {
        return player.copyWith(availability: const <AvailabilitySlot>[]);
      }

      final slots = rawSlots
          .whereType<Map<String, dynamic>>()
          .map(AvailabilitySlot.fromJson)
          .toList();

      return player.copyWith(availability: slots);
    }).toList();
  }

  @override
  Future<void> clearAll() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key == playersStorageKey || key.startsWith(availabilityPrefix)) {
        await _prefs.remove(key);
      }
    }
  }

  Future<void> _savePlayersList(List<Player> players) async {
    final encoded = jsonEncode(players.map((p) => p.toJson()).toList());
    await _prefs.setString(playersStorageKey, encoded);
  }
}

/// Riverpod provider for [PlayerRepository].
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlayerRepositoryImpl(prefs);
});
