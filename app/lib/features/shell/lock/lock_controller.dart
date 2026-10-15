import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../settings_provider.dart';
import 'lock_mode.dart';
import 'pin_hasher.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// State of security lock mode, PIN, attempts, and biometric flags.
class AppLockState {
  final bool isInitialized;
  final LockMode? lockMode;
  final bool hasPin;
  final int? pinLength;
  final bool isLocked;
  final int failedAttempts;
  final int lockoutRemainingSeconds;
  final bool biometricsSupported;
  final bool phoneLockSupported;
  final bool authenticating;

  const AppLockState({
    required this.isInitialized,
    required this.lockMode,
    required this.hasPin,
    this.pinLength,
    required this.isLocked,
    required this.failedAttempts,
    required this.lockoutRemainingSeconds,
    required this.biometricsSupported,
    required this.phoneLockSupported,
    required this.authenticating,
  });

  bool get isLockedOut => lockoutRemainingSeconds > 0;

  AppLockState copyWith({
    bool? isInitialized,
    LockMode? lockMode,
    bool clearLockMode = false,
    bool? hasPin,
    int? pinLength,
    bool clearPinLength = false,
    bool? isLocked,
    int? failedAttempts,
    int? lockoutRemainingSeconds,
    bool? biometricsSupported,
    bool? phoneLockSupported,
    bool? authenticating,
  }) {
    return AppLockState(
      isInitialized: isInitialized ?? this.isInitialized,
      lockMode: clearLockMode ? null : (lockMode ?? this.lockMode),
      hasPin: hasPin ?? this.hasPin,
      pinLength: clearPinLength ? null : (pinLength ?? this.pinLength),
      isLocked: isLocked ?? this.isLocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutRemainingSeconds: lockoutRemainingSeconds ?? this.lockoutRemainingSeconds,
      biometricsSupported: biometricsSupported ?? this.biometricsSupported,
      phoneLockSupported: phoneLockSupported ?? this.phoneLockSupported,
      authenticating: authenticating ?? this.authenticating,
    );
  }
}

class StoredCredential {
  final String hash;
  final String salt;
  final int? len;

  const StoredCredential({
    required this.hash,
    required this.salt,
    this.len,
  });
}

class LockController extends Notifier<AppLockState> {
  static const keyLockMode = 'lock_mode';
  static const keyPinCredential = 'pin_credential';
  static const keyLegacyPinHash = 'pin_hash';
  static const keyLegacyPinSalt = 'pin_salt';
  static const keyFailedAttempts = 'lock_failed_attempts';
  static const keyLockoutUntil = 'lock_lockout_until';

  static const _hasher = PinHasher();
  Timer? _lockoutTimer;

  @override
  AppLockState build() {
    ref.onDispose(() {
      _lockoutTimer?.cancel();
    });

    return const AppLockState(
      isInitialized: false,
      lockMode: null,
      hasPin: false,
      pinLength: null,
      isLocked: true,
      failedAttempts: 0,
      lockoutRemainingSeconds: 0,
      biometricsSupported: false,
      phoneLockSupported: false,
      authenticating: false,
    );
  }

  /// Reads stored credential pairs supporting both new single-key JSON and legacy 2-key storage.
  Future<StoredCredential?> _readCredential(FlutterSecureStorage storage) async {
    final rawJson = await storage.read(key: keyPinCredential);
    if (rawJson != null) {
      try {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        final hash = decoded['hash'] as String?;
        final salt = decoded['salt'] as String?;
        final len = decoded['len'] as int?;
        if (hash != null && salt != null) {
          return StoredCredential(hash: hash, salt: salt, len: len);
        }
      } catch (_) {}
    }

    // Check legacy keys for migration
    final legacyHash = await storage.read(key: keyLegacyPinHash);
    final legacySalt = await storage.read(key: keyLegacyPinSalt);
    if (legacyHash != null && legacySalt != null) {
      // Migrate to single-key format (without len initially)
      final pair = {'hash': legacyHash, 'salt': legacySalt};
      await storage.write(key: keyPinCredential, value: jsonEncode(pair));
      await storage.delete(key: keyLegacyPinHash);
      await storage.delete(key: keyLegacyPinSalt);
      return StoredCredential(hash: legacyHash, salt: legacySalt, len: null);
    }

    return null;
  }

