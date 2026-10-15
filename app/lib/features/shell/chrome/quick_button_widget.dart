import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/handedness.dart';
import '../../../main.dart';
import '../settings_provider.dart';
import '../work_page_provider.dart';
import 'modal_tracker.dart';
import 'quick_button_provider.dart';

/// App-level overlay providing the quick action bolt button and fan-out menu.
class QuickButtonOverlay extends ConsumerStatefulWidget {
  const QuickButtonOverlay({super.key});

  @override
  ConsumerState<QuickButtonOverlay> createState() => _QuickButtonOverlayState();
}

class _QuickButtonOverlayState extends ConsumerState<QuickButtonOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;
  bool _isDragging = false;
  Offset _dragPosition = Offset.zero;

  static const double _buttonSize = 56.0;
  static const double _itemSize = 48.0;
  static const double _screenMargin = 12.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 305),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeMenu() {
    if (!_isOpen) return;
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    });
  }

  void _openMenu() {
    setState(() {
      _isOpen = true;
    });
    _controller.forward(from: 0.0);
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final modalCount = ref.watch(modalCountProvider);

    // Hidden when disabled in settings or when a dialog/sheet/popup is open
    if (!settings.quickButtonVisible || modalCount > 0) {
      return const SizedBox.shrink();
    }

    final quickButton = ref.watch(quickButtonProvider);
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top + 8.0;
    final bottomPadding = mq.padding.bottom + 8.0;
    final usableHeight =
        mq.size.height - topPadding - bottomPadding - _buttonSize;

    double buttonLeft;
    double buttonTop;

    if (_isDragging) {
      buttonLeft = (_dragPosition.dx - _buttonSize / 2)
          .clamp(0.0, mq.size.width - _buttonSize);
      buttonTop = (_dragPosition.dy - _buttonSize / 2)
          .clamp(topPadding, topPadding + usableHeight);
    } else {
      buttonTop = topPadding + quickButton.currentDy * usableHeight;
      if (quickButton.side == HandednessSide.right) {
        buttonLeft = mq.size.width - _screenMargin - _buttonSize;
      } else {
        buttonLeft = _screenMargin;
      }
    }

    final buttonCenterX = buttonLeft + _buttonSize / 2;
    final buttonCenterY = buttonTop + _buttonSize / 2;
    final direction = buttonCenterY >= mq.size.height / 2
        ? FanOutDirection.upward
        : FanOutDirection.downward;

    final theme = Theme.of(context);

    final items = [
      _FanOutItemData(
        label: 'Patients',
        icon: Icons.person_outline,
        onTap: () {
          ref.read(workPageProvider.notifier).setPage(0);
          ref.read(routerProvider).go('/work');
        },
      ),
      _FanOutItemData(
        label: 'Hospital',
        icon: Icons.local_hospital_outlined,
        onTap: () {
          ref.read(workPageProvider.notifier).setPage(1);
          ref.read(routerProvider).go('/work');
        },
      ),
      _FanOutItemData(
        label: 'Study',
        icon: Icons.menu_book_outlined,
        onTap: () {
          ref.read(routerProvider).go('/study');
        },
      ),
      _FanOutItemData(
        label: 'Tools',
        icon: Icons.build_outlined,
        onTap: () {
          ref.read(routerProvider).push('/work/tools');
        },
      ),
      _FanOutItemData(
        label: 'Drafts',
        icon: Icons.note_alt_outlined,
        onTap: () {
          ref.read(routerProvider).push('/drafts');
        },
      ),
      _FanOutItemData(
        label: 'New task',
        icon: Icons.add_task_outlined,
        onTap: () {
          ref.read(routerProvider).push('/new-task');
        },
      ),
    ];

    return PopScope(
      canPop: !_isOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isOpen) {
          _closeMenu();
        }
      },
      child: Stack(
        children: [
          // Scrim (only while menu is open)
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeMenu,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      color: Colors.black.withValues(alpha: 0.35 * _controller.value),
                    );
                  },
                ),
              ),
            ),

          // Fan-out items (only while menu is open)
          if (_isOpen)
            for (int i = 0; i < items.length; i++)
              _buildFanOutItem(
                context: context,
                index: i,
                item: items[i],
                side: quickButton.side,
                direction: direction,
                buttonCenterX: buttonCenterX,
                buttonCenterY: buttonCenterY,
                screenSize: mq.size,
                theme: theme,
              ),

          // Bolt / Close Quick Button
          Positioned(
            left: buttonLeft,
            top: buttonTop,
            child: GestureDetector(
              onTap: () {
                if (!_isDragging) {
                  _toggleMenu();
                }
              },
              onLongPressStart: _isOpen
                  ? null
                  : (details) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isDragging = true;
                        _dragPosition = details.globalPosition;
                      });
                    },
              onLongPressMoveUpdate: _isOpen
                  ? null
                  : (details) {
                      setState(() {
                        _dragPosition = details.globalPosition;
                      });
                    },
              onLongPressEnd: _isOpen
                  ? null
                  : (details) {
                      final snappedSide =
                          snapSide(_dragPosition.dx, mq.size.width);
                      final rawFraction = ((_dragPosition.dy -
                                  (_buttonSize / 2)) -
                              topPadding) /
                          usableHeight;
                      ref
                          .read(quickButtonProvider.notifier)
                          .setPosition(snappedSide, rawFraction);
                      setState(() {
                        _isDragging = false;
                      });
                    },
              onLongPressCancel: () {
                setState(() {
                  _isDragging = false;
                });
              },
              child: AnimatedScale(
                scale: _isDragging ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: _buttonSize,
                  height: _buttonSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isOpen ? Icons.close : Icons.bolt,
                    color: theme.colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanOutItem({
    required BuildContext context,
    required int index,
    required _FanOutItemData item,
    required HandednessSide side,
    required FanOutDirection direction,
    required double buttonCenterX,
    required double buttonCenterY,
    required Size screenSize,
    required ThemeData theme,
  }) {
    final offset = computeFanOutOffset(
      side: side,
      direction: direction,
      index: index,
    );

    final itemCenterX = buttonCenterX + offset.dx;
    final itemCenterY = buttonCenterY + offset.dy;
    const itemRadius = _itemSize / 2;

    final itemAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (index * 25) / 305.0,
        ((index * 25) + 180) / 305.0,
        curve: Curves.easeOut,
      ),
    );

    final circle = Material(
      color: theme.colorScheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          _closeMenu();
          item.onTap();
        },
        child: SizedBox(
          width: _itemSize,
          height: _itemSize,
          child: Icon(
            item.icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
      ),
    );

    final labelCard = Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _closeMenu();
          item.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            item.label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );

    Widget content;
    if (side == HandednessSide.right) {
      // Right edge: label is on the inner side (to the left of circle)
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          labelCard,
          const SizedBox(width: 8),
          circle,
        ],
      );
      return Positioned(
        right: screenSize.width - (itemCenterX + itemRadius),
        top: itemCenterY - itemRadius,
        child: FadeTransition(
          opacity: itemAnimation,
          child: ScaleTransition(
            scale: itemAnimation,
            alignment: Alignment.centerRight,
            child: content,
          ),
        ),
      );
    } else {
      // Left edge: label is on the inner side (to the right of circle)
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          const SizedBox(width: 8),
          labelCard,
        ],
      );
      return Positioned(
        left: itemCenterX - itemRadius,
        top: itemCenterY - itemRadius,
        child: FadeTransition(
          opacity: itemAnimation,
          child: ScaleTransition(
            scale: itemAnimation,
            alignment: Alignment.centerLeft,
            child: content,
          ),
        ),
      );
    }
  }
}

class _FanOutItemData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FanOutItemData({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
