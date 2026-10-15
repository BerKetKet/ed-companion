import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'lock_controller.dart';
import 'pin_keypad.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  int _step = 0; // 0 = current, 1 = new, 2 = confirm new
  String _newPin = '';
  String _confirmPin = '';
  String _input = '';
  String? _errorMessage;

  void _onDigit(String digit) {
    if (_input.length >= 6) return;

    setState(() {
      _errorMessage = null;
      _input += digit;
    });

    if (_step == 2 && _input.length == _newPin.length) {
      _handleStepAction();
    }
  }

  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _input = _input.substring(0, _input.length - 1);
    });
  }

  Future<void> _handleStepAction() async {
    if (_input.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    if (_step == 0) {
      // Verify current PIN
      final isValid =
          await ref.read(lockControllerProvider.notifier).verifyCurrentPin(_input);
      if (isValid) {
        setState(() {
          _input = '';
          _step = 1;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _input = '';
          _errorMessage = 'Current PIN is incorrect';
        });
      }
    } else if (_step == 1) {
      setState(() {
        _newPin = _input;
        _input = '';
        _step = 2;
        _errorMessage = null;
      });
    } else if (_step == 2) {
      _confirmPin = _input;
      if (_confirmPin == _newPin) {
        await ref.read(lockControllerProvider.notifier).setPin(_newPin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN updated successfully')),
          );
          context.pop();
        }
      } else {
        setState(() {
          _errorMessage = 'New PINs did not match. Please try again.';
          _newPin = '';
          _confirmPin = '';
          _input = '';
          _step = 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String subtitle;
    switch (_step) {
      case 0:
        title = 'Current PIN';
        subtitle = 'Enter your existing PIN';
        break;
      case 1:
        title = 'New PIN';
        subtitle = 'Enter your new 4 to 6 digit PIN';
        break;
      case 2:
      default:
        title = 'Confirm New PIN';
        subtitle = 'Re-enter your new PIN to confirm';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change PIN'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
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
              pinLength: _input.length,
              maxDots: _step == 2 && _newPin.isNotEmpty ? _newPin.length : 6,
              hasError: _errorMessage != null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 28,
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
            if ((_step == 0 || _step == 1) && _input.length >= 4)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.tonal(
                  onPressed: _handleStepAction,
                  child: const Text('Continue'),
                ),
              ),
            PinKeypad(
              onDigitPressed: _onDigit,
              onDeletePressed: _onDelete,
              onEnterPressed: _handleStepAction,
              showEnter: _input.length >= 4,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
