/// Supported auto-lock timeout durations.
enum AutoLockTimeout {
  immediately(Duration.zero, 'Immediately'),
  oneMinute(Duration(minutes: 1), '1 minute'),
  fiveMinutes(Duration(minutes: 5), '5 minutes'),
  fifteenMinutes(Duration(minutes: 15), '15 minutes'),
  thirtyMinutes(Duration(minutes: 30), '30 minutes');

  const AutoLockTimeout(this.duration, this.label);

  final Duration duration;
  final String label;

  /// Helper to parse from storage string (or fallback to fiveMinutes).
  static AutoLockTimeout fromString(String? value) {
    return AutoLockTimeout.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AutoLockTimeout.fiveMinutes,
    );
  }
}

/// Pure function to decide if the app should lock on resume based on elapsed time.
bool shouldLock(
  DateTime now,
  DateTime? backgroundedAt,
  AutoLockTimeout timeout,
) {
  if (backgroundedAt == null) {
    return false;
  }
  if (now.isBefore(backgroundedAt)) {
    return false;
  }
  if (timeout == AutoLockTimeout.immediately) {
    return true;
  }
  final elapsed = now.difference(backgroundedAt);
  return elapsed >= timeout.duration;
}
