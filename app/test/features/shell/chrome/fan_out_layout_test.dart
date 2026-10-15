import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:ed_companion/core/handedness.dart';
import 'package:ed_companion/features/shell/chrome/quick_button_provider.dart';

void main() {
  group('computeFanOutOffset pure layout function', () {
    test('right side and upward direction', () {
      for (int i = 0; i < 6; i++) {
        final offset = computeFanOutOffset(
          side: HandednessSide.right,
          direction: FanOutDirection.upward,
          index: i,
        );

        // Vertical step is upward (-60 * (i + 1))
        expect(offset.dy, equals(-(i + 1) * 60.0));

        // Horizontal curve is shifted toward center (leftwards, negative dx)
        final expectedCurve = 24.0 * math.sin(math.pi * i / 5.0);
        expect(offset.dx, closeTo(-expectedCurve, 0.001));
      }

      // Specific values:
      // i = 0: sin(0) = 0 -> dx = 0, dy = -60
      expect(
        computeFanOutOffset(
          side: HandednessSide.right,
          direction: FanOutDirection.upward,
          index: 0,
        ),
        equals(const Offset(0.0, -60.0)),
      );

      // i = 5: sin(pi) = 0 -> dx = 0, dy = -360
      final offset5 = computeFanOutOffset(
        side: HandednessSide.right,
        direction: FanOutDirection.upward,
        index: 5,
      );
      expect(offset5.dx, closeTo(0.0, 0.001));
      expect(offset5.dy, equals(-360.0));
    });

    test('left side and upward direction', () {
      for (int i = 0; i < 6; i++) {
        final offset = computeFanOutOffset(
          side: HandednessSide.left,
          direction: FanOutDirection.upward,
          index: i,
        );

        expect(offset.dy, equals(-(i + 1) * 60.0));

        // Horizontal curve shifted toward center (rightwards, positive dx)
        final expectedCurve = 24.0 * math.sin(math.pi * i / 5.0);
        expect(offset.dx, closeTo(expectedCurve, 0.001));
      }
    });

    test('right side and downward direction', () {
      for (int i = 0; i < 6; i++) {
        final offset = computeFanOutOffset(
          side: HandednessSide.right,
          direction: FanOutDirection.downward,
          index: i,
        );

        // Downward vertical step (+60 * (i + 1))
        expect(offset.dy, equals((i + 1) * 60.0));

        // Shifted toward center (negative dx)
        final expectedCurve = 24.0 * math.sin(math.pi * i / 5.0);
        expect(offset.dx, closeTo(-expectedCurve, 0.001));
      }
    });

    test('left side and downward direction', () {
      for (int i = 0; i < 6; i++) {
        final offset = computeFanOutOffset(
          side: HandednessSide.left,
          direction: FanOutDirection.downward,
          index: i,
        );

        expect(offset.dy, equals((i + 1) * 60.0));

        // Shifted toward center (positive dx)
        final expectedCurve = 24.0 * math.sin(math.pi * i / 5.0);
        expect(offset.dx, closeTo(expectedCurve, 0.001));
      }
    });
  });
}
