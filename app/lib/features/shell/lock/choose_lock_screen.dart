import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'lock_controller.dart';
import 'lock_mode.dart';

class ChooseLockScreen extends ConsumerWidget {
  const ChooseLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lockState = ref.watch(lockControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.security_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Protect ED Companion',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to unlock the app on this device.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),

              // 1. App PIN
              _buildOptionCard(
                context: context,
                icon: Icons.pin_outlined,
                title: 'App PIN',
                description: 'A PIN only for this app. Good on shared phones.',
                enabled: true,
                onTap: () async {
                  await ref
                      .read(lockControllerProvider.notifier)
                      .setLockMode(LockMode.appPin);
                  if (context.mounted) {
                    context.go('/setup-pin');
                  }
                },
              ),
              const SizedBox(height: 16),

              // 2. Phone screen lock
              _buildOptionCard(
                context: context,
                icon: Icons.fingerprint,
                title: 'Phone screen lock',
                description: 'Use the phone\'s own fingerprint, PIN or pattern.',
                enabled: lockState.phoneLockSupported,
                disabledMessage: !lockState.phoneLockSupported
                    ? 'Your phone has no screen lock set up in Android settings.'
                    : null,
                onTap: () async {
                  await ref
                      .read(lockControllerProvider.notifier)
                      .setLockMode(LockMode.phoneLock);
                  // Newly chosen on first setup: unlocked initially
                  ref.read(lockControllerProvider.notifier).unlock();
                },
              ),
              const SizedBox(height: 16),

              // 3. No lock
              _buildOptionCard(
                context: context,
                icon: Icons.lock_open_outlined,
                title: 'No lock',
                description: 'Open straight away. I rely on my phone\'s lock screen.',
                enabled: true,
                onTap: () async {
                  await ref
                      .read(lockControllerProvider.notifier)
                      .setLockMode(LockMode.none);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
    String? disabledMessage,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: enabled
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: enabled
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: enabled
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: enabled
                            ? theme.colorScheme.onSurface
                            : theme.disabledColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.disabledColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.disabledColor,
                ),
              ),
              if (disabledMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  disabledMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
