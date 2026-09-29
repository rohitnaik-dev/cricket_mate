import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/view_state.dart';
import '../repository/weather_repository.dart';
import 'place_controller.dart';

/// Controller managing weather forecast fetching and offline-cache status.
class WeatherController extends StateNotifier<ViewState<WeatherForecast>> {
  WeatherController(this._weatherRepository, [Place? initialPlace])
    : super(const ViewState.empty()) {
    if (initialPlace != null) {
      fetchForecast(initialPlace);
    }
  }

  final WeatherRepository _weatherRepository;
  Place? _currentPlace;

  /// Currently loaded [Place], if any.
  Place? get currentPlace => _currentPlace;

  /// Fetches weather forecast for [place].
  Future<void> fetchForecast(Place place) async {
    _currentPlace = place;
    state = const ViewState.loading();

    try {
      final loaded = await _weatherRepository.getForecast(place);

      if (loaded.data.hourly.isEmpty) {
        state = const ViewState.empty('No hourly forecast available.');
      } else {
        state = ViewState.success(
          loaded.data,
          updatedAt: loaded.updatedAt,
          fromCache: loaded.fromCache,
        );
      }
    } on AppException catch (e) {
      state = ViewState.failure(e);
    } catch (e) {
      state = ViewState.failure(ApiClient.mapError(e));
    }
  }

  /// Re-fetches weather forecast for the currently loaded place.
  Future<void> refresh() async {
    if (_currentPlace != null) {
      await fetchForecast(_currentPlace!);
    }
  }
}

/// Riverpod provider for [WeatherController], automatically reacting to selected place changes.
final weatherControllerProvider =
    StateNotifierProvider<WeatherController, ViewState<WeatherForecast>>((ref) {
      final repo = ref.watch(weatherRepositoryProvider);
      final place = ref.watch(selectedPlaceProvider);

      final controller = WeatherController(repo, place);

      // Listen for place changes and trigger auto-fetch
      ref.listen<Place?>(selectedPlaceProvider, (previous, next) {
        if (next != null && next != previous) {
          controller.fetchForecast(next);
        }
      });

      return controller;
    });
