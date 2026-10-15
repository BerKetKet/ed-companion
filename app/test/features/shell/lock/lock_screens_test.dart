import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ed_companion/features/shell/lock/lock_controller.dart';
import 'package:ed_companion/features/shell/lock/lock_mode.dart';
import 'package:ed_companion/features/shell/lock/lock_screen.dart';
import 'package:ed_companion/features/shell/lock/pin_hasher.dart';
import 'package:ed_companion/features/shell/lock/setup_pin_screen.dart';
import 'package:ed_companion/features/shell/settings_provider.dart';

class TestSecureStorage extends FlutterSecureStorage {
  final Map<String, String> data = {};

  TestSecureStorage([Map<String, String>? initial]) {
    if (initial != null) data.addAll(initial);
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      data[key] = value;
    } else {
      data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }
}

class TestLocalAuth extends LocalAuthentication {
  bool isSupported;

  TestLocalAuth({this.isSupported = true});

  @override
  Future<bool> get canCheckBiometrics async => false;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => const [];

  @override
  Future<bool> isDeviceSupported() async => isSupported;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SetupPinScreen', () {
    testWidgets('shows "Choose a different lock type" when screen cannot pop, tapping it clears lock mode', (tester) async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();

      final storage = TestSecureStorage();
      final localAuth = TestLocalAuth();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(storage),
          localAuthProvider.overrideWithValue(localAuth),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SetupPinScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chooseTypeFinder = find.text('Choose a different lock type');
      expect(chooseTypeFinder, findsOneWidget);

      await tester.tap(chooseTypeFinder);
      await tester.pumpAndSettle();

      expect(container.read(lockControllerProvider).lockMode, isNull);
      expect(prefs.containsKey('lock_mode'), isFalse);
    });

    testWidgets('does not show "Choose a different lock type" when pushed from another route (can pop)', (tester) async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(TestSecureStorage()),
          localAuthProvider.overrideWithValue(TestLocalAuth()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SetupPinScreen()),
                    );
                  },
                  child: const Text('Open Setup'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Setup'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a different lock type'), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);
    });
  });

  group('LockScreen', () {
    testWidgets('phoneLock mode with no device screen lock shows warning and switch to no lock button', (tester) async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'phoneLock'});
      final prefs = await SharedPreferences.getInstance();

      final localAuth = TestLocalAuth(isSupported: false);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(TestSecureStorage()),
          localAuthProvider.overrideWithValue(localAuth),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LockScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This phone no longer has a screen lock. Set one in Android settings, or switch to No lock.'),
        findsOneWidget,
      );
      final switchBtn = find.text('Switch to No lock');
      expect(switchBtn, findsOneWidget);

      await tester.tap(switchBtn);
      await tester.pumpAndSettle();

      expect(container.read(lockControllerProvider).lockMode, equals(LockMode.none));
    });

    testWidgets('appPin with 4-digit PIN: 5 wrong attempts starts lockout, correct PIN unlocks', (tester) async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();

      const hasher = PinHasher();
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('1234', salt);

      final storage = TestSecureStorage({
        'pin_credential': jsonEncode({'hash': hash, 'salt': salt, 'len': 4}),
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(storage),
          localAuthProvider.overrideWithValue(TestLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LockScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter wrong 4-digit PIN 4 times
      for (int attempt = 0; attempt < 4; attempt++) {
        for (final digit in ['9', '9', '9', '9']) {
          await tester.tap(find.text(digit));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(container.read(lockControllerProvider).failedAttempts, equals(attempt + 1));
        expect(find.text('Incorrect PIN'), findsOneWidget);
      }

      // 5th wrong attempt triggers lockout
      for (final digit in ['9', '9', '9', '9']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final state = container.read(lockControllerProvider);
      expect(state.failedAttempts, equals(5));
      expect(state.isLockedOut, isTrue);
      expect(find.textContaining('Too many attempts'), findsOneWidget);

      // Fast forward past the 30-second lockout timer
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(container.read(lockControllerProvider).isLockedOut, isFalse);

      // Now enter correct PIN: unlocks as soon as last digit is typed
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(container.read(lockControllerProvider).isLocked, isFalse);
    });

    testWidgets('appPin with 6-digit PIN: 4 digits do not auto-verify, cannot enter 7th digit', (tester) async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();

      const hasher = PinHasher();
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('123456', salt);

      final storage = TestSecureStorage({
        'pin_credential': jsonEncode({'hash': hash, 'salt': salt, 'len': 6}),
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(storage),
          localAuthProvider.overrideWithValue(TestLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LockScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type 4 digits: should NOT auto-verify
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // No error message and 0 failed attempts
      expect(find.text('Incorrect PIN'), findsNothing);
      expect(container.read(lockControllerProvider).failedAttempts, equals(0));

      // Enter button is visible; tapping it verifies early and counts as failure
      final enterFinder = find.byTooltip('Enter');
      expect(enterFinder, findsOneWidget);
      await tester.tap(enterFinder);
      await tester.pumpAndSettle();

      expect(container.read(lockControllerProvider).failedAttempts, equals(1));
      expect(find.text('Incorrect PIN'), findsOneWidget);

      // Now type 6 digits
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Correct PIN unlocks immediately
      expect(container.read(lockControllerProvider).isLocked, isFalse);
    });
  });
}
