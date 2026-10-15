import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lock/lock_timer.dart';

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

/// Holds all persistent user settings for theme, scaling, and security.
class AppSettings {
  final ThemeMode themeMode;
  final TextSizeChoice textSize;
  final bool useFingerprint;
  final AutoLockTimeout autoLockTimeout;

  const AppSettings({
    required this.themeMode,
    required this.textSize,
    required this.useFingerprint,
    required this.autoLockTimeout,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    TextSizeChoice? textSize,
    bool? useFingerprint,
    AutoLockTimeout? autoLockTimeout,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textSize: textSize ?? this.textSize,
      useFingerprint: useFingerprint ?? this.useFingerprint,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
    );
  }
}

/// Notifier managing persistent settings across app restarts.
class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _keyThemeMode = 'app_theme_mode';
  static const _keyTextSize = 'app_text_size';
  static const _keyUseFingerprint = 'app_use_fingerprint';
  static const _keyAutoLockTimeout = 'app_auto_lock_timeout';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    final themeStr = prefs.getString(_keyThemeMode);
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeStr,
      orElse: () => ThemeMode.system,
    );

    final textSize = TextSizeChoice.fromString(prefs.getString(_keyTextSize));
    final useFingerprint = prefs.getBool(_keyUseFingerprint) ?? false;
    final autoLockTimeout = AutoLockTimeout.fromString(prefs.getString(_keyAutoLockTimeout));

    return AppSettings(
      themeMode: themeMode,
      textSize: textSize,
      useFingerprint: useFingerprint,
      autoLockTimeout: autoLockTimeout,
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

  Future<void> setUseFingerprint(bool enabled) async {
    state = state.copyWith(useFingerprint: enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyUseFingerprint, enabled);
  }

  Future<void> setAutoLockTimeout(AutoLockTimeout timeout) async {
    state = state.copyWith(autoLockTimeout: timeout);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyAutoLockTimeout, timeout.name);
  }
}

final settingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
