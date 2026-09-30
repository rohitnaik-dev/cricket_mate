import 'package:cricket_mate/features/players/repository/player_repository.dart';
import 'package:cricket_mate/features/players/ui/players_screen.dart';
import 'package:cricket_mate/features/players/ui/widgets/add_player_dialog.dart';
import 'package:cricket_mate/features/players/ui/widgets/availability_editor_modal.dart';
import 'package:cricket_mate/features/players/ui/widgets/overlap_preview_card.dart';
import 'package:cricket_mate/features/players/ui/widgets/player_card.dart';
import 'package:cricket_mate/features/players/ui/widgets/players_empty_view.dart';
import 'package:cricket_mate/features/weather/data/cache_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget createSubject({
    required SharedPreferences prefs,
    Size size = const Size(400, 800),
    double textScale = 1.0,
    List<Override> additionalOverrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...additionalOverrides,
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(body: PlayersScreen()),
        ),
      ),
    );
  }

  group('PlayersScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
      'displays empty state view with CTA when squad has no players',
      (tester) async {
        await tester.pumpWidget(createSubject(prefs: prefs));
        await tester.pumpAndSettle();

        expect(find.byType(PlayersEmptyView), findsOneWidget);
        expect(find.text('No Squad Members Yet'), findsOneWidget);
        expect(find.text('Add First Player'), findsOneWidget);

        // Overlap Preview banner displays empty state
        expect(find.byType(OverlapPreviewCard), findsOneWidget);
        expect(find.text('No players added yet'), findsOneWidget);
      },
    );

    testWidgets(
      'inline validation: prevents empty name and duplicate player name',
      (tester) async {
        await tester.pumpWidget(createSubject(prefs: prefs));
        await tester.pumpAndSettle();

        // Open Add Player dialog from empty state CTA
        await tester.tap(find.text('Add First Player'));
        await tester.pumpAndSettle();

        expect(find.byType(AddPlayerDialog), findsOneWidget);

        // Attempt to submit empty name
        final submitFinder = find.widgetWithText(FilledButton, 'Add Player');
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();

        // Inline error appears
        expect(find.text('Player name cannot be empty.'), findsOneWidget);
        expect(find.byType(AddPlayerDialog), findsOneWidget);

        // Type a valid player name and submit
        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Rohit Sharma');
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();

        // Dialog is dismissed and player card is rendered
        expect(find.byType(AddPlayerDialog), findsNothing);
        expect(find.text('Rohit Sharma'), findsOneWidget);
        expect(find.byType(PlayerCard), findsOneWidget);

        // Open Add Player dialog from AppBar icon
        await tester.tap(find.byIcon(Icons.person_add_alt_1).first);
        await tester.pumpAndSettle();

        // Attempt to add duplicate name (case-insensitive)
        await tester.enterText(find.byType(TextField), 'rohit sharma');
        await tester.tap(find.widgetWithText(FilledButton, 'Add Player'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'A player named "rohit sharma" already exists in the squad.',
          ),
          findsOneWidget,
        );

        // Enter unique second player
        await tester.enterText(find.byType(TextField), 'Virat Kohli');
        await tester.tap(find.widgetWithText(FilledButton, 'Add Player'));
        await tester.pumpAndSettle();

        expect(find.text('Virat Kohli'), findsOneWidget);
        expect(find.byType(PlayerCard), findsNWidgets(2));
      },
    );

    testWidgets(
      'availability editor modal opens, applies quick preset, and saves availability',
      (tester) async {
        // Pre-populate one player
        final repo = PlayerRepositoryImpl(prefs);
        await repo.addPlayer(Player(id: 'p1', name: 'Jasprit Bumrah'));

        await tester.pumpWidget(createSubject(prefs: prefs));
        await tester.pumpAndSettle();

        expect(find.text('Jasprit Bumrah'), findsOneWidget);

        // Tap Edit Calendar icon on player card
        await tester.tap(find.byIcon(Icons.edit_calendar_outlined));
        await tester.pumpAndSettle();

        expect(find.byType(AvailabilityEditorModal), findsOneWidget);
        expect(find.text('Quick Presets (Tap to Add)'), findsOneWidget);

        // Tap Evening 5-8 preset
        await tester.tap(find.text('Evening 5-8'));
        await tester.pumpAndSettle();

        // 5:00 PM - 8:00 PM chip should appear under Scheduled Slots
        // Tap Save CTA
        final saveBtn = find.widgetWithText(
          FilledButton,
          'Save Availability for Today',
        );
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Modal closed
        expect(find.byType(AvailabilityEditorModal), findsNothing);

        // PlayerCard now shows Today slot
        expect(find.textContaining('5:00 PM - 8:00 PM'), findsOneWidget);
      },
    );

    testWidgets(
      'availability editor: setting availability for Tomorrow displays under Tmrw on PlayerCard (NOT Today)',
      (tester) async {
        final repo = PlayerRepositoryImpl(prefs);
        await repo.addPlayer(Player(id: 'p1', name: 'Rohit Sharma'));

        await tester.pumpWidget(createSubject(prefs: prefs));
        await tester.pumpAndSettle();

        expect(find.text('Rohit Sharma'), findsOneWidget);
        expect(find.text('Today: No slots'), findsOneWidget);
        expect(find.text('Tmrw: No slots'), findsOneWidget);

        // Tap Edit Calendar icon on player card
        await tester.tap(find.byIcon(Icons.edit_calendar_outlined));
        await tester.pumpAndSettle();

        expect(find.byType(AvailabilityEditorModal), findsOneWidget);

        // Switch to "Tomorrow" tab in the modal
        final tomorrowModalTab = find.descendant(
          of: find.byType(AvailabilityEditorModal),
          matching: find.text('Tomorrow'),
        );
        await tester.tap(tomorrowModalTab);
        await tester.pumpAndSettle();

        // Tap Evening 5-8 preset
        await tester.tap(find.text('Evening 5-8'));
        await tester.pumpAndSettle();

        // Save
        final saveBtn = find.widgetWithText(
          FilledButton,
          'Save Availability for Tomorrow',
        );
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Modal closed
        expect(find.byType(AvailabilityEditorModal), findsNothing);

        // PlayerCard MUST show Today: No slots, and Tmrw: 5:00 PM - 8:00 PM!
        expect(find.text('Today: No slots'), findsOneWidget);
        expect(find.text('Tmrw: 5:00 PM - 8:00 PM'), findsOneWidget);
        // It must NOT show "Today: 5:00 PM - 8:00 PM"
        expect(find.text('Today: 5:00 PM - 8:00 PM'), findsNothing);
      },
    );

    testWidgets(
      'live overlap preview updates dynamically when multiple players share availability',
      (tester) async {
        final repo = PlayerRepositoryImpl(prefs);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Add 2 players with 5-8 PM availability
        final slot5to8 = AvailabilitySlot(
          start: DateTime(today.year, today.month, today.day, 17, 0),
          end: DateTime(today.year, today.month, today.day, 20, 0),
        );

        await repo.addPlayer(Player(id: 'p1', name: 'Hardik Pandya'));
        await repo.setAvailability('p1', today, [slot5to8]);

        await repo.addPlayer(Player(id: 'p2', name: 'KL Rahul'));
        await repo.setAvailability('p2', today, [slot5to8]);

        await tester.pumpWidget(createSubject(prefs: prefs));
        await tester.pumpAndSettle();

        // Live Overlap Preview should display "5:00 PM - 7:00 PM" (2hr session) and "2/2 players"
        expect(find.byType(OverlapPreviewCard), findsOneWidget);
        expect(find.text('5:00 PM - 7:00 PM'), findsOneWidget);
        expect(find.text('2/2 players'), findsOneWidget);

        // Toggle day to Tomorrow in Overlap Preview banner
        await tester.tap(find.text('Tomorrow'));
        await tester.pumpAndSettle();

        // Tomorrow has no availability yet
        expect(find.text('No overlapping time window'), findsOneWidget);
      },
    );

    testWidgets('availability editor allows deleting a scheduled slot', (
      tester,
    ) async {
      final repo = PlayerRepositoryImpl(prefs);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final slot = AvailabilitySlot(
        start: DateTime(today.year, today.month, today.day, 8, 0),
        end: DateTime(today.year, today.month, today.day, 11, 0),
      );
      await repo.addPlayer(Player(id: 'p1', name: 'Shubman Gill'));
      await repo.setAvailability('p1', today, [slot]);

      await tester.pumpWidget(createSubject(prefs: prefs));
      await tester.pumpAndSettle();

      // Open availability editor
      await tester.tap(find.byIcon(Icons.edit_calendar_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AvailabilityEditorModal), findsOneWidget);
      expect(find.text('8:00 AM - 11:00 AM'), findsOneWidget);

      // Tap delete icon on the chip
      final cancelIcon = find.byIcon(Icons.cancel);
      await tester.ensureVisible(cancelIcon);
      await tester.tap(cancelIcon);
      await tester.pumpAndSettle();

      // Slot is removed
      expect(
        find.text(
          'No availability recorded for this day yet. Tap a quick preset or add a custom range above.',
        ),
        findsOneWidget,
      );

      // Save
      final saveBtn = find.widgetWithText(
        FilledButton,
        'Save Availability for Today',
      );
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Player card shows Today: No slots
      expect(find.text('Today: No slots'), findsOneWidget);
    });

    testWidgets(
      'delete player removes squad member and undo SnackBar restores them',
      (tester) async {
        final repo = PlayerRepositoryImpl(prefs);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final slot = AvailabilitySlot(
          start: DateTime(today.year, today.month, today.day, 14, 0),
          end: DateTime(today.year, today.month, today.day, 17, 0),
        );
        await repo.addPlayer(Player(id: 'p1', name: 'Suryakumar Yadav'));
        await repo.setAvailability('p1', today, [slot]);

        await tester.pumpWidget(createSubject(prefs: prefs));
        await tester.pumpAndSettle();

        expect(find.text('Suryakumar Yadav'), findsOneWidget);

        // Tap delete button on player card
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Player is removed from view and empty state / 0 players shown
        expect(find.text('Suryakumar Yadav'), findsNothing);

        // SnackBar appears with Undo button
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text('Suryakumar Yadav removed from squad'),
          findsOneWidget,
        );
        expect(find.text('Undo'), findsOneWidget);

        // Tap Undo
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();

        // Player is restored
        expect(find.text('Suryakumar Yadav'), findsOneWidget);
        expect(find.textContaining('2:00 PM - 5:00 PM'), findsOneWidget);
      },
    );

    testWidgets('renders cleanly without overflow at narrow 320dp width', (
      tester,
    ) async {
      final repo = PlayerRepositoryImpl(prefs);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final slot = AvailabilitySlot(
        start: DateTime(today.year, today.month, today.day, 17, 0),
        end: DateTime(today.year, today.month, today.day, 20, 0),
      );
      await repo.addPlayer(Player(id: 'p1', name: 'Ravindra Jadeja'));
      await repo.setAvailability('p1', today, [slot]);

      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createSubject(prefs: prefs, size: const Size(320, 600)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ravindra Jadeja'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 200% text scale', (
      tester,
    ) async {
      final repo = PlayerRepositoryImpl(prefs);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final slot = AvailabilitySlot(
        start: DateTime(today.year, today.month, today.day, 17, 0),
        end: DateTime(today.year, today.month, today.day, 20, 0),
      );
      await repo.addPlayer(Player(id: 'p1', name: 'Mohammed Siraj'));
      await repo.setAvailability('p1', today, [slot]);

      await tester.pumpWidget(createSubject(prefs: prefs, textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Mohammed Siraj'), findsOneWidget);
    });

    testWidgets('renders two-column layout in landscape orientation', (
      tester,
    ) async {
      final repo = PlayerRepositoryImpl(prefs);
      await repo.addPlayer(Player(id: 'p1', name: 'Rishabh Pant'));

      tester.view.physicalSize = const Size(800, 450);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createSubject(prefs: prefs, size: const Size(800, 450)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Rishabh Pant'), findsOneWidget);
      // In landscape, two column layout has OverlapPreviewCard and squad list side-by-side
      expect(find.byType(OverlapPreviewCard), findsOneWidget);
      expect(find.text('Squad Members'), findsOneWidget);
      expect(find.text('1 registered'), findsOneWidget);
      expect(find.text('Availability Tips'), findsOneWidget);
    });
  });
}
