import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'chrome/chrome_provider.dart';
import 'chrome/collapsible_bar.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barsVisible = ref.watch(chromeProvider.select((s) => s.barsVisible));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CollapsibleBar(
              visible: barsVisible,
              edge: CollapsibleBarEdge.top,
              child: AppBar(
                primary: false,
                title: const Text('Study'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Study library: coming in module E',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
