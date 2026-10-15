import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'pin_hasher.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// State of PIN security, locks, and attempt counters.
class AppLockState {
  final bool isInitialized;
  final bool hasPin;
  final bool isLocked;
  final int failedAttempts;
  final int lockoutRemainingSeconds;
  final bool biometricsSupported;

  const AppLockState({
    required this.isInitialized,
    required this.hasPin,
    required this.isLocked,
    required this.failedAttempts,
    required this.lockoutRemainingSeconds,
    required this.biometricsSupported,
  });

  bool get isLockedOut => lockoutRemainingSeconds > 0;

  AppLockState copyWith({
    bool? isInitialized,
    bool? hasPin,
    bool? isLocked,
    int? failedAttempts,
    int? lockoutRemainingSeconds,
    bool? biometricsSupported,
  }) {
    return AppLockState(
      isInitialized: isInitialized ?? this.isInitialized,
      hasPin: hasPin ?? this.hasPin,
      isLocked: isLocked ?? this.isLocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutRemainingSeconds: lockoutRemainingSeconds ?? this.lockoutRemainingSeconds,
      biometricsSupported: biometricsSupported ?? this.biometricsSupported,
    );
  }
}

class LockController extends Notifier<AppLockState> {
  static const _keyPinHash = 'pin_hash';
  static const _keyPinSalt = 'pin_salt';

  static const _hasher = PinHasher();
  Timer? _lockoutTimer;

  @override
  AppLockState build() {
    ref.onDispose(() {
      _lockoutTimer?.cancel();
    });

    return const AppLockState(
      isInitialized: false,
      hasPin: false,
      isLocked: true,
      failedAttempts: 0,
      lockoutRemainingSeconds: 0,
      biometricsSupported: false,
    );
  }

  Future<void> initialize() async {
    final storage = ref.read(secureStorageProvider);
    final localAuth = ref.read(localAuthProvider);

    final hash = await storage.read(key: _keyPinHash);
    final salt = await storage.read(key: _keyPinSalt);

    final hasPin = hash != null && salt != null;

    bool biometrics = false;
    try {
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();
      biometrics = canCheck || isSupported;
    } catch (_) {
      biometrics = false;
    }

    state = AppLockState(
      isInitialized: true,
      hasPin: hasPin,
      // Cold start: always locked if PIN is configured.
      isLocked: hasPin,
      failedAttempts: 0,
      lockoutRemainingSeconds: 0,
      biometricsSupported: biometrics,
    );
  }

  Future<void> setPin(String newPin) async {
    final storage = ref.read(secureStorageProvider);
    final salt = _hasher.generateSalt();
    final hash = _hasher.hashPin(newPin, salt);

    await storage.write(key: _keyPinSalt, value: salt);
    await storage.write(key: _keyPinHash, value: hash);

    state = state.copyWith(
      hasPin: true,
      isLocked: false,
      failedAttempts: 0,
      lockoutRemainingSeconds: 0,
    );
  }

  Future<bool> verifyAndUnlock(String enteredPin) async {
    if (state.isLockedOut) {
      return false;
    }

    final storage = ref.read(secureStorageProvider);
    final hash = await storage.read(key: _keyPinHash);
    final salt = await storage.read(key: _keyPinSalt);

    if (hash == null || salt == null) {
      return false;
    }

    final isValid = _hasher.verifyPin(enteredPin, salt, hash);

    if (isValid) {
      _lockoutTimer?.cancel();
      state = state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        lockoutRemainingSeconds: 0,
      );
      return true;
    } else {
      final newFailedAttempts = state.failedAttempts + 1;
      if (newFailedAttempts >= 5) {
        _startLockout(30);
      } else {
        state = state.copyWith(failedAttempts: newFailedAttempts);
      }
      return false;
    }
  }

  Future<bool> verifyCurrentPin(String currentPin) async {
    final storage = ref.read(secureStorageProvider);
    final hash = await storage.read(key: _keyPinHash);
    final salt = await storage.read(key: _keyPinSalt);

    if (hash == null || salt == null) {
      return false;
    }

    return _hasher.verifyPin(currentPin, salt, hash);
  }

  Future<bool> authenticateWithBiometrics() async {
    if (state.isLockedOut || !state.hasPin) {
      return false;
    }

    final localAuth = ref.read(localAuthProvider);
    try {
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Unlock ED Companion',
        biometricOnly: true,
      );

      if (authenticated) {
        _lockoutTimer?.cancel();
        state = state.copyWith(
          isLocked: false,
          failedAttempts: 0,
          lockoutRemainingSeconds: 0,
        );
        return true;
      }
    } catch (_) {
      // Biometric failure or cancellation falls back to PIN
    }
    return false;
  }

  void lock() {
    if (state.hasPin) {
      state = state.copyWith(isLocked: true);
    }
  }

  void _startLockout(int seconds) {
    _lockoutTimer?.cancel();
    state = state.copyWith(
      failedAttempts: 5,
      lockoutRemainingSeconds: seconds,
    );

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.lockoutRemainingSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
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
