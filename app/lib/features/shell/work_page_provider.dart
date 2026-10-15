import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier tracking the selected page in the Work tab (0: Patients, 1: Hospital).
class WorkPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int page) {
    if (page >= 0 && page <= 1 && state != page) {
      state = page;
    }
  }
}

final workPageProvider = NotifierProvider<WorkPageNotifier, int>(
  WorkPageNotifier.new,
);
