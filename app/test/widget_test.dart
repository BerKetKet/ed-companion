import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ed_companion/features/shell/lock/lock_controller.dart';
import 'package:ed_companion/features/shell/settings_provider.dart';
import 'package:ed_companion/main.dart';

class UnlockedLockController extends LockController {
  @override
  AppLockState build() {
    return const AppLockState(
      isInitialized: true,
      hasPin: true,
      isLocked: false,
      failedAttempts: 0,
      lockoutRemainingSeconds: 0,
      biometricsSupported: false,
    );
  }
}

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
          lockControllerProvider.overrideWith(UnlockedLockController.new),
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
          lockControllerProvider.overrideWith(UnlockedLockController.new),
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
}
