import 'package:flutter/material.dart';

/// Edge from which the collapsible bar aligns when shrinking/expanding.
enum CollapsibleBarEdge {
  top,
  bottom,
}

/// A bar that animates (200 ms) between full height and zero using ClipRect,
/// Align with heightFactor and TweenAnimationBuilder.
class CollapsibleBar extends StatelessWidget {
  final bool visible;
  final CollapsibleBarEdge edge;
  final Widget child;
  final Duration duration;

  const CollapsibleBar({
    super.key,
    required this.visible,
    required this.edge,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: visible ? 1.0 : 0.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, factor, child) {
        if (factor == 0.0) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: Align(
            alignment: edge == CollapsibleBarEdge.bottom
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            heightFactor: factor,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
