import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'chrome/bar_handle.dart';
import 'chrome/chrome_provider.dart';
import 'chrome/collapsible_bar.dart';
import 'chrome/scroll_tracker.dart';
import 'settings_provider.dart';

/// Navigation shell wrapping the app with collapsible NavigationBar,
/// scroll tracking for auto-hide, and bottom handle overlay.
class NavigationShellWidget extends ConsumerStatefulWidget {
  const NavigationShellWidget({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<NavigationShellWidget> createState() =>
      _NavigationShellWidgetState();
}

class _NavigationShellWidgetState
    extends ConsumerState<NavigationShellWidget> {
  final _scrollTracker = ScrollDirectionTracker();

  @override
  Widget build(BuildContext context) {
    final chrome = ref.watch(chromeProvider);
    final barMode = ref.watch(settingsProvider.select((s) => s.barMode));
    final showHandle =
        barMode != BarMode.alwaysShow && !chrome.barsVisible;

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis != Axis.vertical) {
                return false;
              }
              final currentMode = ref.read(settingsProvider).barMode;
              if (currentMode != BarMode.autoHide) {
                return false;
              }
              final delta = notification.scrollDelta ?? 0.0;
              final action = _scrollTracker.update(
                delta,
                notification.metrics.pixels,
              );
              if (action == true) {
                ref.read(chromeProvider.notifier).show();
              } else if (action == false) {
                ref.read(chromeProvider.notifier).hide();
              }
              return false;
            },
            child: widget.navigationShell,
          ),
          if (showHandle)
            BarHandle(
              isWorkBranch: widget.navigationShell.currentIndex == 0,
            ),
        ],
      ),
      bottomNavigationBar: CollapsibleBar(
        visible: chrome.barsVisible,
        edge: CollapsibleBarEdge.bottom,
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            if (index != widget.navigationShell.currentIndex) {
              ref.read(chromeProvider.notifier).onBranchChanged();
            }
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services),
              label: 'Work',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Study',
            ),
          ],
        ),
      ),
    );
  }
}
