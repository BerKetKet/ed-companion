import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ed_companion/features/shell/chrome/chrome_provider.dart';
import 'package:ed_companion/features/shell/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChromeNotifier and state', () {
    test('default state with autoHide mode has barsRevealed and barsVisible true', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final chrome = container.read(chromeProvider);
      expect(chrome.barsRevealed, isTrue);
      expect(chrome.barsVisible, isTrue);
    });

    test('mode changes: autoHide reveals bars, gesturesOnly hides bars', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Switch to gesturesOnly
      await container.read(settingsProvider.notifier).setBarMode(BarMode.gesturesOnly);
      expect(container.read(chromeProvider).barsRevealed, isFalse);
      expect(container.read(chromeProvider).barsVisible, isFalse);

      // Switch to autoHide
      await container.read(settingsProvider.notifier).setBarMode(BarMode.autoHide);
      expect(container.read(chromeProvider).barsRevealed, isTrue);
      expect(container.read(chromeProvider).barsVisible, isTrue);

      // Switch to alwaysShow
      await container.read(settingsProvider.notifier).setBarMode(BarMode.alwaysShow);
      expect(container.read(chromeProvider).barsVisible, isTrue);
    });

    test('alwaysShow mode keeps barsVisible true even after hide()', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bar_mode', 'alwaysShow');

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(chromeProvider).barsVisible, isTrue);

      // Call hide(): barsRevealed becomes false, but barsVisible stays true in alwaysShow
      container.read(chromeProvider.notifier).hide();
      expect(container.read(chromeProvider).barsRevealed, isFalse);
      expect(container.read(chromeProvider).barsVisible, isTrue);
    });

    testWidgets('reveal timer in gesturesOnly mode hides bars after 5 seconds', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bar_mode', 'gesturesOnly');

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chromeProvider.notifier);
      expect(container.read(chromeProvider).barsVisible, isFalse);

      // Call reveal()
      notifier.reveal();
      expect(container.read(chromeProvider).barsVisible, isTrue);

      // Advance 4 seconds: still visible
      await tester.pump(const Duration(seconds: 4));
      expect(container.read(chromeProvider).barsVisible, isTrue);

      // Advance 1 more second (total 5): now hidden
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(chromeProvider).barsVisible, isFalse);
    });

    testWidgets('reveal in gesturesOnly restarts the 5-second timer on subsequent reveal', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bar_mode', 'gesturesOnly');

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chromeProvider.notifier);
      notifier.reveal();
      expect(container.read(chromeProvider).barsVisible, isTrue);

      // Advance 3 seconds
      await tester.pump(const Duration(seconds: 3));
      expect(container.read(chromeProvider).barsVisible, isTrue);

      // Second reveal() restarts timer
      notifier.reveal();

      // Advance 3 more seconds (6 total from first, 3 from second): still visible!
      await tester.pump(const Duration(seconds: 3));
      expect(container.read(chromeProvider).barsVisible, isTrue);

      // Advance 2 more seconds (5 total from second): now hidden
      await tester.pump(const Duration(seconds: 2));
      expect(container.read(chromeProvider).barsVisible, isFalse);
    });

    testWidgets('autoHide never hides through reveal', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bar_mode', 'autoHide');

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chromeProvider.notifier);
      notifier.hide();
      expect(container.read(chromeProvider).barsVisible, isFalse);

      notifier.reveal();
      expect(container.read(chromeProvider).barsVisible, isTrue);

      // Advance 10 seconds: must NEVER auto-hide through reveal
      await tester.pump(const Duration(seconds: 10));
      expect(container.read(chromeProvider).barsVisible, isTrue);
    });

    test('branch switch shows bars', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bar_mode', 'autoHide');

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      container.read(chromeProvider.notifier).hide();
      expect(container.read(chromeProvider).barsVisible, isFalse);

      container.read(chromeProvider.notifier).onBranchChanged();
      expect(container.read(chromeProvider).barsVisible, isTrue);
    });
  });
}
