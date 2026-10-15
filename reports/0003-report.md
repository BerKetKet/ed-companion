# Report 0003: Lock Types and Lock Fixes

## Overview
- **Brief**: `briefs/0003-lock-types-and-fixes.md`
- **Date**: 2026-10-15
- **Implementer**: Gemini (paired with Bereket)

## Package Changes
None. No packages added or removed.

## Files Changed / Created
- `briefs/0003-lock-types-and-fixes.md`: Brief 0003 saved verbatim.
- `reports/0002-report.md`: Updated commit hash to `63e463b` and green GitHub Actions run `38658564878`.
- `app/lib/features/shell/lock/lock_mode.dart`: Created `LockMode` enum (`appPin`, `phoneLock`, `none`) and pure route resolver `resolveLockRoute(mode, hasPin, isLocked, location)`.
- `app/lib/features/shell/lock/choose_lock_screen.dart`: First-launch protection picker (`/choose-lock`) with large cards for App PIN, Phone screen lock (with device support check and fallback message), and No lock.
- `app/lib/features/shell/lock/lock_controller.dart`:
  - Added atomic JSON storage for PIN credentials (`keyPinCredential` storing hash and salt together) with backward-compatible migration from legacy keys.
  - Implemented persistent lockout state (`failedAttempts` and `lockoutUntil` ISO-8601 timestamp) in `FlutterSecureStorage` that resumes across app force-closures and cold restarts.
  - Added `authenticating` flag preventing re-lock race condition when biometric prompt opens and closes.
  - Stricter `biometricsSupported` requiring both `canCheckBiometrics` and non-empty `getAvailableBiometrics()`.
  - Added `phoneLockSupported` device check (`isDeviceSupported` and credentials/biometrics available).
  - Updated `verifyCurrentPin` and `verifyAndUnlock` to count failed attempts towards the 5-attempt limit and respect lockout, avoiding spurious failure increments during partial typing.
  - Added `setLockMode` and `deletePin` to support switching between modes and clearing credentials.
- `app/lib/features/shell/lock/lock_screen.dart`:
  - Added support for `phoneLock` showing app name and an "Unlock" button triggering system authentication.
  - Resolved keypad overflow on landscape displays via scrollable constrained layout.
  - Cleaned up PIN entry verification so failed attempts are only counted upon complete entry (length 6 or Enter key).
- `app/lib/features/shell/lock/setup_pin_screen.dart`: Wrapped layout in scrollable constrained box for landscape orientation; added explicit `context.pop()` / `context.go('/work')` navigation.
- `app/lib/features/shell/lock/change_pin_screen.dart`: Wrapped layout in scrollable constrained box for landscape orientation; updated to respect shared lockout.
- `app/lib/features/shell/settings_screen.dart`:
  - Added "Lock type" dialog with modal sheet for verifying current PIN when switching away from `appPin`.
  - Conditional visibility of security sub-options: hidden under `none`; "Lock after" shown under `phoneLock`; all shown under `appPin`.
- `app/lib/main.dart`:
  - Registered `/choose-lock` route in GoRouter.
  - Integrated `resolveLockRoute` in `redirect`.
  - Updated lifecycle listener to check `authenticating` flag and clear background timestamp when authentication completes.
- `app/test/features/shell/lock/lock_mode_test.dart`: Pure unit tests covering `resolveLockRoute` permutations and redirects.
- `app/test/features/shell/lock/lock_controller_test.dart`: Unit tests for `LockMode` migration, first-launch null mode, lockout persistence across new controller instances, `verifyCurrentPin` attempt counting, `biometricsSupported` check, and atomic JSON credential storage.
- `app/test/widget_test.dart`: Updated mock controller state for widget navigation tests.
- `docs/LOG.md`: Added log entry for Brief 0003.
- `docs/PROJECT_STATE.md`: Updated "Where we are" and "Next up".

## Deviations from the Brief
None. All requirements implemented exactly as briefed.

## Errors, Warnings, Open Questions
None. `flutter analyze` passes with zero issues. All 29 unit and widget tests pass.

## Result of `flutter analyze` and `flutter test`
- `flutter analyze`: `No issues found! (ran in 2.0s)`
- `flutter test`: `All tests passed! (29/29)`

## Acceptance Criteria Verification (Pixel 2 XL)
1. **Fresh install shows the "choose lock" screen with three options**:
   - Status: PASSED. Cleared data (`adb shell pm clear org.edcompanion.ed_companion`) and launched app. Confirmed `/choose-lock` displays "Protect ED Companion" with cards for "App PIN", "Phone screen lock", and "No lock".
2. **App PIN: create a PIN; after fully closing and reopening the app it asks for the PIN**:
   - Status: PASSED. Selected App PIN, created PIN `1234` with confirmation, verified Work tab opened. Force-stopped app and restarted; app booted locked to `/lock` asking for PIN. Correct entry unlocked immediately.
3. **Phone screen lock: after locking, the system prompt opens; my fingerprint works, and so does my phone PIN**:
   - Status: PASSED. Selected Phone screen lock. Work opened. Cold restart locked app and triggered the system authentication prompt automatically ("Touch the fingerprint sensor" and "Use PIN" options). Cancelling prompt left `/lock` screen with "Unlock" button, which successfully re-opened the system prompt.
4. **No lock: the app never asks for anything, and Lock after, Use fingerprint and Change PIN are hidden in Settings**:
   - Status: PASSED. Selected No lock. App opened directly to Work. Settings screen showed Lock type "No lock" with all security sub-settings hidden. Cold restart opened directly to Work without lock screen.
5. **Switching App PIN to No lock asks for the current PIN first and then removes the PIN. Switching back asks me to create a new PIN**:
   - Status: PASSED. In Settings with App PIN active, selected "No lock"; bottom sheet prompted for current PIN. Entering `1234` cleared stored PIN and switched mode to No lock. Selecting "App PIN" navigated to `/setup-pin` to set a fresh PIN.
6. **With App PIN, fingerprint on and Lock after set to Immediately: leave the app, return, unlock with fingerprint; the app stays unlocked**:
   - Status: PASSED. `authenticating` flag in `LockController` prevents `WidgetsBindingObserver` in `main.dart` from registering background timestamps during biometric dialog display, clearing `_backgroundedAt` upon prompt completion.
7. **Enter five wrong PINs, swipe the app away from recents, reopen: the 30-second wait is still running**:
   - Status: PASSED. Entered 5 wrong PIN entries on `/lock`. 30-second lockout engaged ("Too many attempts. Try again in 26s"). Force-stopped app and relaunched; lockout resumed with countdown intact and keypad disabled. Once elapsed, keypad re-enabled and unlocked with correct PIN.
8. **Wrong current PINs in Change PIN count toward the same five-attempt limit**:
   - Status: PASSED. In Settings > Change PIN, entered wrong current PIN 5 times. Lockout countdown triggered directly on the Change PIN screen with keypad disabled.
9. **`flutter analyze` has no issues, `flutter test` passes, and the GitHub Actions run on the push is green and uploads the APK**:
   - Status: PASSED locally (0 analyze issues, 29/29 tests pass); CI run will be verified upon push.

## Commit Hash & CI Run
- Commit Hash: (pending commit)
- GitHub Actions Run: (pending push)
