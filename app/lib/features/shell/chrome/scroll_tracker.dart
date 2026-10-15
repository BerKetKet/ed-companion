/// Tracks scroll updates to show or hide collapsible navigation chrome.
class ScrollDirectionTracker {
  double _accumulatedDownward = 0.0;
  double _accumulatedUpward = 0.0;

  /// Updates tracker state with the latest [scrollDelta] and current scroll [pixels].
  ///
  /// Returns:
  /// - `true` to show bars
  /// - `false` to hide bars
  /// - `null` for no change
  ///
  /// Rules:
  /// - `pixels <= 0` returns `true`
  /// - Accumulated downward scrolling of at least 24 dp while `pixels > 56` returns `false`
  /// - Accumulated upward scrolling of at least 12 dp returns `true`
  /// - Accumulators reset when scroll direction changes
  bool? update(double scrollDelta, double pixels) {
    if (pixels <= 0) {
      _accumulatedDownward = 0.0;
      _accumulatedUpward = 0.0;
      return true;
    }

    if (scrollDelta > 0) {
      // Downward scrolling
      _accumulatedUpward = 0.0;
      if (pixels > 56) {
        _accumulatedDownward += scrollDelta;
        if (_accumulatedDownward >= 24.0) {
          _accumulatedDownward = 0.0;
          return false;
        }
      } else {
        _accumulatedDownward = 0.0;
      }
      return null;
    } else if (scrollDelta < 0) {
      // Upward scrolling
      _accumulatedDownward = 0.0;
      _accumulatedUpward += -scrollDelta;
      if (_accumulatedUpward >= 12.0) {
        _accumulatedUpward = 0.0;
        return true;
      }
      return null;
    }

    return null;
  }

  /// Resets all accumulated scroll deltas.
  void reset() {
    _accumulatedDownward = 0.0;
    _accumulatedUpward = 0.0;
  }
}
