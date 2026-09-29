import 'package:flutter/foundation.dart';

/// Immutable model representing daily solar/astronomical times (sunrise and sunset).
@immutable
class DailyAstro {
  const DailyAstro({required this.date, this.sunrise, this.sunset});

  /// The calendar date for these astronomical values.
  final DateTime date;

  /// Local sunrise timestamp.
  final DateTime? sunrise;

  /// Local sunset timestamp.
  final DateTime? sunset;

  /// Converts this [DailyAstro] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date.toIso8601String().split('T').first,
      if (sunrise != null) 'sunrise': sunrise!.toIso8601String(),
      if (sunset != null) 'sunset': sunset!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyAstro &&
        other.date == date &&
        other.sunrise == sunrise &&
        other.sunset == sunset;
  }

  @override
  int get hashCode => Object.hash(date, sunrise, sunset);

  @override
  String toString() =>
      'DailyAstro(date: ${date.toIso8601String().split('T').first}, sunrise: $sunrise, sunset: $sunset)';
}
