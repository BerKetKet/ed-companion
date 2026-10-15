import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks number of active PopupRoutes (dialogs, bottom sheets, menus).
class ModalCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;

  void decrement() {
    if (state > 0) state--;
  }
}

final modalCountProvider = NotifierProvider<ModalCountNotifier, int>(
  ModalCountNotifier.new,
);

/// NavigatorObserver that monitors open PopupRoutes and updates modalCountProvider.
class ModalTrackerObserver extends NavigatorObserver {
  final Ref ref;

  ModalTrackerObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PopupRoute) {
      ref.read(modalCountProvider.notifier).increment();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PopupRoute) {
      ref.read(modalCountProvider.notifier).decrement();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is PopupRoute) {
      ref.read(modalCountProvider.notifier).decrement();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute is PopupRoute) {
      ref.read(modalCountProvider.notifier).decrement();
    }
    if (newRoute is PopupRoute) {
      ref.read(modalCountProvider.notifier).increment();
    }
  }
}
