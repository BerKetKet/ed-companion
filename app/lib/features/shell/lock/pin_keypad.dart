import 'package:flutter/material.dart';

/// One-handed friendly numeric keypad with >= 48dp tap targets.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onEnterPressed,
    this.onBiometricPressed,
    this.enabled = true,
    this.showBiometrics = false,
    this.showEnter = false,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onEnterPressed;
  final VoidCallback? onBiometricPressed;
  final bool enabled;
  final bool showBiometrics;
  final bool showEnter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 12),
        _buildBottomRow(context),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildDigitButton(context, digit)).toList(),
    );
  }

  Widget _buildDigitButton(BuildContext context, String digit) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onDigitPressed(digit) : null,
          child: Center(
            child: Text(
              digit,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    Widget leftAction;
    if (showBiometrics) {
      leftAction = SizedBox(
        width: 72,
        height: 72,
        child: IconButton(
          iconSize: 32,
          icon: const Icon(Icons.fingerprint),
          onPressed: enabled ? onBiometricPressed : null,
          tooltip: 'Unlock with fingerprint',
        ),
      );
    } else if (showEnter) {
      leftAction = SizedBox(
        width: 72,
        height: 72,
        child: IconButton(
          iconSize: 32,
          icon: const Icon(Icons.check_circle_outline),
          onPressed: enabled ? onEnterPressed : null,
          tooltip: 'Enter',
        ),
      );
    } else {
      leftAction = const SizedBox(width: 72, height: 72);
    }

    final deleteAction = SizedBox(
      width: 72,
      height: 72,
      child: IconButton(
        iconSize: 30,
        icon: const Icon(Icons.backspace_outlined),
        onPressed: enabled ? onDeletePressed : null,
        tooltip: 'Delete',
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        leftAction,
        _buildDigitButton(context, '0'),
        deleteAction,
      ],
    );
  }
}

/// Visual dot indicators for entered PIN digits.
class PinDotsIndicator extends StatelessWidget {
  const PinDotsIndicator({
    super.key,
    required this.pinLength,
    this.maxDots = 6,
    this.hasError = false,
  });

  final int pinLength;
  final int maxDots;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = hasError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxDots, (index) {
        final isFilled = index < pinLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? dotColor : Colors.transparent,
            border: Border.all(
              color: hasError ? theme.colorScheme.error : theme.colorScheme.outline,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
