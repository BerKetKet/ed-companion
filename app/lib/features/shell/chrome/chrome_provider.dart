import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings_provider.dart';

/// State of chrome bars visibility.
class ChromeState {
  final bool barsRevealed;
  final bool barsVisible;

  const ChromeState({
    required this.barsRevealed,
    required this.barsVisible,
  });

  ChromeState copyWith({
    bool? barsRevealed,
    bool? barsVisible,
  }) {
    return ChromeState(
      barsRevealed: barsRevealed ?? this.barsRevealed,
      barsVisible: barsVisible ?? this.barsVisible,
    );
  }
}

/// Notifier managing collapsible chrome bars visibility and auto-hide timer.
class ChromeNotifier extends Notifier<ChromeState> {
  Timer? _revealTimer;

  @override
  ChromeState build() {
    ref.onDispose(() {
      _cancelTimer();
    });

    final barMode = ref.watch(settingsProvider.select((s) => s.barMode));

    ref.listen<BarMode>(settingsProvider.select((s) => s.barMode), (prev, next) {
      if (prev != null && prev != next) {
        _cancelTimer();
        if (next == BarMode.autoHide) {
          state = ChromeState(
            barsRevealed: true,
            barsVisible: true,
          );
        } else if (next == BarMode.gesturesOnly) {
          state = ChromeState(
            barsRevealed: false,
            barsVisible: false,
          );
        } else if (next == BarMode.alwaysShow) {
          state = state.copyWith(barsVisible: true);
        }
      }
    });

    final initialRevealed = barMode != BarMode.gesturesOnly;
    final initialVisible = barMode == BarMode.alwaysShow ? true : initialRevealed;

    return ChromeState(
      barsRevealed: initialRevealed,
      barsVisible: initialVisible,
    );
  }

  void _cancelTimer() {
    _revealTimer?.cancel();
    _revealTimer = null;
  }

  void hide() {
    _cancelTimer();
    final barMode = ref.read(settingsProvider).barMode;
    state = ChromeState(
      barsRevealed: false,
      barsVisible: barMode == BarMode.alwaysShow,
    );
  }

  void show() {
    _cancelTimer();
    state = const ChromeState(
      barsRevealed: true,
      barsVisible: true,
    );
  }

  void reveal() {
    _cancelTimer();
    state = const ChromeState(
      barsRevealed: true,
      barsVisible: true,
    );

    final mode = ref.read(settingsProvider).barMode;
    if (mode == BarMode.gesturesOnly) {
      _revealTimer = Timer(const Duration(seconds: 5), () {
        hide();
      });
    }
  }

  void onBranchChanged() {
    show();
  }
}

final chromeProvider = NotifierProvider<ChromeNotifier, ChromeState>(
  ChromeNotifier.new,
);
