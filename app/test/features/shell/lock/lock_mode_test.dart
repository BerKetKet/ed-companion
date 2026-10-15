import 'package:flutter_test/flutter_test.dart';
import 'package:ed_companion/features/shell/lock/lock_mode.dart';

void main() {
  group('resolveLockRoute', () {
    test('redirects to /choose-lock when mode is null', () {
      expect(
        resolveLockRoute(
          mode: null,
          hasPin: false,
          isLocked: false,
          location: '/work',
        ),
        equals('/choose-lock'),
      );
      expect(
        resolveLockRoute(
          mode: null,
          hasPin: false,
          isLocked: true,
          location: '/settings',
        ),
        equals('/choose-lock'),
      );
      expect(
        resolveLockRoute(
          mode: null,
          hasPin: false,
          isLocked: false,
          location: '/choose-lock',
        ),
        isNull,
      );
    });

    test('appPin mode without PIN redirects to /setup-pin', () {
      expect(
        resolveLockRoute(
          mode: LockMode.appPin,
          hasPin: false,
          isLocked: false,
          location: '/work',
        ),
        equals('/setup-pin'),
      );
      expect(
        resolveLockRoute(
          mode: LockMode.appPin,
          hasPin: false,
          isLocked: false,
          location: '/setup-pin',
        ),
        isNull,
      );
    });

    test('appPin mode with PIN locked redirects to /lock', () {
      expect(
        resolveLockRoute(
          mode: LockMode.appPin,
          hasPin: true,
          isLocked: true,
          location: '/work',
        ),
        equals('/lock'),
      );
      expect(
        resolveLockRoute(
          mode: LockMode.appPin,
          hasPin: true,
          isLocked: true,
          location: '/lock',
        ),
        isNull,
      );
    });

    test('appPin mode with PIN unlocked redirects auth routes to /work', () {
      expect(
        resolveLockRoute(
          mode: LockMode.appPin,
          hasPin: true,
          isLocked: false,
          location: '/lock',
        ),
        equals('/work'),
      );
      expect(
        resolveLockRoute(
          mode: LockMode.appPin,
          hasPin: true,
          isLocked: false,
          location: '/setup-pin',
        ),
        equals('/work'),
      );
      expect(
        resolveLockRoute(
          mode: LockMode.appPin,
          hasPin: true,
          isLocked: false,
          location: '/choose-lock',
        ),
        equals('/work'),
      );
      expect(
        resolveLockRoute(
          mode: LockMode.appPin,
          hasPin: true,
          isLocked: false,
          location: '/work',
        ),
        isNull,
      );
      expect(
        resolveLockRoute(
          mode: LockMode.appPin,
          hasPin: true,
          isLocked: false,
          location: '/settings',
        ),
        isNull,
      );
    });

    test('phoneLock mode locked redirects to /lock', () {
      expect(
        resolveLockRoute(
          mode: LockMode.phoneLock,
          hasPin: false,
          isLocked: true,
          location: '/work',
        ),
        equals('/lock'),
      );
      expect(
        resolveLockRoute(
          mode: LockMode.phoneLock,
          hasPin: false,
          isLocked: true,
          location: '/lock',
        ),
        isNull,
      );
    });

    test('phoneLock mode unlocked redirects auth routes to /work', () {
      expect(
        resolveLockRoute(
          mode: LockMode.phoneLock,
          hasPin: false,
          isLocked: false,
          location: '/lock',
        ),
        equals('/work'),
      );
      expect(
        resolveLockRoute(
          mode: LockMode.phoneLock,
          hasPin: false,
          isLocked: false,
          location: '/work',
        ),
        isNull,
      );
    });

    test('none mode never goes to /lock and redirects auth routes to /work', () {
      expect(
        resolveLockRoute(
          mode: LockMode.none,
          hasPin: false,
          isLocked: false,
          location: '/lock',
        ),
        equals('/work'),
      );
      expect(
        resolveLockRoute(
          mode: LockMode.none,
          hasPin: false,
          isLocked: true,
          location: '/lock',
        ),
        equals('/work'),
      );
      expect(
        resolveLockRoute(
          mode: LockMode.none,
          hasPin: false,
          isLocked: false,
          location: '/work',
        ),
        isNull,
      );
      expect(
        resolveLockRoute(
          mode: LockMode.none,
          hasPin: false,
          isLocked: false,
          location: '/settings',
        ),
        isNull,
      );
      expect(
        resolveLockRoute(
          mode: LockMode.none,
          hasPin: false,
          isLocked: false,
          location: '/setup-pin',
        ),
        isNull,
      );
      expect(
        resolveLockRoute(
          mode: LockMode.none,
          hasPin: true,
          isLocked: false,
          location: '/setup-pin',
        ),
        equals('/work'),
      );
    });

    test('phoneLock mode allows setup-pin when user has no PIN, redirects when user has PIN', () {
      expect(
        resolveLockRoute(
          mode: LockMode.phoneLock,
          hasPin: false,
          isLocked: false,
          location: '/setup-pin',
        ),
        isNull,
      );
      expect(
        resolveLockRoute(
          mode: LockMode.phoneLock,
          hasPin: true,
          isLocked: false,
          location: '/setup-pin',
        ),
        equals('/work'),
      );
    });
  });
}
