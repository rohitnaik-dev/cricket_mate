import '../../players/domain/overlap_window.dart';
import 'ball_type.dart';
import 'conditions_scorer.dart';
import 'reason_chip.dart';
import 'weather_scorer.dart';

/// Categorical recommendation tier based on final session score.
enum SessionRating {
  excellent,
  good,
  fair,
  poor,
  notRecommended;

  /// Human-readable label matching user requirements.
  String get label => switch (this) {
    SessionRating.excellent => 'Excellent',
    SessionRating.good => 'Good',
    SessionRating.fair => 'Fair',
    SessionRating.poor => 'Poor',
    SessionRating.notRecommended => 'Not recommended',
  };

  /// Derives categorical rating from numeric score.
  static SessionRating fromScore(double score) {
    if (score >= 85.0) return SessionRating.excellent;
    if (score >= 70.0) return SessionRating.good;
    if (score >= 50.0) return SessionRating.fair;
    if (score >= 30.0) return SessionRating.poor;
    return SessionRating.notRecommended;
  }
}

/// Comprehensive evaluated candidate cricket session.
class SessionCandidate {
  SessionCandidate({
    required this.window,
    required this.score,
    required this.rating,
    required this.weatherScores,
    required this.conditionsScores,
    required this.availabilityScore,
    required this.ballType,
    required List<ReasonChip> reasonChips,
    List<String> vetoReasons = const <String>[],
  }) : reasonChips = List<ReasonChip>.unmodifiable(reasonChips),
       vetoReasons = List<String>.unmodifiable(vetoReasons);

  /// The time window and squad members available for the session.
  final OverlapWindow window;

  /// Overall session score (0.0 - 100.0).
  final double score;

  /// Categorical recommendation tier.
  final SessionRating rating;

  /// Human-friendly rating label ('Excellent', 'Good', 'Fair', 'Poor', 'Not recommended').
  String get label => rating.label;

  /// Granular weather sub-scores (rain, temp, wind, humidity, uv).
  final WeatherSubScores weatherScores;

  /// Ground and ambient condition sub-scores (outfield, dew, daylight).
  final ConditionsSubScores conditionsScores;

  /// Squad attendance score against quorum.
  final double availabilityScore;

  /// Ball type evaluated for this session.
  final BallType ballType;

  /// Contextual explanations with positive/negative visual tone.
  final List<ReasonChip> reasonChips;

  /// List of hard veto triggers that capped the score at <= 30.
  final List<String> vetoReasons;

  /// Whether a safety or match viability veto was triggered.
  bool get hasVeto => vetoReasons.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionCandidate &&
        other.window == window &&
        other.score == score &&
        other.rating == rating &&
        other.weatherScores == weatherScores &&
        other.conditionsScores == conditionsScores &&
        other.availabilityScore == availabilityScore &&
        other.ballType == ballType;
  }

  @override
  int get hashCode => Object.hash(
    window,
    score,
    rating,
    weatherScores,
    conditionsScores,
    availabilityScore,
    ballType,
  );

  @override
  String toString() =>
      'SessionCandidate(score: ${score.toStringAsFixed(1)}, label: $label, window: ${window.start} - ${window.end}, players: ${window.playerCount})';
}
