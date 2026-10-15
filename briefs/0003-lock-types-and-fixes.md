# Brief 0003: Lock type options, plus lock fixes

## Context
Brief 0002 gave us the shell and a PIN/fingerprint lock. Bereket wants users to be able to choose how the app is protected, and a code review found some defects in the lock. No new packages.

## Part 1: Lock Types
1. Add an enum `LockMode { appPin, phoneLock, none }` stored in `shared_preferences` (key `lock_mode`). It is a setting, not a secret.
2. Migration: if `lock_mode` is unset but a PIN hash and salt already exist, treat the mode as `appPin` and save it.
3. First launch, with `lock_mode` unset and no PIN: show a new screen `/choose-lock` with three large option cards and one line each:
   - "App PIN": a PIN only for this app. Good on shared phones.
   - "Phone screen lock": use the phone's own fingerprint, PIN or pattern.
   - "No lock": open straight away. I rely on my phone's lock screen.
   Choosing App PIN continues to the existing `/setup-pin` flow. The other two save the mode and go to `/work`. Phone screen lock may only be chosen if the device reports it is secured with a screen lock (`local_auth` `isDeviceSupported()` is true and the device has a credential or biometric set up); if not, show a message that the phone has no screen lock set up and keep the option disabled.
4. `appPin` behaves exactly as in 0002.
5. `phoneLock`: when locked, `/lock` shows a simple screen with the app name and an "Unlock" button, and opens the system prompt automatically using `localAuth.authenticate` with `biometricOnly: false` so the phone's PIN/pattern also works. A cancelled or failed prompt leaves the Unlock button available. No app PIN is stored in this mode.
6. `none`: the app is never locked and never shows `/lock`. The "Lock after", "Use fingerprint" and "Change PIN" settings are hidden.
7. Settings > Security gets a "Lock type" selector with the three modes.
   - `appPin` to `phoneLock` or `none`: first ask for the current PIN (it counts toward the attempt limit, see Part 2), then switch and delete the stored PIN hash and salt completely.
   - `phoneLock` or `none` to `appPin`: go through the existing create-PIN screen; the mode only changes once a PIN is saved.
   - `phoneLock` to `none`, and `none` to `phoneLock`: switch immediately (`phoneLock` requires the device check from item 3).
   - "Lock after" applies to `appPin` and `phoneLock`.
8. Router redirect rules, implemented as one pure function `resolveLockRoute(mode, hasPin, isLocked, location)` with unit tests: mode unset goes to `/choose-lock`; `appPin` without a PIN goes to `/setup-pin`; locked in `appPin` or `phoneLock` goes to `/lock`; `none` never goes to `/lock`; unlocked users on `/lock`, `/setup-pin` or `/choose-lock` go to `/work`. A cold start is always locked in `appPin` and `phoneLock`.

## Part 2: Fixes
9. Biometric re-lock bug: add an `authenticating` flag (in the lock controller) that is true while any `local_auth` prompt is showing. While it is true, the lifecycle observer in `main.dart` must ignore paused/inactive/hidden events and clear `_backgroundedAt` when the prompt finishes. Result: with "Lock after: Immediately", a successful fingerprint or phone-lock unlock must not immediately lock again. Also prevent a second prompt from opening while one is already showing.
10. Persist the wrong-attempt state: store `failedAttempts` and the lockout end time (an absolute timestamp) in `flutter_secure_storage`. On startup, resume any lockout still in the future with the correct remaining seconds; clear it after a correct PIN or when it expires.
11. `verifyCurrentPin` (used by Change PIN and lock type changes) must count wrong attempts and respect the same lockout as the lock screen.
12. `biometricsSupported` must be true only if `canCheckBiometrics` is true AND `getAvailableBiometrics` returns a non-empty list. Hide the "Use fingerprint" toggle otherwise.
13. `setPin` must cancel any running lockout timer, and write the salt and hash so a failure between the two cannot leave a mismatched pair (write the hash and salt as one JSON value under one key, and read old two-key values for migration).

## Tests (`flutter test` must pass)
- `resolveLockRoute` for every combination of mode, hasPin, isLocked and a few locations.
- `LockMode` migration (PIN exists, mode unset gives `appPin`).
- Lockout persistence: after five wrong attempts, a new controller instance created before the end time is still locked out with the right remaining seconds; after the end time it is not.
- Wrong attempts through `verifyCurrentPin` count toward the limit.
- Keep the existing 14 tests passing.

## Do not
- Add packages, a database, or any other feature.
- Change docs other than as stated below.

## Acceptance criteria (Bereket checks on the Pixel 2 XL; to test a fresh install run: `adb shell pm clear org.edcompanion.ed_companion`)
1. Fresh install shows the "choose lock" screen with three options.
2. App PIN: create a PIN; after fully closing and reopening the app it asks for the PIN.
3. Phone screen lock: after locking, the system prompt opens; my fingerprint works, and so does my phone PIN.
4. No lock: the app never asks for anything, and Lock after, Use fingerprint and Change PIN are hidden in Settings.
5. Switching App PIN to No lock asks for the current PIN first and then removes the PIN. Switching back asks me to create a new PIN.
6. With App PIN, fingerprint on and Lock after set to Immediately: leave the app, return, unlock with fingerprint; the app stays unlocked.
7. Enter five wrong PINs, swipe the app away from recents, reopen: the 30-second wait is still running.
8. Wrong current PINs in Change PIN count toward the same five-attempt limit.
9. `flutter analyze` has no issues, `flutter test` passes, and the GitHub Actions run on the push is green and uploads the APK.

## Report and docs
Write `reports/0003-report.md` as in `docs/BRIEF_TEMPLATE.md`. Fill in the real commit hash and the real GitHub Actions result only after you have checked them (the 0002 report said "pending"; correct it to run 38658564878 with its true result). Commit with "0003: lock types and lock fixes", push, add one line to `docs/LOG.md`, and update "Where we are" and "Next up" in `docs/PROJECT_STATE.md` (next: review 0003, then plan module B with Bereket's ideas).
