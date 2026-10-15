import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../work_page_provider.dart';
import 'chrome_provider.dart';

/// Overlay handle at bottom center shown when bars are hidden.
class BarHandle extends ConsumerStatefulWidget {
  final bool isWorkBranch;

  const BarHandle({
    super.key,
    required this.isWorkBranch,
  });

  @override
  ConsumerState<BarHandle> createState() => _BarHandleState();
}

class _BarHandleState extends ConsumerState<BarHandle> {
  double _dragDx = 0.0;
  double _dragDy = 0.0;
  bool _actionTriggered = false;

  void _onPanStart(DragStartDetails details) {
    _dragDx = 0.0;
    _dragDy = 0.0;
    _actionTriggered = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_actionTriggered) return;

    _dragDx += details.delta.dx;
    _dragDy += details.delta.dy;

    // Upward drag calls reveal()
    if (_dragDy <= -16.0) {
      _actionTriggered = true;
      ref.read(chromeProvider.notifier).reveal();
      return;
    }

    // Horizontal drag of at least 40 dp when on Work branch
    if (widget.isWorkBranch && _dragDx.abs() >= 40.0) {
      _actionTriggered = true;
      // Drag left goes to Hospital (1), drag right goes to Patients (0)
      if (_dragDx <= -40.0) {
        ref.read(workPageProvider.notifier).setPage(1);
      } else if (_dragDx >= 40.0) {
        ref.read(workPageProvider.notifier).setPage(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final systemGestureBottom = mq.systemGestureInsets.bottom;
    final viewPaddingBottom = mq.viewPadding.bottom;
    final bottomOffset = math.max(viewPaddingBottom, systemGestureBottom) + 6.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomOffset,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(chromeProvider.notifier).reveal();
          },
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          child: SizedBox(
            width: 160,
            height: 48,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