  Future<void> initialize() async {
    final storage = ref.read(secureStorageProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final localAuth = ref.read(localAuthProvider);

    final cred = await _readCredential(storage);
    final hasPin = cred != null;
    final int? pinLength = cred?.len;

    // Check LockMode and migration
    final storedModeStr = prefs.getString(keyLockMode);
    LockMode? resolvedMode = LockMode.fromString(storedModeStr);

    if (storedModeStr == null) {
      if (hasPin) {
        // Migration: PIN exists but lock_mode unset -> treat as appPin and save
        resolvedMode = LockMode.appPin;
        await prefs.setString(keyLockMode, LockMode.appPin.name);
      } else {
        // First launch: mode unset
        resolvedMode = null;
      }
    }

    // Check device support for biometrics and phone lock
    bool biometrics = false;
    bool phoneLock = false;
    try {
      final canCheck = await localAuth.canCheckBiometrics;
      final available = await localAuth.getAvailableBiometrics();
      biometrics = canCheck && available.isNotEmpty;

      phoneLock = await localAuth.isDeviceSupported();
    } catch (_) {
      biometrics = false;
      phoneLock = false;
    }

    // Cold start rule:
    // appPin or phoneLock are always locked on cold start.
    // none is never locked.
    final bool startLocked = resolvedMode != LockMode.none;

    // Check persisted lockout state
    int failedAttempts = 0;
    int remainingSeconds = 0;
    final storedAttemptsStr = await storage.read(key: keyFailedAttempts);
    if (storedAttemptsStr != null) {
      failedAttempts = int.tryParse(storedAttemptsStr) ?? 0;
    }

    final lockoutUntilStr = await storage.read(key: keyLockoutUntil);
    if (lockoutUntilStr != null) {
      final lockoutUntil = DateTime.tryParse(lockoutUntilStr);
      if (lockoutUntil != null) {
        final diff = lockoutUntil.difference(DateTime.now()).inSeconds;
        if (diff > 0) {
          remainingSeconds = diff;
          _startCountdown(diff);
        } else {
          // Lockout expired while app was closed
          await _clearLockoutState(storage);
          failedAttempts = 0;
        }
      }
    }

    state = AppLockState(
      isInitialized: true,
      lockMode: resolvedMode,
      hasPin: hasPin,
      pinLength: pinLength,
      isLocked: startLocked,
      failedAttempts: failedAttempts,
      lockoutRemainingSeconds: remainingSeconds,
      biometricsSupported: biometrics,
      phoneLockSupported: phoneLock,
      authenticating: false,
    );
  }

  Future<void> clearLockMode() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(keyLockMode);
    state = state.copyWith(clearLockMode: true);
  }

  Future<void> setLockMode(LockMode mode, {bool unlock = false}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(keyLockMode, mode.name);

    final bool newLocked = (mode == LockMode.none || unlock) ? false : state.isLocked;

    state = state.copyWith(
      lockMode: mode,
      isLocked: newLocked,
      failedAttempts: unlock ? 0 : state.failedAttempts,
      lockoutRemainingSeconds: unlock ? 0 : state.lockoutRemainingSeconds,
    );
  }

  Future<bool> refreshDeviceSupport() async {
    final localAuth = ref.read(localAuthProvider);
    bool supported = false;
    try {
      supported = await localAuth.isDeviceSupported();
    } catch (_) {
      supported = false;
    }
    state = state.copyWith(phoneLockSupported: supported);
    return supported;
  }

  Future<void> setPin(String newPin) async {
    _lockoutTimer?.cancel();
    final storage = ref.read(secureStorageProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    final salt = _hasher.generateSalt();
    final hash = _hasher.hashPin(newPin, salt);
    final payload = jsonEncode({
      'hash': hash,
      'salt': salt,
      'len': newPin.length,
    });

    // Write hash, salt and len as one atomic JSON value
    await storage.write(key: keyPinCredential, value: payload);
    await storage.delete(key: keyLegacyPinHash);
    await storage.delete(key: keyLegacyPinSalt);

    await _clearLockoutState(storage);

    // Saving PIN also ensures lock_mode is appPin
    await prefs.setString(keyLockMode, LockMode.appPin.name);

    state = state.copyWith(
      lockMode: LockMode.appPin,
      hasPin: true,
      pinLength: newPin.length,
      isLocked: false,
      failedAttempts: 0,
      lockoutRemainingSeconds: 0,
    );
  }

  Future<void> deletePin() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: keyPinCredential);
    await storage.delete(key: keyLegacyPinHash);
    await storage.delete(key: keyLegacyPinSalt);
    await _clearLockoutState(storage);

