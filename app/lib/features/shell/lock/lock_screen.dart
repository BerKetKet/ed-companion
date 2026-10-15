import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings_provider.dart';
import 'lock_mode.dart';
import 'lock_controller.dart';
import 'pin_keypad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _promptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoPrompt();
    });
  }

  Future<void> _checkAutoPrompt() async {
    if (_promptShown) return;
    final lockState = ref.read(lockControllerProvider);

    if (lockState.lockMode == LockMode.phoneLock) {
      final supported = await ref
          .read(lockControllerProvider.notifier)
          .refreshDeviceSupport();
      if (!mounted) return;
      if (supported) {
        _promptShown = true;
        await _triggerPhoneLock();
      }
    } else if (lockState.lockMode == LockMode.appPin) {
      final settings = ref.read(settingsProvider);
      if (settings.useFingerprint &&
          lockState.biometricsSupported &&
          !lockState.isLockedOut) {
        _promptShown = true;
        await _triggerBiometrics();
      }
    }
  }

  Future<void> _triggerPhoneLock() async {
    final success =
        await ref.read(lockControllerProvider.notifier).authenticateWithPhoneLock();
    if (!success && mounted) {
      await ref.read(lockControllerProvider.notifier).refreshDeviceSupport();
    }
  }

  Future<void> _triggerBiometrics() async {
    final success =
        await ref.read(lockControllerProvider.notifier).authenticateWithBiometrics();
    if (!success && mounted) {
      setState(() {
        // Biometrics was cancelled or failed; keypad remains usable.
      });
    }
  }

  Future<void> _onDigit(String digit) async {
    final lockState = ref.read(lockControllerProvider);
    final maxAllowed = lockState.pinLength ?? 6;
    if (lockState.isLockedOut || _enteredPin.length >= maxAllowed) return;

    final nextPin = _enteredPin + digit;
    setState(() {
      _errorMessage = null;
      _enteredPin = nextPin;
    });

    if (lockState.pinLength != null && nextPin.length == lockState.pinLength) {
      final success = await ref
          .read(lockControllerProvider.notifier)
          .verifyAndUnlock(nextPin);
      if (!success && mounted) {
        setState(() {
          _enteredPin = '';
          _errorMessage = 'Incorrect PIN';
        });
      }
    }
  }

  void _onDelete() {
    final lockState = ref.read(lockControllerProvider);
    if (lockState.isLockedOut || _enteredPin.isEmpty) return;

    setState(() {
      _errorMessage = null;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _onEnter() async {
    final lockState = ref.read(lockControllerProvider);
    if (lockState.isLockedOut || _enteredPin.isEmpty) return;

    final success =
        await ref.read(lockControllerProvider.notifier).verifyAndUnlock(_enteredPin);
    if (!success && mounted) {
      setState(() {
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final lockState = ref.watch(lockControllerProvider);

    String? displayError = _errorMessage;
    if (lockState.isLockedOut) {
      displayError = 'Too many attempts. Try again in ${lockState.lockoutRemainingSeconds}s';
    }

    final showBiometrics =
        settings.useFingerprint && lockState.biometricsSupported;

    if (lockState.lockMode == LockMode.phoneLock) {
      final hasLock = lockState.phoneLockSupported;

      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasLock ? Icons.lock_outline : Icons.warning_amber_rounded,
                    size: 56,
                    color: hasLock ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ED Companion',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'App locked',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (hasLock)
                    FilledButton.icon(
                      onPressed: _triggerPhoneLock,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Unlock'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(160, 48),
                      ),
                    )
                  else ...[
                    Text(
                      'This phone no longer has a screen lock. Set one in Android settings, or switch to No lock.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        await ref
                            .read(lockControllerProvider.notifier)
                            .setLockMode(LockMode.none);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(160, 48),
                      ),
                      child: const Text('Switch to No lock'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ED Companion',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your PIN to unlock',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      PinDotsIndicator(
                        pinLength: _enteredPin.length,
                        maxDots: lockState.pinLength ?? 6,
                        hasError: displayError != null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 28,
                        child: displayError != null
                            ? Text(
                                displayError,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      const Spacer(),
                      PinKeypad(
                        onDigitPressed: _onDigit,
                        onDeletePressed: _onDelete,
                        onEnterPressed: _onEnter,
                        onBiometricPressed: _triggerBiometrics,
                        enabled: !lockState.isLockedOut,
                        showBiometrics: showBiometrics,
                        showEnter: _enteredPin.length >= 4,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
