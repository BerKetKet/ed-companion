import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ed_companion/features/shell/settings_provider.dart';
import 'package:ed_companion/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('tapping Study in the bottom bar shows the Study placeholder',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const EdCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Work tab is initially open with Patients placeholder
    expect(find.text('Patients: ward board coming in module B'), findsOneWidget);

    // Tap Study in the bottom navigation bar
    final studyTabFinder = find.byIcon(Icons.menu_book_outlined);
    expect(studyTabFinder, findsOneWidget);
    await tester.tap(studyTabFinder);
    await tester.pumpAndSettle();

    // Verify Study placeholder is displayed
    expect(find.text('Study library: coming in module E'), findsOneWidget);
  });

  testWidgets(
      'tapping "Hospital" in the segmented button shows the Hospital placeholder, tapping "Patients" returns',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const EdCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Initial state: Patients placeholder visible
    expect(find.text('Patients: ward board coming in module B'), findsOneWidget);

    // Tap "Hospital" segmented button
    final hospitalButton = find.text('Hospital');
    expect(hospitalButton, findsOneWidget);
    await tester.tap(hospitalButton);
    await tester.pumpAndSettle();

    // Verify Hospital placeholder is shown
    expect(find.text('Hospital system: coming in module C'), findsOneWidget);

    // Tap "Patients" segmented button to return
    final patientsButton = find.text('Patients');
    expect(patientsButton, findsOneWidget);
    await tester.tap(patientsButton);
    await tester.pumpAndSettle();

    // Verify Patients placeholder is shown again
    expect(find.text('Patients: ward board coming in module B'), findsOneWidget);
  });

  testWidgets(
      'tapping the quick button shows the six labels, choosing Study opens the Study placeholder',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const EdCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Quick bolt button is visible
    final boltButton = find.byIcon(Icons.bolt);
    expect(boltButton, findsOneWidget);

    // Labels are not built yet when closed
    expect(find.text('Drafts'), findsNothing);
    expect(find.text('New task'), findsNothing);

    // Tap the bolt button to open fan-out menu
    await tester.tap(boltButton);
    await tester.pumpAndSettle();

    // Six items are now visible
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Drafts'), findsOneWidget);
    expect(find.text('New task'), findsOneWidget);
    // Patients, Hospital, and Study are present on screen and in the menu
    expect(find.text('Patients'), findsNWidgets(2));
    expect(find.text('Hospital'), findsNWidgets(2));
    expect(find.text('Study'), findsNWidgets(2));

    // Tap Study in the fan-out menu (last one found)
    await tester.tap(find.text('Study').last);
    await tester.pumpAndSettle();

    // Verify Study library placeholder is open
    expect(find.text('Study library: coming in module E'), findsOneWidget);
  });

  testWidgets(
      'scrolling the Patients list down hides the segmented row and scrolling up shows it',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const EdCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Segmented button is initially visible
    expect(find.byType(SegmentedButton<int>), findsOneWidget);

    // Scroll down the list (drag upward by 300 dp)
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0));
    await tester.pumpAndSettle();

    // Segmented button has collapsed into SizedBox.shrink()
    expect(find.byType(SegmentedButton<int>), findsNothing);

    // Scroll back up (drag downward by 300 dp)
    await tester.drag(find.byType(ListView), const Offset(0.0, 300.0));
    await tester.pumpAndSettle();

    // Segmented button is visible again
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
  });

  testWidgets('the hint card shows once and not again after dismiss',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const EdCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Hint card is visible on first launch
    final tipFinder = find.textContaining('Tips: swipe sideways to switch Patients and Hospital');
    expect(tipFinder, findsOneWidget);

    // Tap "Got it"
    final gotItFinder = find.text('Got it');
    expect(gotItFinder, findsOneWidget);
    await tester.tap(gotItFinder);
    await tester.pumpAndSettle();

    // Hint card is dismissed
    expect(tipFinder, findsNothing);
    expect(prefs.getBool('gesture_hint_seen'), isTrue);

    // Re-pump widget: remains dismissed
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const EdCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tipFinder, findsNothing);
  });
}
