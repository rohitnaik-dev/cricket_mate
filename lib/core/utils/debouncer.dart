import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lightweight debouncer to delay callback invocation until a quiet period has elapsed.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 400)});

  final Duration duration;
  Timer? _timer;

  /// Runs the provided [action] after the debouncer [duration].
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels any scheduled invocation.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes timer resources.
  void dispose() {
    cancel();
  }
}
