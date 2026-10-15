import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/handedness.dart';
import '../settings_provider.dart';

/// Direction in which the fan-out menu expands.
enum FanOutDirection {
  upward,
  downward,
}

/// Pure function to snap an x-coordinate to the nearer screen side.
HandednessSide snapSide(double x, double screenWidth) {
  return x < screenWidth / 2 ? HandednessSide.left : HandednessSide.right;
}

/// Pure function to compute the fan-out offset for item [index] (0..5).
/// [side]: HandednessSide.left or HandednessSide.right
/// [direction]: FanOutDirection.upward or FanOutDirection.downward
/// [index]: 0..5 (0 = nearest to button, 5 = farthest)
Offset computeFanOutOffset({
  required HandednessSide side,
  required FanOutDirection direction,
  required int index,
}) {
  final step = (index + 1) * 60.0;
  final dy = direction == FanOutDirection.upward ? -step : step;
  final curve = 24.0 * math.sin(math.pi * index / 5.0);
  final dx = side == HandednessSide.right ? -curve : curve;
  return Offset(dx, dy);
}

/// State of the quick action button.
class QuickButtonState {
  final HandednessSide side;
  final double dyLeft;
  final double dyRight;

  const QuickButtonState({
    required this.side,
    required this.dyLeft,
    required this.dyRight,
  });

  double get currentDy => side == HandednessSide.left ? dyLeft : dyRight;

  QuickButtonState copyWith({
    HandednessSide? side,
    double? dyLeft,
    double? dyRight,
  }) {
    return QuickButtonState(
      side: side ?? this.side,
      dyLeft: dyLeft ?? this.dyLeft,
      dyRight: dyRight ?? this.dyRight,
    );
  }
}

/// Manages Quick Button placement, dragging, snapping, and persistence.
class QuickButtonNotifier extends Notifier<QuickButtonState> {
  static const _keyQuickSide = 'quick_side';
  static const _keyQuickDyLeft = 'quick_dy_left';
  static const _keyQuickDyRight = 'quick_dy_right';
  static const double kDefaultDyFraction = 0.65;

  @override
  QuickButtonState build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    ref.listen<Handedness>(settingsProvider.select((s) => s.handedness), (prev, next) {
      if (prev != null && prev != next) {
        final newSide = next.thumbSide;
        state = state.copyWith(side: newSide);
        final p = ref.read(sharedPreferencesProvider);
        p.setString(_keyQuickSide, newSide.name);
      }
    });

    final savedSideStr = prefs.getString(_keyQuickSide);
    final side = savedSideStr != null
        ? HandednessSide.fromString(savedSideStr)
        : ref.read(settingsProvider).handedness.thumbSide;

    final dyLeft = prefs.getDouble(_keyQuickDyLeft) ?? kDefaultDyFraction;
    final dyRight = prefs.getDouble(_keyQuickDyRight) ?? kDefaultDyFraction;

    return QuickButtonState(
      side: side,
      dyLeft: dyLeft,
      dyRight: dyRight,
    );
  }

  Future<void> setPosition(HandednessSide side, double dyFraction) async {
    final clamped = dyFraction.clamp(0.0, 1.0);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyQuickSide, side.name);

    if (side == HandednessSide.left) {
      await prefs.setDouble(_keyQuickDyLeft, clamped);
      state = state.copyWith(side: side, dyLeft: clamped);
    } else {
      await prefs.setDouble(_keyQuickDyRight, clamped);
      state = state.copyWith(side: side, dyRight: clamped);
    }
  }

  Future<void> reset() async {
    final handedness = ref.read(settingsProvider).handedness;
    final defaultSide = handedness.thumbSide;
    final prefs = ref.read(sharedPreferencesProvider);

    await prefs.setString(_keyQuickSide, defaultSide.name);
    await prefs.setDouble(_keyQuickDyLeft, kDefaultDyFraction);
    await prefs.setDouble(_keyQuickDyRight, kDefaultDyFraction);

    state = QuickButtonState(
      side: defaultSide,
      dyLeft: kDefaultDyFraction,
      dyRight: kDefaultDyFraction,
    );
  }
}

final quickButtonProvider =
    NotifierProvider<QuickButtonNotifier, QuickButtonState>(
  QuickButtonNotifier.new,
);
