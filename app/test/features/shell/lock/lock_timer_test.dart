import 'package:flutter_test/flutter_test.dart';
import 'package:ed_companion/features/shell/lock/lock_timer.dart';

void main() {
  group('shouldLock', () {
    final baseTime = DateTime(2026, 10, 15, 12, 0, 0);

    test('returns false when backgroundedAt is null', () {
      expect(shouldLock(baseTime, null, AutoLockTimeout.immediately), isFalse);
      expect(shouldLock(baseTime, null, AutoLockTimeout.fiveMinutes), isFalse);
    });

    test('returns false if now is before backgroundedAt', () {
      final futureTime = baseTime.add(const Duration(minutes: 5));
      expect(shouldLock(baseTime, futureTime, AutoLockTimeout.fiveMinutes), isFalse);
    });

    test('handles AutoLockTimeout.immediately', () {
      expect(shouldLock(baseTime, baseTime, AutoLockTimeout.immediately), isTrue);
      expect(
        shouldLock(
          baseTime.add(const Duration(seconds: 1)),
          baseTime,
          AutoLockTimeout.immediately,
        ),
        isTrue,
      );
    });

    test('handles AutoLockTimeout.oneMinute (before, at limit, after)', () {
      const timeout = AutoLockTimeout.oneMinute;

      // Before limit (59 seconds)
      expect(shouldLock(baseTime.add(const Duration(seconds: 59)), baseTime, timeout), isFalse);

      // Exactly at limit (60 seconds)
      expect(shouldLock(baseTime.add(const Duration(minutes: 1)), baseTime, timeout), isTrue);

      // After limit (61 seconds)
      expect(shouldLock(baseTime.add(const Duration(seconds: 61)), baseTime, timeout), isTrue);
    });

    test('handles AutoLockTimeout.fiveMinutes (before, at limit, after)', () {
      const timeout = AutoLockTimeout.fiveMinutes;

      // Before limit (4 minutes 59 seconds)
      expect(
        shouldLock(baseTime.add(const Duration(minutes: 4, seconds: 59)), baseTime, timeout),
        isFalse,
      );

      // Exactly at limit (5 minutes)
      expect(shouldLock(baseTime.add(const Duration(minutes: 5)), baseTime, timeout), isTrue);

      // After limit (5 minutes 1 second)
      expect(
        shouldLock(baseTime.add(const Duration(minutes: 5, seconds: 1)), baseTime, timeout),
        isTrue,
      );
    });

    test('handles AutoLockTimeout.fifteenMinutes (before, at limit, after)', () {
      const timeout = AutoLockTimeout.fifteenMinutes;

      // Before limit (14 minutes 59 seconds)
      expect(
        shouldLock(baseTime.add(const Duration(minutes: 14, seconds: 59)), baseTime, timeout),
        isFalse,
      );

      // Exactly at limit (15 minutes)
      expect(shouldLock(baseTime.add(const Duration(minutes: 15)), baseTime, timeout), isTrue);

      // After limit (15 minutes 1 second)
      expect(
        shouldLock(baseTime.add(const Duration(minutes: 15, seconds: 1)), baseTime, timeout),
        isTrue,
      );
    });

    test('handles AutoLockTimeout.thirtyMinutes (before, at limit, after)', () {
      const timeout = AutoLockTimeout.thirtyMinutes;

      // Before limit (29 minutes 59 seconds)
      expect(
        shouldLock(baseTime.add(const Duration(minutes: 29, seconds: 59)), baseTime, timeout),
        isFalse,
      );

      // Exactly at limit (30 minutes)
      expect(shouldLock(baseTime.add(const Duration(minutes: 30)), baseTime, timeout), isTrue);

      // After limit (30 minutes 1 second)
      expect(
        shouldLock(baseTime.add(const Duration(minutes: 30, seconds: 1)), baseTime, timeout),
        isTrue,
      );
    });
  });
}
