import 'package:cricket_mate/core/errors/app_exception.dart';
import 'package:cricket_mate/core/state/view_state.dart';
import 'package:cricket_mate/features/weather/repository/weather_repository.dart';
import 'package:cricket_mate/features/weather/state/place_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late MockWeatherRepository mockRepo;
  late PlaceController controller;

  const testPlace = Place(
    name: 'London',
    country: 'United Kingdom',
    latitude: 51.5074,
    longitude: -0.1278,
    timezone: 'Europe/London',
  );

  setUpAll(() {
    registerFallbackValue(testPlace);
  });

  setUp(() {
    mockRepo = MockWeatherRepository();
    when(() => mockRepo.getSelectedPlace()).thenReturn(null);
    when(() => mockRepo.saveSelectedPlace(any())).thenAnswer((_) async {});
    controller = PlaceController(mockRepo);
  });

  tearDown(() {
    controller.dispose();
  });

  group('PlaceController', () {
    test('debounce fires once for rapid typing within 400ms', () async {
      when(() => mockRepo.searchPlaces('London'))
          .thenAnswer((_) async => [testPlace]);

      controller = PlaceController(
        mockRepo,
        debounceDuration: const Duration(milliseconds: 100),
      );

      // Simulate rapid user keystrokes
      controller.onSearchQueryChanged('L');
      controller.onSearchQueryChanged('Lo');
      controller.onSearchQueryChanged('Lon');
      controller.onSearchQueryChanged('Lond');
      controller.onSearchQueryChanged('London');

      // Before debounce duration elapses, search should NOT have been called
      verifyNever(() => mockRepo.searchPlaces(any()));

      // Wait for debounce timer to fire
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Verify search was invoked EXACTLY once with the final query 'London'
      verify(() => mockRepo.searchPlaces('London')).called(1);

      expect(controller.state.searchState.isSuccess, isTrue);
      expect(controller.state.searchState.dataOrNull, equals([testPlace]));
    });

    test(
      'state transitions: Loading -> Success when search returns places',
      () async {
        when(() => mockRepo.searchPlaces('Manchester'))
            .thenAnswer((_) async => [testPlace]);

        controller = PlaceController(
          mockRepo,
          debounceDuration: const Duration(milliseconds: 50),
        );

        final states = <ViewState<List<Place>>>[];
        controller.addListener((state) {
          states.add(state.searchState);
        });

        controller.onSearchQueryChanged('Manchester');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(states.any((s) => s.isLoading), isTrue);
        expect(states.last.isSuccess, isTrue);
        expect(states.last.dataOrNull?.length, equals(1));
      },
    );

    test(
      'state transitions: Loading -> Empty when search returns 0 results',
      () async {
        when(() => mockRepo.searchPlaces('Atlantis'))
            .thenAnswer((_) async => <Place>[]);

        controller = PlaceController(
          mockRepo,
          debounceDuration: const Duration(milliseconds: 50),
        );

        controller.onSearchQueryChanged('Atlantis');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(controller.state.searchState.isEmpty, isTrue);
      },
    );

    test(
      'state transitions: Loading -> Failure on network exception',
      () async {
        when(() => mockRepo.searchPlaces('OfflineCity'))
            .thenThrow(const NetworkException());

        controller = PlaceController(
          mockRepo,
          debounceDuration: const Duration(milliseconds: 50),
        );

        controller.onSearchQueryChanged('OfflineCity');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(controller.state.searchState.isFailure, isTrue);
        final failure =
            controller.state.searchState as ViewFailure<List<Place>>;
        expect(failure.exception, isA<NetworkException>());
      },
    );

    test('selectPlace updates selectedPlace, persists to storage, and resets search', () async {
      controller = PlaceController(mockRepo);

      await controller.selectPlace(testPlace);

      verify(() => mockRepo.saveSelectedPlace(testPlace)).called(1);
      expect(controller.state.selectedPlace, equals(testPlace));
      expect(controller.state.searchState.isEmpty, isTrue);
      expect(controller.state.query, isEmpty);
    });
  });
}
