import 'package:flutter_test/flutter_test.dart';
import 'package:ed_companion/features/shell/chrome/scroll_tracker.dart';

void main() {
  group('ScrollDirectionTracker', () {
    late ScrollDirectionTracker tracker;

    setUp(() {
      tracker = ScrollDirectionTracker();
    });

    test('pixels <= 0 returns true (top of list)', () {
      expect(tracker.update(0.0, 0.0), isTrue);
      expect(tracker.update(10.0, 0.0), isTrue);
      expect(tracker.update(-5.0, -10.0), isTrue);
    });

    test('accumulated downward scrolling >= 24 dp while pixels > 56 returns false', () {
      // Below 56: scrolling downward should not hide
      expect(tracker.update(15.0, 30.0), isNull);
      expect(tracker.update(15.0, 45.0), isNull);

      // Above 56: start accumulating downward scrolling
      expect(tracker.update(10.0, 60.0), isNull); // 10 dp
      expect(tracker.update(10.0, 70.0), isNull); // 20 dp
      expect(tracker.update(5.0, 75.0), isFalse); // 25 dp >= 24 dp -> returns false (hide)
    });

    test('accumulated upward scrolling >= 12 dp returns true', () {
      // User is down the list at pixels = 200
      expect(tracker.update(-6.0, 194.0), isNull); // 6 dp upward
      expect(tracker.update(-7.0, 187.0), isTrue); // 13 dp upward >= 12 dp -> returns true (show)
    });

    test('direction change resets accumulators', () {
      // Scroll down 20 dp while pixels > 56 (not enough to trigger 24 dp)
      expect(tracker.update(20.0, 80.0), isNull);

      // Reverse direction: scroll up 5 dp (less than 12 dp)
      // This should reset the downward accumulator
      expect(tracker.update(-5.0, 75.0), isNull);

      // Scroll down again: should start from 0 downward accumulation
      expect(tracker.update(10.0, 85.0), isNull); // 10 dp
      expect(tracker.update(10.0, 95.0), isNull); // 20 dp
      expect(tracker.update(3.0, 98.0), isNull); // 23 dp < 24 dp
      expect(tracker.update(2.0, 100.0), isFalse); // 25 dp >= 24 dp -> returns false
    });

    test('top of list resets accumulators and returns true', () {
      // Accumulate 20 dp downward at pixels > 56
      expect(tracker.update(20.0, 80.0), isNull);

      // User jumps to top of list
      expect(tracker.update(-80.0, 0.0), isTrue);

      // Scrolling down from near top: accumulator was reset
      expect(tracker.update(10.0, 60.0), isNull);
      expect(tracker.update(10.0, 70.0), isNull);
      expect(tracker.update(5.0, 75.0), isFalse); // 25 dp >= 24 dp
    });
  });
}
