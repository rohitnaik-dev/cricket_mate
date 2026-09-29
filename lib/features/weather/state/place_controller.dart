import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/view_state.dart';
import '../repository/weather_repository.dart';

/// State of place selection and debounced search.
@immutable
class PlaceState {
  const PlaceState({
    this.selectedPlace,
    this.searchState = const ViewState.empty(),
    this.query = '',
  });

  /// The user's currently selected and persisted cricket ground/city.
  final Place? selectedPlace;

  /// Current search results state.
  final ViewState<List<Place>> searchState;

  /// Raw search query string.
  final String query;

  /// Copies this state with optional field updates.
  PlaceState copyWith({
    Place? selectedPlace,
    ViewState<List<Place>>? searchState,
    String? query,
    bool clearSelectedPlace = false,
  }) {
    return PlaceState(
      selectedPlace: clearSelectedPlace
          ? null
          : (selectedPlace ?? this.selectedPlace),
      searchState: searchState ?? this.searchState,
      query: query ?? this.query,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceState &&
        other.selectedPlace == selectedPlace &&
        other.searchState == searchState &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(selectedPlace, searchState, query);
}

/// Controller managing debounced location searches (400ms) and selected place persistence.
class PlaceController extends StateNotifier<PlaceState> {
  PlaceController(
    this._weatherRepository, {
    this.debounceDuration = const Duration(milliseconds: 400),
  }) : super(PlaceState(selectedPlace: _weatherRepository.getSelectedPlace()));

  final WeatherRepository _weatherRepository;
  final Duration debounceDuration;

  Timer? _debounceTimer;

  /// Updates search query with a 400ms cancelable debounce timer.
  void onSearchQueryChanged(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        query: query,
        searchState: const ViewState.empty(),
      );
      return;
    }

    state = state.copyWith(query: query);

    _debounceTimer = Timer(debounceDuration, () {
      _executeSearch(trimmed);
    });
  }

  /// Cancels any scheduled debounce search timer.
  void cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> _executeSearch(String query) async {
    state = state.copyWith(searchState: const ViewState.loading());

    try {
      final results = await _weatherRepository.searchPlaces(query);
      if (results.isEmpty) {
        state = state.copyWith(
          searchState: const ViewState.empty('No matching locations found.'),
        );
      } else {
        state = state.copyWith(searchState: ViewState.success(results));
      }
    } on AppException catch (e) {
      state = state.copyWith(searchState: ViewState.failure(e));
    } catch (e) {
      state = state.copyWith(
        searchState: ViewState.failure(ApiClient.mapError(e)),
      );
    }
  }

  /// Selects [place], persists it to local storage, and resets search state.
  Future<void> selectPlace(Place place) async {
    cancelDebounce();
    await _weatherRepository.saveSelectedPlace(place);
    state = state.copyWith(
      selectedPlace: place,
      searchState: const ViewState.empty(),
      query: '',
    );
  }

  /// Clears active search results and query.
  void clearSearch() {
    cancelDebounce();
    state = state.copyWith(searchState: const ViewState.empty(), query: '');
  }

  @override
  void dispose() {
    cancelDebounce();
    super.dispose();
  }
}

/// Riverpod provider for [PlaceController].
final placeControllerProvider =
    StateNotifierProvider<PlaceController, PlaceState>((ref) {
      final repo = ref.watch(weatherRepositoryProvider);
      return PlaceController(repo);
    });

/// Provider exposing the current [Place?].
final selectedPlaceProvider = Provider<Place?>((ref) {
  return ref.watch(placeControllerProvider).selectedPlace;
});
