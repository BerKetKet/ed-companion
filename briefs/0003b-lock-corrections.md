Brief 0003b: lock corrections (from Claude's code review of 0003)

Context
Brief 0003 is implemented. A code review found six defects in the lock code. No new packages. Save this brief verbatim as briefs/0003b-lock-corrections.md.

Goal
Fix the defects below. Change nothing else.

Do
1. Stop the free PIN-guessing oracle.
   a. Remove the recordFailure parameter from verifyAndUnlock and verifyCurrentPin in lock_controller.dart. Every wrong verify counts as a failed attempt, always.
   b. Store the PIN length in the credential: the JSON value under keyPinCredential becomes {hash, salt, len}. setPin writes len. Credentials without len (legacy) stay readable; after the first successful verify of such a credential, rewrite it with len set to the length of the entered PIN.
   c. Add pinLength (int?, null when unknown) to AppLockState, filled in initialize() and setPin().
   d. In lock_screen.dart and in the _VerifyCurrentPinSheet in settings_screen.dart: when pinLength is known, auto-verify only when the typed length equals pinLength, and do not accept more digits than pinLength. When pinLength is null, never auto-verify; the Enter key verifies (and counts). Enter with fewer digits than pinLength also verifies and counts.
   e. change_pin_screen.dart already verifies only via Continue/Enter; keep that.
2. In initialize(), set phoneLockSupported = isDeviceSupported only (remove the extra canCheck/available condition). Leave biometricsSupported as it is. Before changing, read the local_auth_android source in ~/.pub-cache and state in the report what isDeviceSupported returns on a phone that has only a PIN or pattern.
3. First-launch trap: in setup_pin_screen.dart, when the screen cannot pop (first launch flow), show a TextButton "Choose a different lock type" under the keypad. It calls a new controller method clearLockMode() (removes lock_mode from shared_preferences and sets lockMode to null in state); the router then redirects to /choose-lock. Do not show this button when the screen was pushed from Settings.
4. Change setLockMode(mode) to setLockMode(mode, {bool unlock = false}); when unlock is true it sets isLocked to false in the same state update as the mode. choose_lock_screen.dart uses setLockMode(LockMode.phoneLock, unlock: true) and no longer calls unlock() separately.
5. Phone screen lock escape: add controller method refreshDeviceSupport() that re-reads isDeviceSupported and updates phoneLockSupported. In lock_screen.dart, in phoneLock mode, call it in initState before the automatic prompt and again after any cancelled or failed prompt. If it reports false, replace the Unlock button with the text "This phone no longer has a screen lock. Set one in Android settings, or switch to No lock." and a button "Switch to No lock" that calls setLockMode(LockMode.none). If true, behave exactly as now.
6. In lock_mode.dart, remove the unreachable duplicate appPin-without-PIN branch of resolveLockRoute. Behavior must not change; the existing resolveLockRoute tests must still pass.

Tests (flutter test must pass; keep the existing 29 passing, adjusting only where the removed recordFailure parameter requires)
- Every wrong verifyAndUnlock and verifyCurrentPin counts toward the limit, for 4, 5 and 6 digit entries.
- setPin stores len; a legacy credential without len is upgraded after a successful verify.
- phoneLockSupported is true when isDeviceSupported is true and there are no biometrics.
- refreshDeviceSupport updates the state.
- clearLockMode returns lockMode to null and resolveLockRoute then gives /choose-lock.
- setLockMode(phoneLock, unlock: true) leaves isLocked false.

Do not
- Add packages or other features, or touch docs other than as stated below.
- Change the 5-attempt, 30-second lockout rule or the PIN length range of 4 to 6.

Acceptance criteria (Bereket checks on the Pixel 2 XL)
1. With a 4-digit PIN set, entering a wrong 4-digit PIN five times starts the 30-second wait. A correct PIN still unlocks as soon as its last digit is typed.
2. With a 6-digit PIN set, behavior is the same, and a 7th digit cannot be typed.
3. Fresh install (adb shell pm clear org.edcompanion.ed_companion): choose App PIN, swipe the app away without saving a PIN, reopen. The Set PIN screen shows "Choose a different lock type"; tapping it returns to the three-option screen.
4. Fresh install: choose Phone screen lock. The app opens on Work with no system prompt appearing.
5. Phone screen lock still unlocks with fingerprint and with the phone PIN as before.
6. Settings > Lock type: Phone screen lock is selectable (the Pixel has a lock set).
7. flutter analyze has no issues, flutter test passes, the GitHub Actions run on the push is green and uploads the APK.

Report
Write reports/0003b-report.md as in docs/BRIEF_TEMPLATE.md, including the isDeviceSupported finding from item 2 and the real commit hash and real CI result (check them before writing). Commit "0003b: lock corrections", push, add one line to docs/LOG.md, and set "Where we are" in docs/PROJECT_STATE.md to "0003b done, awaiting Claude review". Do not tag ok-0003 yet.
