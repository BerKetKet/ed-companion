import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ed_companion/main.dart';

void main() {
  testWidgets('ED Companion title and version smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EdCompanionApp(),
      ),
    );

    // Verify that "ED Companion" text appears.
    expect(find.text('ED Companion'), findsOneWidget);
    expect(find.text('Version 1.0.0+1'), findsOneWidget);
  });
}
