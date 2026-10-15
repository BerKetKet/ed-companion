import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/handedness.dart';

/// Provider for SharedPreferences instance injected at app startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

/// User-selectable text scale options.
enum TextSizeChoice {
  normal(1.0, 'Normal'),
  large(1.15, 'Large'),
  extraLarge(1.3, 'Extra large');

  const TextSizeChoice(this.scale, this.label);
  final double scale;
  final String label;

  static TextSizeChoice fromString(String? val) {
    return TextSizeChoice.values.firstWhere(
      (e) => e.name == val,
      orElse: () => TextSizeChoice.normal,
    );
  }
}

/// Navigation bar visibility modes.
enum BarMode {
  alwaysShow('Always show'),
  autoHide('Auto-hide'),
  gesturesOnly('Gestures only');

  const BarMode(this.label);
  final String label;

  static BarMode fromString(String? val) {
    return BarMode.values.firstWhere(
      (e) => e.name == val,
      orElse: () => BarMode.autoHide,
    );
  }
}

/// Holds user settings for theme, scaling, and navigation chrome.
class AppSettings {
  final ThemeMode themeMode;
  final TextSizeChoice textSize;
  final BarMode barMode;
  final Handedness handedness;
  final bool quickButtonVisible;
  final bool gestureHintSeen;

  const AppSettings({
    required this.themeMode,
    required this.textSize,
    required this.barMode,
    required this.handedness,
    required this.quickButtonVisible,
    required this.gestureHintSeen,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    TextSizeChoice? textSize,
    BarMode? barMode,
    Handedness? handedness,
    bool? quickButtonVisible,
    bool? gestureHintSeen,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textSize: textSize ?? this.textSize,
      barMode: barMode ?? this.barMode,
      handedness: handedness ?? this.handedness,
      quickButtonVisible: quickButtonVisible ?? this.quickButtonVisible,
      gestureHintSeen: gestureHintSeen ?? this.gestureHintSeen,
    );
  }
}

/// Notifier managing persistent settings across app restarts.
class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _keyThemeMode = 'app_theme_mode';
  static const _keyTextSize = 'app_text_size';
  static const _keyBarMode = 'bar_mode';
  static const _keyHandedness = 'handedness';
  static const _keyQuickButtonVisible = 'quick_button_visible';
  static const _keyGestureHintSeen = 'gesture_hint_seen';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    final themeStr = prefs.getString(_keyThemeMode);
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeStr,
      orElse: () => ThemeMode.system,
    );

    final textSize = TextSizeChoice.fromString(prefs.getString(_keyTextSize));
    final barMode = BarMode.fromString(prefs.getString(_keyBarMode));
    final handedness = Handedness.fromString(prefs.getString(_keyHandedness));
    final quickButtonVisible = prefs.getBool(_keyQuickButtonVisible) ?? true;
    final gestureHintSeen = prefs.getBool(_keyGestureHintSeen) ?? false;

    return AppSettings(
      themeMode: themeMode,
      textSize: textSize,
      barMode: barMode,
      handedness: handedness,
      quickButtonVisible: quickButtonVisible,
      gestureHintSeen: gestureHintSeen,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyThemeMode, mode.name);
  }

  Future<void> setTextSize(TextSizeChoice size) async {
    state = state.copyWith(textSize: size);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyTextSize, size.name);
  }

  Future<void> setBarMode(BarMode mode) async {
    state = state.copyWith(barMode: mode);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyBarMode, mode.name);
  }

  Future<void> setHandedness(Handedness handedness) async {
    state = state.copyWith(handedness: handedness);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyHandedness, handedness.name);
  }

  Future<void> setQuickButtonVisible(bool visible) async {
    state = state.copyWith(quickButtonVisible: visible);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyQuickButtonVisible, visible);
  }

  Future<void> setGestureHintSeen(bool seen) async {
    state = state.copyWith(gestureHintSeen: seen);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyGestureHintSeen, seen);
  }
}

final settingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
