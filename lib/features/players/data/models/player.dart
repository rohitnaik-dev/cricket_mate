import 'package:flutter/foundation.dart';

import 'availability_slot.dart';

/// Immutable model representing a cricket squad player.
///
/// Ensures player name is trimmed, non-empty, and does not exceed [maxNameLength].
@immutable
class Player {
  Player({
    required String id,
    required String name,
    List<AvailabilitySlot> availability = const <AvailabilitySlot>[],
  }) : id = id.trim(),
       name = name.trim(),
       availability = List<AvailabilitySlot>.unmodifiable(availability) {
    if (this.id.isEmpty) {
      throw ArgumentError('Player id cannot be empty.');
    }
    if (this.name.isEmpty) {
      throw ArgumentError('Player name cannot be empty.');
    }
    if (this.name.length > maxNameLength) {
      throw ArgumentError(
        'Player name cannot exceed $maxNameLength characters (was ${this.name.length}).',
      );
    }
  }

  /// Maximum allowed length for player names.
  static const int maxNameLength = 50;

  /// Unique identifier for the player.
  final String id;

  /// Display name of the player, trimmed of whitespace.
  final String name;

  /// Availability slots associated with this player for a selected context/day.
  final List<AvailabilitySlot> availability;

  /// Deserializes a [Player] from JSON.
  factory Player.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    final rawName = json['name'] as String?;

    if (rawId == null || rawName == null) {
      throw const FormatException('Missing required id or name in Player JSON');
    }

    final rawSlots = json['availability'] as List<dynamic>?;
    final parsedSlots = rawSlots != null
        ? rawSlots
              .map(
                (slot) =>
                    AvailabilitySlot.fromJson(slot as Map<String, dynamic>),
              )
              .toList()
        : const <AvailabilitySlot>[];

    return Player(id: rawId, name: rawName, availability: parsedSlots);
  }

  /// Serializes to JSON.
  /// If [includeAvailability] is true, encodes the player's availability slots.
  Map<String, dynamic> toJson({bool includeAvailability = false}) => {
    'id': id,
    'name': name,
    if (includeAvailability)
      'availability': availability.map((s) => s.toJson()).toList(),
  };

  /// Returns a new [Player] with specified fields replaced.
  Player copyWith({
    String? id,
    String? name,
    List<AvailabilitySlot>? availability,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      availability: availability ?? this.availability,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player &&
        other.id == id &&
        other.name == name &&
        listEquals(other.availability, availability);
  }

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(availability));

  @override
  String toString() =>
      'Player(id: $id, name: $name, slotsCount: ${availability.length})';
}
