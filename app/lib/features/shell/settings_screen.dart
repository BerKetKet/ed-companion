import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'lock/lock_controller.dart';
import 'lock/lock_mode.dart';
import 'lock/lock_timer.dart';
import 'lock/pin_keypad.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lockState = ref.watch(lockControllerProvider);
    final currentLockMode = lockState.lockMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildSectionHeader(context, 'Appearance'),
            ListTile(
              leading: const Icon(Icons.brightness_medium_outlined),
              title: const Text('Theme'),
              subtitle: Text(
                settings.themeMode == ThemeMode.system
                    ? 'System default'
                    : settings.themeMode == ThemeMode.light
                        ? 'Light'
                        : 'Dark',
              ),
              trailing: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto, size: 18),
                    tooltip: 'System',
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode, size: 18),
                    tooltip: 'Light',
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode, size: 18),
                    tooltip: 'Dark',
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selected) {
                  ref.read(settingsProvider.notifier).setThemeMode(selected.first);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.format_size),
              title: const Text('Text size'),
              subtitle: Text(settings.textSize.label),
              trailing: DropdownButton<TextSizeChoice>(
                value: settings.textSize,
                underline: const SizedBox(),
                items: TextSizeChoice.values.map((choice) {
                  return DropdownMenuItem(
                    value: choice,
                    child: Text(choice.label),
                  );
                }).toList(),
                onChanged: (choice) {
                  if (choice != null) {
                    ref.read(settingsProvider.notifier).setTextSize(choice);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader(context, 'Security'),
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('Lock type'),
              subtitle: Text(currentLockMode?.label ?? 'Not set'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLockTypePicker(context, ref, lockState),
            ),
            if (currentLockMode != LockMode.none) ...[
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Lock after'),
                subtitle: Text(settings.autoLockTimeout.label),
                trailing: DropdownButton<AutoLockTimeout>(
                  value: settings.autoLockTimeout,
                  underline: const SizedBox(),
                  items: AutoLockTimeout.values.map((timeout) {
                    return DropdownMenuItem(
                      value: timeout,
                      child: Text(timeout.label),
                    );
                  }).toList(),
                  onChanged: (timeout) {
                    if (timeout != null) {
                      ref.read(settingsProvider.notifier).setAutoLockTimeout(timeout);
                    }
                  },
                ),
              ),
            ],
            if (currentLockMode == LockMode.appPin && lockState.biometricsSupported) ...[
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Use fingerprint'),
                subtitle: const Text('Unlock with biometric sensor'),
                value: settings.useFingerprint,
                onChanged: (enabled) {
                  ref.read(settingsProvider.notifier).setUseFingerprint(enabled);
                },
              ),
            ],
            if (currentLockMode == LockMode.appPin) ...[
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: const Text('Change PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/change-pin'),
              ),
            ],
            const SizedBox(height: 16),
            _buildSectionHeader(context, 'About & Information'),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('Version, clinical disclaimer & sources'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/about'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLockTypePicker(
    BuildContext context,
    WidgetRef ref,
    AppLockState lockState,
  ) async {
    final currentMode = lockState.lockMode ?? LockMode.none;

    final selectedMode = await showDialog<LockMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lock type'),
          contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
          content: SingleChildScrollView(
            child: RadioGroup<LockMode>(
              groupValue: currentMode,
              onChanged: (val) {
                if (val != null) Navigator.of(context).pop(val);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RadioListTile<LockMode>(
                    value: LockMode.appPin,
                    title: Text('App PIN'),
                    subtitle: Text('A PIN only for this app. Good on shared phones.'),
                  ),
                  RadioListTile<LockMode>(
                    value: LockMode.phoneLock,
                    title: const Text('Phone screen lock'),
                    subtitle: Text(
                      lockState.phoneLockSupported
                          ? 'Use the phone\'s own fingerprint, PIN or pattern.'
                          : 'No screen lock set up on device',
                    ),
                    enabled: lockState.phoneLockSupported,
                  ),
                  const RadioListTile<LockMode>(
                    value: LockMode.none,
                    title: Text('No lock'),
                    subtitle: Text('Open straight away. I rely on my phone\'s lock screen.'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedMode == null || selectedMode == currentMode || !context.mounted) {
      return;
    }

    if (currentMode == LockMode.appPin) {
      // appPin to phoneLock or none:
      // first ask for current PIN
      final verified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const _VerifyCurrentPinSheet(),
      );

      if (verified == true && context.mounted) {
        await ref.read(lockControllerProvider.notifier).setLockMode(selectedMode);
        await ref.read(lockControllerProvider.notifier).deletePin();
      }
    } else if (selectedMode == LockMode.appPin) {
      // phoneLock or none to appPin:
      // go through the existing create-PIN screen; mode only changes once PIN is saved
      context.push('/setup-pin');
    } else {
      // phoneLock <-> none
      if (selectedMode == LockMode.phoneLock && !lockState.phoneLockSupported) {
        return;
      }
      await ref.read(lockControllerProvider.notifier).setLockMode(selectedMode);
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _VerifyCurrentPinSheet extends ConsumerStatefulWidget {
  const _VerifyCurrentPinSheet();

  @override
  ConsumerState<_VerifyCurrentPinSheet> createState() => _VerifyCurrentPinSheetState();
}

class _VerifyCurrentPinSheetState extends ConsumerState<_VerifyCurrentPinSheet> {
  String _enteredPin = '';
  String? _errorMessage;

  void _onDigit(String digit) {
    final lockState = ref.read(lockControllerProvider);
    final maxAllowed = lockState.pinLength ?? 6;
    if (lockState.isLockedOut || _enteredPin.length >= maxAllowed) return;

    final nextPin = _enteredPin + digit;
    setState(() {
      _errorMessage = null;
      _enteredPin = nextPin;
    });

    if (lockState.pinLength != null && nextPin.length == lockState.pinLength) {
      _verify(nextPin);
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

  Future<void> _verify(String pinToVerify) async {
    final lockState = ref.read(lockControllerProvider);
    if (lockState.isLockedOut) return;

    final isValid = await ref
        .read(lockControllerProvider.notifier)
        .verifyCurrentPin(pinToVerify);

    if (isValid) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _errorMessage = 'Current PIN is incorrect';
        });
      }
    }
  }

  Future<void> _onEnter() async {
    final lockState = ref.read(lockControllerProvider);
    if (lockState.isLockedOut || _enteredPin.isEmpty) return;
    await _verify(_enteredPin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lockState = ref.watch(lockControllerProvider);

    String? displayError = _errorMessage;
    if (lockState.isLockedOut) {
      displayError =
          'Too many attempts. Try again in ${lockState.lockoutRemainingSeconds}s';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    'Enter current PIN',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN to confirm lock type change',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            PinDotsIndicator(
              pinLength: _enteredPin.length,
              maxDots: lockState.pinLength ?? 6,
              hasError: displayError != null,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 24,
              child: displayError != null
                  ? Text(
                      displayError,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            PinKeypad(
              onDigitPressed: _onDigit,
              onDeletePressed: _onDelete,
              onEnterPressed: _onEnter,
              enabled: !lockState.isLockedOut,
              showEnter: _enteredPin.length >= 4,
            ),
          ],
        ),
      ),
    );
  }
}
