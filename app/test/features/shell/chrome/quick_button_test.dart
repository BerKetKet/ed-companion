import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ed_companion/core/handedness.dart';
import 'package:ed_companion/features/shell/chrome/quick_button_provider.dart';
import 'package:ed_companion/features/shell/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Quick button logic and state', () {
    test('snapSide pure function snaps to nearer edge', () {
      const screenWidth = 400.0;
      // Coordinates left of center snap to left
      expect(snapSide(50.0, screenWidth), equals(HandednessSide.left));
      expect(snapSide(199.9, screenWidth), equals(HandednessSide.left));

      // Coordinates at or right of center snap to right
      expect(snapSide(200.0, screenWidth), equals(HandednessSide.right));
      expect(snapSide(350.0, screenWidth), equals(HandednessSide.right));
    });

    test('initial defaults: side from handedness (right), fraction 0.65 for both', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(quickButtonProvider);
      expect(state.side, equals(HandednessSide.right));
      expect(state.dyRight, equals(0.65));
      expect(state.dyLeft, equals(0.65));
      expect(state.currentDy, equals(0.65));
    });

    test('position persistence per side: left and right remember their own heights', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(quickButtonProvider.notifier);

      // Set position on right side to 0.40
      await notifier.setPosition(HandednessSide.right, 0.40);
      expect(container.read(quickButtonProvider).side, equals(HandednessSide.right));
      expect(container.read(quickButtonProvider).dyRight, equals(0.40));
      expect(container.read(quickButtonProvider).dyLeft, equals(0.65));
      expect(prefs.getDouble('quick_dy_right'), equals(0.40));

      // Drag over to left side and set position to 0.85
      await notifier.setPosition(HandednessSide.left, 0.85);
      expect(container.read(quickButtonProvider).side, equals(HandednessSide.left));
      expect(container.read(quickButtonProvider).dyLeft, equals(0.85));
      // Right side position is still preserved at 0.40!
      expect(container.read(quickButtonProvider).dyRight, equals(0.40));
      expect(prefs.getDouble('quick_dy_left'), equals(0.85));
      expect(prefs.getString('quick_side'), equals('left'));
    });

    test('handedness change in Settings moves the side and uses that side\'s saved fraction', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final quickNotifier = container.read(quickButtonProvider.notifier);
      final settingsNotifier = container.read(settingsProvider.notifier);

      // Save custom positions for right and left
      await quickNotifier.setPosition(HandednessSide.right, 0.30);
      await quickNotifier.setPosition(HandednessSide.left, 0.80);

      // Change Handedness in Settings to Left (changed from initial Right)
      await settingsNotifier.setHandedness(Handedness.left);

      // Side should move to left and use left's saved fraction 0.80
      final stateLeft = container.read(quickButtonProvider);
      expect(stateLeft.side, equals(HandednessSide.left));
      expect(stateLeft.currentDy, equals(0.80));

      // Change Handedness in Settings to Right (changed from Left)
      await settingsNotifier.setHandedness(Handedness.right);

      // Side should move to right and use right's saved fraction 0.30
      final stateRight = container.read(quickButtonProvider);
      expect(stateRight.side, equals(HandednessSide.right));
      expect(stateRight.currentDy, equals(0.30));
    });

    test('reset restores defaults (side from handedness, 0.65 for both)', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final quickNotifier = container.read(quickButtonProvider.notifier);
      await quickNotifier.setPosition(HandednessSide.left, 0.20);
      await quickNotifier.setPosition(HandednessSide.right, 0.90);

      // Reset
      await quickNotifier.reset();

      final state = container.read(quickButtonProvider);
      expect(state.side, equals(HandednessSide.right)); // default handedness is right
      expect(state.dyRight, equals(0.65));
      expect(state.dyLeft, equals(0.65));
      expect(prefs.getDouble('quick_dy_right'), equals(0.65));
      expect(prefs.getDouble('quick_dy_left'), equals(0.65));
      expect(prefs.getString('quick_side'), equals('right'));
    });
  });
}
