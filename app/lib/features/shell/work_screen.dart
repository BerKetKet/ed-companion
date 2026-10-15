import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  late final PageController _pageController;
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSegmentChanged(Set<int> newSelection) {
    final newIndex = newSelection.first;
    setState(() {
      _selectedPageIndex = newIndex;
    });
    _pageController.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: const [
                  KeepAliveWrapper(
                    child: Center(
                      child: Text(
                        'Patients: ward board coming in module B',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  KeepAliveWrapper(
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
            Padding(
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
                  selected: {_selectedPageIndex},
                  onSelectionChanged: _onSegmentChanged,
                ),
              ),
            ),
          ],
        ),
      ),
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
