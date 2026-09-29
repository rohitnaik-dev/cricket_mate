import 'package:cricket_mate/core/errors/app_exception.dart';
import 'package:cricket_mate/core/state/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewState<T> sealed hierarchy', () {
    test('ViewLoading represents operation in flight', () {
      const state = ViewState<String>.loading();

      expect(state.isLoading, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.isEmpty, isFalse);
      expect(state.isFailure, isFalse);
      expect(state.dataOrNull, isNull);
    });

    test('ViewSuccess holds data, updatedAt, and fromCache metadata', () {
      final now = DateTime(2026, 9, 30, 15, 0);
      final state = ViewState<int>.success(42, updatedAt: now, fromCache: true);

      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.dataOrNull, equals(42));

      switch (state) {
        case ViewSuccess<int>(:final data, :final updatedAt, :final fromCache):
          expect(data, equals(42));
          expect(updatedAt, equals(now));
          expect(fromCache, isTrue);
        default:
          fail('Expected ViewSuccess');
      }
    });

    test('ViewEmpty represents empty results with optional message', () {
      const state = ViewState<List<String>>.empty('No items found');

      expect(state.isEmpty, isTrue);
      expect(state.dataOrNull, isNull);

      final msg = switch (state) {
        ViewEmpty<List<String>>(:final message) => message,
        _ => null,
      };
      expect(msg, equals('No items found'));
    });

    test('ViewFailure encapsulates AppException', () {
      const exception = NetworkException();
      const state = ViewState<String>.failure(exception);

      expect(state.isFailure, isTrue);
      expect(state.dataOrNull, isNull);

      final caught = switch (state) {
        ViewFailure<String>(:final exception) => exception,
        _ => null,
      };
      expect(caught, equals(exception));
    });

    test('when helper method handles all branches exhaustively', () {
      const ViewState<String> loading = ViewState.loading();
      const ViewState<String> success = ViewState.success('hello');
      const ViewState<String> empty = ViewState.empty('none');
      const ViewState<String> failure = ViewState.failure(NetworkException());

      String branch(ViewState<String> state) {
        return state.when(
          loading: () => 'L',
          success: (d, _, _) => 'S:$d',
          empty: (m) => 'E:$m',
          failure: (e) => 'F:${e.messageKey}',
        );
      }

      expect(branch(loading), equals('L'));
      expect(branch(success), equals('S:hello'));
      expect(branch(empty), equals('E:none'));
      expect(branch(failure), equals('F:error_network_connection'));
    });
  });
}
