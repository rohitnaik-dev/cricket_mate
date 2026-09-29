import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';

/// Exhaustive UI state representation modeling asynchronous operations.
///
/// Subclasses:
/// - [ViewLoading]: Work is actively in flight.
/// - [ViewSuccess]: Data was retrieved successfully with cache and timestamp metadata.
/// - [ViewEmpty]: Completed successfully but yielded no items or results.
/// - [ViewFailure]: An unrecoverable [AppException] occurred.
@immutable
sealed class ViewState<T> {
  const ViewState();

  /// Constant constructor creating a [ViewLoading] state.
  const factory ViewState.loading() = ViewLoading<T>;

  /// Constant constructor creating a [ViewSuccess] state.
  const factory ViewState.success(
    T data, {
    DateTime? updatedAt,
    bool fromCache,
  }) = ViewSuccess<T>;

  /// Constant constructor creating a [ViewEmpty] state with an optional message.
  const factory ViewState.empty([String? message]) = ViewEmpty<T>;

  /// Constant constructor creating a [ViewFailure] state wrapping an [AppException].
  const factory ViewState.failure(AppException exception) = ViewFailure<T>;

  /// True if the current state is [ViewLoading].
  bool get isLoading => this is ViewLoading<T>;

  /// True if the current state is [ViewSuccess].
  bool get isSuccess => this is ViewSuccess<T>;

  /// True if the current state is [ViewEmpty].
  bool get isEmpty => this is ViewEmpty<T>;

  /// True if the current state is [ViewFailure].
  bool get isFailure => this is ViewFailure<T>;

  /// Returns [ViewSuccess.data] if this is [ViewSuccess], null otherwise.
  T? get dataOrNull => switch (this) {
    ViewSuccess<T>(:final data) => data,
    _ => null,
  };

  /// Exhaustive pattern-matching helper executing the appropriate callback.
  R when<R>({
    required R Function() loading,
    required R Function(T data, DateTime? updatedAt, bool fromCache) success,
    required R Function(String? message) empty,
    required R Function(AppException exception) failure,
  }) {
    return switch (this) {
      ViewLoading<T>() => loading(),
      ViewSuccess<T>(:final data, :final updatedAt, :final fromCache) =>
        success(data, updatedAt, fromCache),
      ViewEmpty<T>(:final message) => empty(message),
      ViewFailure<T>(:final exception) => failure(exception),
    };
  }

  /// Optional pattern-matching helper with fallback.
  R maybeWhen<R>({
    R Function()? loading,
    R Function(T data, DateTime? updatedAt, bool fromCache)? success,
    R Function(String? message)? empty,
    R Function(AppException exception)? failure,
    required R Function() orElse,
  }) {
    return switch (this) {
      ViewLoading<T>() => loading != null ? loading() : orElse(),
      ViewSuccess<T>(:final data, :final updatedAt, :final fromCache) =>
        success != null ? success(data, updatedAt, fromCache) : orElse(),
      ViewEmpty<T>(:final message) => empty != null ? empty(message) : orElse(),
      ViewFailure<T>(:final exception) =>
        failure != null ? failure(exception) : orElse(),
    };
  }
}

/// State indicating an asynchronous operation is in flight.
final class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ViewLoading<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ViewState<$T>.loading()';
}

/// State indicating successful data retrieval with freshness metadata.
final class ViewSuccess<T> extends ViewState<T> {
  const ViewSuccess(this.data, {this.updatedAt, this.fromCache = false});

  /// The loaded data payload.
  final T data;

  /// Timestamp when this data payload was saved or generated.
  final DateTime? updatedAt;

  /// True if served from local persistent cache, false if freshly fetched over network.
  final bool fromCache;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ViewSuccess<T> &&
        other.data == data &&
        other.updatedAt == updatedAt &&
        other.fromCache == fromCache;
  }

  @override
  int get hashCode => Object.hash(data, updatedAt, fromCache);

  @override
  String toString() =>
      'ViewState<$T>.success(data: $data, updatedAt: $updatedAt, fromCache: $fromCache)';
}

/// State indicating successful query completion that yielded no results.
final class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty([this.message]);

  /// Optional message explaining why no results were available.
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ViewEmpty<T> && other.message == message);

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => 'ViewState<$T>.empty(message: $message)';
}

/// State indicating an operation failed due to a domain [AppException].
final class ViewFailure<T> extends ViewState<T> {
  const ViewFailure(this.exception);

  /// The domain exception encapsulating the failure cause.
  final AppException exception;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ViewFailure<T> && other.exception == exception);

  @override
  int get hashCode => Object.hash(runtimeType, exception);

  @override
  String toString() => 'ViewState<$T>.failure(exception: $exception)';
}