    state = state.copyWith(
      hasPin: false,
      clearPinLength: true,
      failedAttempts: 0,
      lockoutRemainingSeconds: 0,
    );
  }

  Future<bool> verifyAndUnlock(String enteredPin) async {
    if (state.isLockedOut) {
      return false;
    }

    final storage = ref.read(secureStorageProvider);
    final cred = await _readCredential(storage);
    if (cred == null) {
      return false;
    }

    final isValid = _hasher.verifyPin(enteredPin, cred.salt, cred.hash);
    if (isValid) {
      await _handleSuccessUnlock(
        storage,
        cred: cred,
        enteredLength: enteredPin.length,
      );
      return true;
    } else {
      await _handleFailedAttempt(storage);
      return false;
    }
  }

  /// Verifies current PIN, counting wrong attempts and respecting lockout.
  Future<bool> verifyCurrentPin(String currentPin) async {
    if (state.isLockedOut) {
      return false;
    }

    final storage = ref.read(secureStorageProvider);
    final cred = await _readCredential(storage);
    if (cred == null) {
      return false;
    }

    final isValid = _hasher.verifyPin(currentPin, cred.salt, cred.hash);
    if (isValid) {
      await _handleSuccessUnlock(
        storage,
        cred: cred,
        enteredLength: currentPin.length,
      );
      return true;
    } else {
      await _handleFailedAttempt(storage);
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (state.isLockedOut || !state.hasPin || state.authenticating) {
      return false;
    }

    state = state.copyWith(authenticating: true);
    final localAuth = ref.read(localAuthProvider);
    final storage = ref.read(secureStorageProvider);

    try {
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Unlock ED Companion',
        biometricOnly: true,
      );

      if (authenticated) {
        final cred = await _readCredential(storage);
        await _handleSuccessUnlock(storage, cred: cred);
        return true;
      }
    } catch (_) {
      // Biometric failure falls back to keypad
    } finally {
      state = state.copyWith(authenticating: false);
    }
    return false;
  }

  Future<bool> authenticateWithPhoneLock() async {
    if (state.authenticating) {
      return false;
    }

    state = state.copyWith(authenticating: true);
    final localAuth = ref.read(localAuthProvider);

    try {
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Unlock ED Companion',
        biometricOnly: false,
      );

      if (authenticated) {
        state = state.copyWith(
          isLocked: false,
          failedAttempts: 0,
          lockoutRemainingSeconds: 0,
        );
        return true;
      }
    } catch (_) {
      // Dismissed or failed leaves Unlock button visible
    } finally {
      state = state.copyWith(authenticating: false);
    }
    return false;
  }

  void lock() {
    if (state.lockMode == LockMode.appPin || state.lockMode == LockMode.phoneLock) {
      state = state.copyWith(isLocked: true);
    }
  }

  void unlock() {
    state = state.copyWith(
      isLocked: false,
      failedAttempts: 0,
      lockoutRemainingSeconds: 0,
    );
  }

  Future<void> _handleSuccessUnlock(
    FlutterSecureStorage storage, {
    StoredCredential? cred,
    int enteredLength = 0,
  }) async {
    _lockoutTimer?.cancel();
    await _clearLockoutState(storage);

    int? newPinLength = state.pinLength;
    if (cred != null) {
      if (cred.len == null && enteredLength > 0) {
        // Upgrade legacy credential to include len
        final upgraded = jsonEncode({
          'hash': cred.hash,
          'salt': cred.salt,
          'len': enteredLength,
        });
        await storage.write(key: keyPinCredential, value: upgraded);
        newPinLength = enteredLength;
      } else {
        newPinLength = cred.len ?? state.pinLength;
      }
    }

    state = state.copyWith(
      isLocked: false,
      pinLength: newPinLength,
      failedAttempts: 0,
      lockoutRemainingSeconds: 0,
    );
  }

  Future<void> _handleFailedAttempt(FlutterSecureStorage storage) async {
    final newAttempts = state.failedAttempts + 1;
    if (newAttempts >= 5) {
      final lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
      await storage.write(key: keyFailedAttempts, value: '5');
      await storage.write(key: keyLockoutUntil, value: lockoutUntil.toIso8601String());

      state = state.copyWith(
        failedAttempts: 5,
        lockoutRemainingSeconds: 30,
      );
      _startCountdown(30);
    } else {
      await storage.write(key: keyFailedAttempts, value: '$newAttempts');
      state = state.copyWith(failedAttempts: newAttempts);
    }
  }

  Future<void> _clearLockoutState(FlutterSecureStorage storage) async {
    _lockoutTimer?.cancel();
    await storage.delete(key: keyFailedAttempts);
    await storage.delete(key: keyLockoutUntil);
  }

  void _startCountdown(int seconds) {
    _lockoutTimer?.cancel();
    state = state.copyWith(lockoutRemainingSeconds: seconds);

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.lockoutRemainingSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        final storage = ref.read(secureStorageProvider);
        _clearLockoutState(storage);
        state = state.copyWith(
          failedAttempts: 0,
          lockoutRemainingSeconds: 0,
        );
      } else {
        state = state.copyWith(lockoutRemainingSeconds: remaining);
      }
    });
  }
}

final lockControllerProvider = NotifierProvider<LockController, AppLockState>(
  LockController.new,
);
