import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';

/// Immutable model representing a geographic place or cricket venue resolved from Geocoding.
@immutable
class Place {
  const Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.admin1,
    this.country,
  });

  /// Name of the venue, city, or locality.
  final String name;

  /// Latitude coordinate in decimal degrees.
  final double latitude;

  /// Longitude coordinate in decimal degrees.
  final double longitude;

  /// Local timezone identifier (e.g. "Europe/London", "Asia/Kolkata").
  final String timezone;

  /// State, province, or region name, if available.
  final String? admin1;

  /// Country name, if available.
  final String? country;

  /// Deserializes a [Place] from Open-Meteo Geocoding JSON payload.
  /// Throws [ParsingException] if mandatory coordinates or identifiers are missing or invalid.
  factory Place.fromJson(Map<String, dynamic> json) {
    final String? rawName = json['name'] as String?;
    final num? rawLat = json['latitude'] as num?;
    final num? rawLng = json['longitude'] as num?;

    if (rawName == null || rawName.trim().isEmpty) {
      throw const ParsingException(
        message: 'Place is missing a required name field.',
      );
    }

    if (rawLat == null || rawLng == null) {
      throw const ParsingException(
        message: 'Place is missing valid geographic coordinates.',
      );
    }

    return Place(
      name: rawName.trim(),
      latitude: rawLat.toDouble(),
      longitude: rawLng.toDouble(),
      timezone: json['timezone'] as String? ?? 'UTC',
      admin1: json['admin1'] as String?,
      country: json['country'] as String?,
    );
  }

  /// Converts this [Place] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      if (admin1 != null) 'admin1': admin1,
      if (country != null) 'country': country,
    };
  }

  /// Formatted presentation label (e.g. "Lord's, England, United Kingdom").
  String get displayName {
    final parts = <String>[
      name,
      if (admin1 != null && admin1!.isNotEmpty) admin1!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Place &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timezone == timezone &&
        other.admin1 == admin1 &&
        other.country == country;
  }

  @override
  int get hashCode =>
      Object.hash(name, latitude, longitude, timezone, admin1, country);

  @override
  String toString() =>
      'Place(name: $name, lat: $latitude, lng: $longitude, tz: $timezone, admin1: $admin1, country: $country)';
}
