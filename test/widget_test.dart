import 'package:cricket_mate/app.dart';
import 'package:cricket_mate/features/weather/data/cache_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('CricketMate smoke test launches and displays tabs', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CricketMateApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial sessions planner tab is visible
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap Players navigation tab
    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();

    // Verify Players screen is active
    expect(find.text('Squad & Availability'), findsOneWidget);
  });
}
