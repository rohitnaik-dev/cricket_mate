import 'package:flutter/widgets.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/reason_chip.dart';

/// Extension providing localization for [ReasonChip] in presentation layer.
extension ReasonChipLocalizer on ReasonChip {
  /// Returns the localized description based on [messageKey] or falls back to [message].
  String getLocalizedMessage(BuildContext context) {
    if (messageKey == null) return message;
    final l10n = context.l10n;
    final args = arguments ?? const <String, dynamic>{};

    return switch (messageKey!) {
      'reasonThunderstorm' => l10n.reasonThunderstorm,
      'reasonRainRisk' => l10n.reasonRainRisk(
        (args['percent'] as num?)?.toInt() ?? 70,
      ),
      'reasonBelowQuorum' => l10n.reasonBelowQuorum(
        (args['count'] as num?)?.toInt() ?? 0,
        (args['quorum'] as num?)?.toInt() ?? 6,
      ),
      'reasonLeatherDaylight' => l10n.reasonLeatherDaylight,
      'reasonLowRain' => l10n.reasonLowRain,
      'reasonIdealTemp' => l10n.reasonIdealTemp,
      'reasonChillyTemp' => l10n.reasonChillyTemp,
      'reasonGentleBreeze' => l10n.reasonGentleBreeze,
      'reasonGustyWind' => l10n.reasonGustyWind,
      'reasonWetGround' => l10n.reasonWetGround((args['mm'] ?? '0').toString()),
      'reasonDryOutfield' => l10n.reasonDryOutfield,
      'reasonDewRisk' => l10n.reasonDewRisk,
      'reasonQuorumReached' => l10n.reasonQuorumReached(
        (args['count'] as num?)?.toInt() ?? 0,
        (args['quorum'] as num?)?.toInt() ?? 6,
      ),
      _ => message,
    };
  }
}
