import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ed_companion/features/shell/lock/lock_controller.dart';
import 'package:ed_companion/features/shell/lock/lock_mode.dart';
import 'package:ed_companion/features/shell/lock/pin_hasher.dart';
import 'package:ed_companion/features/shell/settings_provider.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> data = {};

  FakeSecureStorage([Map<String, String>? initial]) {
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

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map<String, String>.from(data);
  }
}

class FakeLocalAuth extends LocalAuthentication {
  bool canCheck;
  List<BiometricType> biometrics;
  bool isSupported;

  FakeLocalAuth({
    this.canCheck = false,
    this.biometrics = const [],
    this.isSupported = false,
  });

  @override
  Future<bool> get canCheckBiometrics async => canCheck;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => biometrics;

  @override
  Future<bool> isDeviceSupported() async => isSupported;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LockController', () {
    test('LockMode migration: PIN exists, mode unset gives appPin and saves it', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const hasher = PinHasher();
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('1234', salt);

      // Legacy 2-key storage
      final fakeStorage = FakeSecureStorage({
        'pin_hash': hash,
        'pin_salt': salt,
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      final state = container.read(lockControllerProvider);
      expect(state.lockMode, equals(LockMode.appPin));
      expect(state.hasPin, isTrue);
      expect(prefs.getString('lock_mode'), equals('appPin'));

      // Check migration to single-key JSON
      expect(fakeStorage.data.containsKey('pin_credential'), isTrue);
      expect(fakeStorage.data.containsKey('pin_hash'), isFalse);
      expect(fakeStorage.data.containsKey('pin_salt'), isFalse);

      final cred = jsonDecode(fakeStorage.data['pin_credential']!) as Map<String, dynamic>;
      expect(cred['hash'], equals(hash));
      expect(cred['salt'], equals(salt));
    });

    test('first launch: no PIN and mode unset gives null lockMode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeStorage = FakeSecureStorage();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      final state = container.read(lockControllerProvider);
      expect(state.lockMode, isNull);
      expect(state.hasPin, isFalse);
    });

    test('lockout persistence: 5 wrong attempts persist and resume on new controller', () async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();

      const hasher = PinHasher();
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('1234', salt);

      final fakeStorage = FakeSecureStorage({
        'pin_credential': jsonEncode({'hash': hash, 'salt': salt}),
      });

      final container1 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller1 = container1.read(lockControllerProvider.notifier);
      await controller1.initialize();

      // Enter 4 wrong PINs
      for (int i = 0; i < 4; i++) {
        final ok = await controller1.verifyAndUnlock('0000');
        expect(ok, isFalse);
        expect(container1.read(lockControllerProvider).failedAttempts, equals(i + 1));
        expect(container1.read(lockControllerProvider).isLockedOut, isFalse);
      }

      // 5th wrong attempt triggers 30s lockout
      final ok5 = await controller1.verifyAndUnlock('0000');
      expect(ok5, isFalse);
      final state1 = container1.read(lockControllerProvider);
      expect(state1.failedAttempts, equals(5));
      expect(state1.isLockedOut, isTrue);
      expect(state1.lockoutRemainingSeconds, equals(30));

      // Verify stored in secure storage
      expect(fakeStorage.data['lock_failed_attempts'], equals('5'));
      expect(fakeStorage.data.containsKey('lock_lockout_until'), isTrue);

      // Simulate app restart before lockout ends
      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );
      final controller2 = container2.read(lockControllerProvider.notifier);
      await controller2.initialize();

      final state2 = container2.read(lockControllerProvider);
      expect(state2.isLockedOut, isTrue);
      expect(state2.lockoutRemainingSeconds, inInclusiveRange(28, 30));

      // Simulate app restart after lockout ends
      final pastTime = DateTime.now().subtract(const Duration(seconds: 5));
      fakeStorage.data['lock_lockout_until'] = pastTime.toIso8601String();

