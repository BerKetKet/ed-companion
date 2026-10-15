import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/handedness.dart';
import 'chrome/quick_button_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
                  ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(selected.first);
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
            _buildSectionHeader(context, 'Navigation'),
            ListTile(
              leading: const Icon(Icons.view_headline),
              title: const Text('Bars'),
              subtitle: Text(settings.barMode.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBarModeDialog(context, ref, settings.barMode),
            ),
            ListTile(
              leading: const Icon(Icons.pan_tool_outlined),
              title: const Text('Handedness'),
              subtitle: Text('${settings.handedness.label} thumb reach'),
              trailing: SegmentedButton<Handedness>(
                segments: const [
                  ButtonSegment(
                    value: Handedness.right,
                    label: Text('Right'),
                  ),
                  ButtonSegment(
                    value: Handedness.left,
                    label: Text('Left'),
                  ),
                ],
                selected: {settings.handedness},
                onSelectionChanged: (selected) {
                  ref
                      .read(settingsProvider.notifier)
                      .setHandedness(selected.first);
                },
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.bolt),
              title: const Text('Show quick button'),
              subtitle: const Text('Floating action button for navigation'),
              value: settings.quickButtonVisible,
              onChanged: (visible) {
                ref
                    .read(settingsProvider.notifier)
                    .setQuickButtonVisible(visible);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Reset quick button position'),
              subtitle: const Text('Restore default edge and height'),
              onTap: () async {
                await ref.read(quickButtonProvider.notifier).reset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quick button position reset to default'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.gesture),
              title: const Text('Gestures help'),
              subtitle: const Text('Gesture shortcuts and fallbacks'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/gestures'),
            ),
            ListTile(
              leading: const Icon(Icons.tips_and_updates_outlined),
              title: const Text('Show gesture hint again'),
              subtitle: const Text('Display the tips card on the Work page'),
              onTap: () async {
                await ref
                    .read(settingsProvider.notifier)
                    .setGestureHintSeen(false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gesture hints will show on Work page'),
                    ),
                  );
                }
              },
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

  Future<void> _showBarModeDialog(
    BuildContext context,
    WidgetRef ref,
    BarMode currentMode,
  ) async {
    final selectedMode = await showDialog<BarMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bars mode'),
          contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
          content: SingleChildScrollView(
            child: RadioGroup<BarMode>(
              groupValue: currentMode,
              onChanged: (val) {
                if (val != null) Navigator.of(context).pop(val);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: BarMode.values.map((mode) {
                  return RadioListTile<BarMode>(
                    value: mode,
                    title: Text(mode.label),
                  );
                }).toList(),
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

    if (selectedMode != null && selectedMode != currentMode) {
      ref.read(settingsProvider.notifier).setBarMode(selectedMode);
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
