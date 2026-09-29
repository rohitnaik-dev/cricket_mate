import 'package:cricket_mate/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CricketMate smoke test launches and displays tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CricketMateApp()));
    await tester.pumpAndSettle();

    // Verify initial sessions planner tab is visible
    expect(find.text('When should we play?'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Weather'), findsOneWidget);

    // Tap Weather navigation tab
    await tester.tap(find.text('Weather'));
    await tester.pumpAndSettle();

    // Verify Weather screen content is now active
    expect(find.text('Ground Weather'), findsOneWidget);
  });
}
