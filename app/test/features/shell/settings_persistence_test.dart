import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ed_companion/core/handedness.dart';
import 'package:ed_companion/features/shell/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Settings persistence', () {
    test('barMode defaults to autoHide and persists correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(settingsProvider).barMode, equals(BarMode.autoHide));

      await container.read(settingsProvider.notifier).setBarMode(BarMode.gesturesOnly);
      expect(container.read(settingsProvider).barMode, equals(BarMode.gesturesOnly));
      expect(prefs.getString('bar_mode'), equals('gesturesOnly'));

      await container.read(settingsProvider.notifier).setBarMode(BarMode.alwaysShow);
      expect(container.read(settingsProvider).barMode, equals(BarMode.alwaysShow));
      expect(prefs.getString('bar_mode'), equals('alwaysShow'));
    });

    test('handedness defaults to right and persists correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(settingsProvider).handedness, equals(Handedness.right));

      await container.read(settingsProvider.notifier).setHandedness(Handedness.left);
      expect(container.read(settingsProvider).handedness, equals(Handedness.left));
      expect(prefs.getString('handedness'), equals('left'));

      await container.read(settingsProvider.notifier).setHandedness(Handedness.right);
      expect(container.read(settingsProvider).handedness, equals(Handedness.right));
      expect(prefs.getString('handedness'), equals('right'));
    });

    test('quickButtonVisible defaults to true and persists correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(settingsProvider).quickButtonVisible, isTrue);

      await container.read(settingsProvider.notifier).setQuickButtonVisible(false);
      expect(container.read(settingsProvider).quickButtonVisible, isFalse);
      expect(prefs.getBool('quick_button_visible'), isFalse);

      await container.read(settingsProvider.notifier).setQuickButtonVisible(true);
      expect(container.read(settingsProvider).quickButtonVisible, isTrue);
      expect(prefs.getBool('quick_button_visible'), isTrue);
    });

    test('gestureHintSeen defaults to false and persists correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(settingsProvider).gestureHintSeen, isFalse);

      await container.read(settingsProvider.notifier).setGestureHintSeen(true);
      expect(container.read(settingsProvider).gestureHintSeen, isTrue);
      expect(prefs.getBool('gesture_hint_seen'), isTrue);

      await container.read(settingsProvider.notifier).setGestureHintSeen(false);
      expect(container.read(settingsProvider).gestureHintSeen, isFalse);
      expect(prefs.getBool('gesture_hint_seen'), isFalse);
    });
  });
}
