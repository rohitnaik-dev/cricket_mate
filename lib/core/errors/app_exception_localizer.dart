import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'app_exception.dart';

/// Extension providing localized presentation text for [AppException].
extension AppExceptionLocalizer on AppException {
  /// Returns a user-facing localized message for this exception.
  String getLocalizedMessage(BuildContext context) {
    final l10n = context.l10n;
    return switch (messageKey) {
      'error_network_connection' => l10n.errorNetworkConnection,
      'error_request_timeout' => l10n.errorRequestTimeout,
      'error_server' => l10n.errorServer,
      'error_parsing_failed' => l10n.errorParsingFailed,
      _ => message.isNotEmpty ? message : l10n.errorGeneric,
    };
  }
}
