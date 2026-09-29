/// Cricket ball types and their environmental tolerance profiles.
enum BallType {
  /// Standard tennis ball, light and hollow.
  /// Highly sensitive to wind drift, but resilient to wet grass and dew.
  /// Does not strictly require daylight (often played under park/flood lights).
  tennis,

  /// Traditional leather cricket ball (red/white/pink).
  /// Strictly requires daylight or proper international-standard floodlights for player safety.
  /// Highly vulnerable to dew and wet outfields (waterlogged leather damages seam, ruins swing, and causes slips).
  /// Better wind penetration due to heavier mass (~156g).
  leather,

  /// Box / tape / indoor cricket.
  /// Played in close quarters or netted enclosures.
  /// Highly tolerant to wind and outfield dew.
  box;

  /// Whether matches using this ball type strictly require natural daylight.
  bool get requiresDaylight => this == BallType.leather;

  /// Multiplier for wind resistance.
  /// Values > 1.0 indicate better wind resilience; < 1.0 indicates wind vulnerability.
  double get windToleranceFactor => switch (this) {
    BallType.tennis => 0.7,
    BallType.leather => 1.25,
    BallType.box => 1.3,
  };

  /// Multiplier for dew vulnerability.
  /// Values > 1.0 indicate greater sensitivity/penalty from dew; < 1.0 indicates tolerance.
  double get dewSensitivityFactor => switch (this) {
    BallType.tennis => 0.6,
    BallType.leather => 1.6,
    BallType.box => 0.5,
  };

  /// User-friendly display name.
  String get displayName => switch (this) {
    BallType.tennis => 'Tennis Ball',
    BallType.leather => 'Leather Ball',
    BallType.box => 'Box Cricket',
  };
}
