import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import 'chrome/chrome_provider.dart';
import 'chrome/collapsible_bar.dart';
import 'settings_provider.dart';
import 'work_page_provider.dart';

class WorkScreen extends ConsumerStatefulWidget {
  const WorkScreen({super.key});

  @override
  ConsumerState<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends ConsumerState<WorkScreen> {
  late final PageController _pageController;
  bool _edgeGuardActive = false;

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(workPageProvider);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSegmentChanged(Set<int> newSelection) {
    final newIndex = newSelection.first;
    ref.read(workPageProvider.notifier).setPage(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final workPage = ref.watch(workPageProvider);
    final barsVisible = ref.watch(chromeProvider.select((s) => s.barsVisible));
    final gestureHintSeen = ref.watch(settingsProvider.select((s) => s.gestureHintSeen));

    ref.listen<int>(workPageProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });

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
                title: const Text('Work'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.build_outlined),
                    tooltip: 'Tools',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => context.push('/work/tools'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            if (!gestureHintSeen) _buildGestureHintCard(context),
            Expanded(
              child: Listener(
                onPointerDown: (event) {
                  final x = event.position.dx;
                  final width = MediaQuery.of(context).size.width;
                  if (x < kEdgeGuard || x > width - kEdgeGuard) {
                    if (!_edgeGuardActive) {
                      setState(() {
                        _edgeGuardActive = true;
                      });
                    }
                  }
                },
                onPointerUp: (event) {
                  if (_edgeGuardActive) {
                    setState(() {
                      _edgeGuardActive = false;
                    });
                  }
                },
                onPointerCancel: (event) {
                  if (_edgeGuardActive) {
                    setState(() {
                      _edgeGuardActive = false;
                    });
                  }
                },
                child: PageView(
                  controller: _pageController,
                  physics: (workPage == 1 || _edgeGuardActive)
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  onPageChanged: (index) {
                    ref.read(workPageProvider.notifier).setPage(index);
                  },
                  children: [
                    KeepAliveWrapper(
                      child: _buildPatientsList(),
                    ),
                    const KeepAliveWrapper(
                      child: Center(
                        child: Text(
                          'Hospital system: coming in module C',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CollapsibleBar(
              visible: barsVisible,
              edge: CollapsibleBarEdge.bottom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('Patients'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('Hospital'),
                        icon: Icon(Icons.local_hospital_outlined),
                      ),
                    ],
                    selected: {workPage},
                    onSelectionChanged: _onSegmentChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureHintCard(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tips: swipe sideways to switch Patients and Hospital. Scroll down to hide the bars; the small handle at the bottom brings them back. Press and hold the bolt button to move it.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref.read(settingsProvider.notifier).setGestureHintSeen(true);
                      context.push('/gestures');
                    },
                    child: const Text('All gestures'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () {
                      ref.read(settingsProvider.notifier).setGestureHintSeen(true);
                    },
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientsList() {
    return ListView.builder(
      itemCount: 41,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Center(
              child: Text(
                'Patients: ward board coming in module B',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListTile(
          title: Text('Scroll test row $index'),
        );
      },
    );
  }
}

/// Ensures sub-pages remain alive in memory during swipe and tab changes.
class KeepAliveWrapper extends StatefulWidget {
  const KeepAliveWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
