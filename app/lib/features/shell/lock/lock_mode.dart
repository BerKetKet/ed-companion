/// The available lock modes for ED Companion.
enum LockMode {
  appPin('App PIN'),
  phoneLock('Phone screen lock'),
  none('No lock');

  const LockMode(this.label);
  final String label;

  static LockMode? fromString(String? val) {
    if (val == null) return null;
    return LockMode.values.firstWhere(
      (e) => e.name == val,
      orElse: () => LockMode.appPin,
    );
  }
}

/// Pure router redirect decision function based on security state.
///
/// Returns target route string to redirect to, or null if current location is allowed.
String? resolveLockRoute({
  required LockMode? mode,
  required bool hasPin,
  required bool isLocked,
  required String location,
}) {
  // Mode unset goes to /choose-lock
  if (mode == null) {
    return location == '/choose-lock' ? null : '/choose-lock';
  }

  // appPin without a PIN goes to /setup-pin
  if (mode == LockMode.appPin && !hasPin) {
    return location == '/setup-pin' ? null : '/setup-pin';
  }

  // Locked in appPin or phoneLock goes to /lock
  if ((mode == LockMode.appPin || mode == LockMode.phoneLock) && isLocked) {
    return location == '/lock' ? null : '/lock';
  }

  // none never goes to /lock; unlocked users on /lock or /choose-lock go to /work
  if (location == '/lock' || location == '/choose-lock') {
    return '/work';
  }

  // /setup-pin: users who already have a PIN go to /work
  if (location == '/setup-pin' && hasPin) {
    return '/work';
  }

  return null;
}
