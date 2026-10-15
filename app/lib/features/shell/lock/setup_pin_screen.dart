import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lock_controller.dart';
import 'pin_keypad.dart';

class SetupPinScreen extends ConsumerStatefulWidget {
  const SetupPinScreen({super.key});

  @override
  ConsumerState<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends ConsumerState<SetupPinScreen> {
  int _step = 0; // 0 = create, 1 = confirm
  String _firstPin = '';
  String _currentPin = '';
  String? _errorMessage;

  void _onDigit(String digit) {
    if (_currentPin.length >= 6) return;

    setState(() {
      _errorMessage = null;
      _currentPin += digit;
    });

    // In step 1, automatically check if lengths match
    if (_step == 1 && _currentPin.length == _firstPin.length) {
      _finishConfirmation();
    }
  }

  void _onDelete() {
    if (_currentPin.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _currentPin = _currentPin.substring(0, _currentPin.length - 1);
    });
  }

  void _onContinue() {
    if (_currentPin.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    if (_step == 0) {
      setState(() {
        _firstPin = _currentPin;
        _currentPin = '';
        _step = 1;
        _errorMessage = null;
      });
    } else {
      _finishConfirmation();
    }
  }

  Future<void> _finishConfirmation() async {
    if (_currentPin == _firstPin) {
      await ref.read(lockControllerProvider.notifier).setPin(_firstPin);
      // Navigation is handled automatically by GoRouter redirect to /work.
    } else {
      setState(() {
        _errorMessage = 'PINs did not match. Please try again.';
        _firstPin = '';
        _currentPin = '';
        _step = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _step == 0 ? 'Create a PIN' : 'Confirm your PIN';
    final subtitle = _step == 0
        ? 'Enter 4 to 6 digits to secure your notes'
        : 'Re-enter your PIN to verify';

    return Scaffold(
      body: SafeArea(
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
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            PinDotsIndicator(
              pinLength: _currentPin.length,
              maxDots: _step == 1 && _firstPin.isNotEmpty ? _firstPin.length : 6,
              hasError: _errorMessage != null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 24,
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
            ),
            const Spacer(),
            if (_step == 0 && _currentPin.length >= 4)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.tonal(
                  onPressed: _onContinue,
                  child: const Text('Continue'),
                ),
              ),
            PinKeypad(
              onDigitPressed: _onDigit,
              onDeletePressed: _onDelete,
              onEnterPressed: _onContinue,
              showEnter: _currentPin.length >= 4,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
