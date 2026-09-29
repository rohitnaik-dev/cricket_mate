/// Tone categorization for visual chips displayed in the UI.
enum ReasonTone {
  /// Favorable condition for cricket (e.g. low rain, comfortable temp, high turnout).
  positive,

  /// Unfavorable or risk condition (e.g. high rain, mud, thunderstorm, below quorum).
  negative,

  /// Cautionary note (e.g. high UV, evening dew, borderline wind).
  warning,

  /// Informational context.
  neutral,
}

/// Descriptive chip highlighting a positive or negative factor affecting a session score.
class ReasonChip {
  const ReasonChip({required this.message, required this.tone});

  /// Factory for a positive reason.
  const ReasonChip.positive(this.message) : tone = ReasonTone.positive;

  /// Factory for a negative reason.
  const ReasonChip.negative(this.message) : tone = ReasonTone.negative;

  /// Factory for a warning reason.
  const ReasonChip.warning(this.message) : tone = ReasonTone.warning;

  /// Factory for an informational reason.
  const ReasonChip.neutral(this.message) : tone = ReasonTone.neutral;

  /// Human-readable explanation.
  final String message;

  /// Categorical tone.
  final ReasonTone tone;

  /// Convenience helper to check if this factor is positive.
  bool get isPositive => tone == ReasonTone.positive;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReasonChip &&
        other.message == message &&
        other.tone == tone;
  }

  @override
  int get hashCode => Object.hash(message, tone);

  @override
  String toString() => 'ReasonChip($tone: $message)';
}
