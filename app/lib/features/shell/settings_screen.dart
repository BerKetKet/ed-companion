import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'lock/lock_controller.dart';
import 'lock/lock_timer.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lockState = ref.watch(lockControllerProvider);

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
            if (lockState.biometricsSupported) ...[
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
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: const Text('Change PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/change-pin'),
            ),
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