      final container3 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );
      final controller3 = container3.read(lockControllerProvider.notifier);
      await controller3.initialize();

      final state3 = container3.read(lockControllerProvider);
      expect(state3.isLockedOut, isFalse);
      expect(state3.failedAttempts, equals(0));
      expect(fakeStorage.data.containsKey('lock_lockout_until'), isFalse);
      expect(fakeStorage.data.containsKey('lock_failed_attempts'), isFalse);
    });

    test('wrong attempts through verifyCurrentPin count toward the limit', () async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();

      const hasher = PinHasher();
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('1234', salt);

      final fakeStorage = FakeSecureStorage({
        'pin_credential': jsonEncode({'hash': hash, 'salt': salt}),
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      for (int i = 0; i < 5; i++) {
        final ok = await controller.verifyCurrentPin('9999');
        expect(ok, isFalse);
      }

      final state = container.read(lockControllerProvider);
      expect(state.failedAttempts, equals(5));
      expect(state.isLockedOut, isTrue);
      expect(state.lockoutRemainingSeconds, equals(30));

      // Once locked out, further verifyCurrentPin calls return false immediately
      final okAfterLockout = await controller.verifyCurrentPin('1234');
      expect(okAfterLockout, isFalse);
    });

    test('biometricsSupported is true only if canCheckBiometrics AND available is not empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Case 1: canCheck true but empty available
      final container1 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localAuthProvider.overrideWithValue(FakeLocalAuth(
            canCheck: true,
            biometrics: const [],
          )),
        ],
      );
      await container1.read(lockControllerProvider.notifier).initialize();
      expect(container1.read(lockControllerProvider).biometricsSupported, isFalse);

      // Case 2: canCheck true and non-empty available
      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localAuthProvider.overrideWithValue(FakeLocalAuth(
            canCheck: true,
            biometrics: const [BiometricType.fingerprint],
          )),
        ],
      );
      await container2.read(lockControllerProvider.notifier).initialize();
      expect(container2.read(lockControllerProvider).biometricsSupported, isTrue);
    });

    test('setPin cancels running lockout timer and writes hash and salt as one atomic JSON value', () async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();
      final fakeStorage = FakeSecureStorage({
        'lock_failed_attempts': '5',
        'lock_lockout_until': DateTime.now().add(const Duration(seconds: 30)).toIso8601String(),
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();
      expect(container.read(lockControllerProvider).isLockedOut, isTrue);

      // Calling setPin clears lockout and sets new atomic credential
      await controller.setPin('5678');

      final state = container.read(lockControllerProvider);
      expect(state.hasPin, isTrue);
      expect(state.isLockedOut, isFalse);
      expect(state.failedAttempts, equals(0));
      expect(state.lockoutRemainingSeconds, equals(0));
      expect(fakeStorage.data.containsKey('lock_failed_attempts'), isFalse);
      expect(fakeStorage.data.containsKey('lock_lockout_until'), isFalse);

      final credJson = fakeStorage.data['pin_credential'];
      expect(credJson, isNotNull);
      final decoded = jsonDecode(credJson!) as Map<String, dynamic>;
      expect(decoded.containsKey('hash'), isTrue);
      expect(decoded.containsKey('salt'), isTrue);
    });

    test('deletePin removes credentials and clears lockout state', () async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();
      final fakeStorage = FakeSecureStorage({
        'pin_credential': jsonEncode({'hash': 'abc', 'salt': 'xyz'}),
        'lock_failed_attempts': '2',
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      await controller.deletePin();

      final state = container.read(lockControllerProvider);
      expect(state.hasPin, isFalse);
      expect(fakeStorage.data.containsKey('pin_credential'), isFalse);
    });

    test('Every wrong verifyAndUnlock and verifyCurrentPin counts toward the limit, for 4, 5 and 6 digit entries', () async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();

      const hasher = PinHasher();
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('123456', salt);

      // 6-digit PIN credential
      final fakeStorage = FakeSecureStorage({
        'pin_credential': jsonEncode({'hash': hash, 'salt': salt, 'len': 6}),
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      // Test verifyAndUnlock counts wrong attempts for 4, 5, 6 digit entries
      expect(await controller.verifyAndUnlock('0000'), isFalse); // 4-digit
      expect(container.read(lockControllerProvider).failedAttempts, equals(1));

      expect(await controller.verifyAndUnlock('00000'), isFalse); // 5-digit
      expect(container.read(lockControllerProvider).failedAttempts, equals(2));

      expect(await controller.verifyAndUnlock('000000'), isFalse); // 6-digit
      expect(container.read(lockControllerProvider).failedAttempts, equals(3));

      // Test verifyCurrentPin also counts wrong attempts for 4, 5 digit entries
      expect(await controller.verifyCurrentPin('1111'), isFalse); // 4-digit
      expect(container.read(lockControllerProvider).failedAttempts, equals(4));

      // 5th attempt with 5 digits triggers lockout
      expect(await controller.verifyCurrentPin('11111'), isFalse); // 5-digit
      final state = container.read(lockControllerProvider);
      expect(state.failedAttempts, equals(5));
      expect(state.isLockedOut, isTrue);
    });

    test('setPin stores len; a legacy credential without len is upgraded after a successful verify', () async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();

      final fakeStorage = FakeSecureStorage();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      // 1. setPin stores len in JSON and state
      await controller.setPin('12345');
      expect(container.read(lockControllerProvider).pinLength, equals(5));

      final storedJson = fakeStorage.data['pin_credential'];
      expect(storedJson, isNotNull);
      final decoded = jsonDecode(storedJson!) as Map<String, dynamic>;
      expect(decoded['len'], equals(5));

      // 2. Legacy credential without len in storage
      const hasher = PinHasher();
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('654321', salt);
      fakeStorage.data['pin_credential'] = jsonEncode({'hash': hash, 'salt': salt}); // no len

      final legacyContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(fakeStorage),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final legacyController = legacyContainer.read(lockControllerProvider.notifier);
      await legacyController.initialize();
      expect(legacyContainer.read(lockControllerProvider).pinLength, isNull);

      // Successful verify upgrades legacy credential with len = 6
      final ok = await legacyController.verifyAndUnlock('654321');
      expect(ok, isTrue);
      expect(legacyContainer.read(lockControllerProvider).pinLength, equals(6));

      final upgradedJson = fakeStorage.data['pin_credential'];
      final upgradedDecoded = jsonDecode(upgradedJson!) as Map<String, dynamic>;
      expect(upgradedDecoded['len'], equals(6));
    });

    test('phoneLockSupported is true when isDeviceSupported is true and there are no biometrics', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localAuthProvider.overrideWithValue(FakeLocalAuth(
            isSupported: true,
            canCheck: false,
            biometrics: const [],
          )),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();

      final state = container.read(lockControllerProvider);
      expect(state.phoneLockSupported, isTrue);
      expect(state.biometricsSupported, isFalse);
    });

    test('refreshDeviceSupport updates the state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeAuth = FakeLocalAuth(isSupported: true);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localAuthProvider.overrideWithValue(fakeAuth),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();
      expect(container.read(lockControllerProvider).phoneLockSupported, isTrue);

      // Simulate device lock removed
      fakeAuth.isSupported = false;
      final supported = await controller.refreshDeviceSupport();
      expect(supported, isFalse);
      expect(container.read(lockControllerProvider).phoneLockSupported, isFalse);
    });

    test('clearLockMode returns lockMode to null and resolveLockRoute then gives /choose-lock', () async {
      SharedPreferences.setMockInitialValues({'lock_mode': 'appPin'});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();
      expect(container.read(lockControllerProvider).lockMode, equals(LockMode.appPin));

      await controller.clearLockMode();

      final state = container.read(lockControllerProvider);
      expect(state.lockMode, isNull);
      expect(prefs.containsKey('lock_mode'), isFalse);

      final redirect = resolveLockRoute(
        mode: state.lockMode,
        hasPin: state.hasPin,
        isLocked: state.isLocked,
        location: '/work',
      );
      expect(redirect, equals('/choose-lock'));
    });

    test('setLockMode(phoneLock, unlock: true) leaves isLocked false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localAuthProvider.overrideWithValue(FakeLocalAuth()),
        ],
      );

      final controller = container.read(lockControllerProvider.notifier);
      await controller.initialize();
      expect(container.read(lockControllerProvider).isLocked, isTrue);

      await controller.setLockMode(LockMode.phoneLock, unlock: true);

      final state = container.read(lockControllerProvider);
      expect(state.lockMode, equals(LockMode.phoneLock));
      expect(state.isLocked, isFalse);
    });
  });
}
