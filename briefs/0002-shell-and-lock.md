# Brief 0002: Cleanup, app shell and lock screen

## Context
ED Companion is an offline-first Flutter app for ED residents. Brief 0001 gave us a building empty app (Flutter 3.47.7, Riverpod, go_router, Drift, minSdk 24). This brief does three things: small cleanup, the navigation shell (module A), and the PIN/fingerprint lock. No patient data, no database code, no WebView yet.

## Part 1: Cleanup
1. In `app/pubspec.yaml` remove `sqlite3_flutter_libs` and add `drift_flutter`. Do not write database code. Run `flutter pub get`; `flutter analyze` must still pass.
2. In `.github/workflows/build.yml` pin the Flutter action to `flutter-version: '3.47.7'` (keep `cache: true`; drop the channel line if it conflicts).
3. Edit `reports/0001-report.md`: set the commit hash to `cafad1b` and record that the GitHub Actions run 38656101694 completed successfully. Then create and push the git tag `ok-0001` on commit `cafad1b`.

## Part 2: Shell (`app/lib/features/shell/`)
4. Router: `go_router` with `StatefulShellRoute.indexedStack`, two branches: `/work` and `/study`. Bottom `NavigationBar` (Material 3) with two destinations, Work (icon `medical_services_outlined`) and Study (icon `menu_book_outlined`). Keep all tap targets at least 48dp.
5. Work screen: AppBar titled "Work" with two icon buttons: Tools (opens route `/work/tools`, a placeholder screen saying "Tools: coming in module D") and Settings (opens `/settings`). Body: a `PageView` with two pages, page 0 a placeholder "Patients: ward board coming in module B", page 1 a placeholder "Hospital system: coming in module C". Below the `PageView`, a `SegmentedButton` (or equivalent) with the two labels "Patients" and "Hospital". Tapping it animates the `PageView`; swiping the `PageView` updates the button. Each page must stay alive when switched away (`AutomaticKeepAliveClientMixin`), because a WebView will live in page 1 later.
6. Study screen: AppBar titled "Study" with a Settings icon button. Body is a placeholder "Study library: coming in module E".
7. Settings screen (`/settings`), using the `shared_preferences` package, all values persist across restarts:
   - Theme: System / Light / Dark (applies immediately).
   - Text size: Normal / Large / Extra large (text scale 1.0 / 1.15 / 1.3, applied app-wide immediately).
   - Security section (see Part 3).
   - A row "About" opening `/about`.
8. About screen (`/about`): app name, version (read from package info or reuse the existing constant), the line "Decision support only. Verify against the source and your judgment before acting.", and a section titled "Sources" containing the placeholder "Clinical formula sources will be listed here as calculators are added."

## Part 3: Lock (`app/lib/features/shell/lock/`)
9. Add packages: `flutter_secure_storage`, `local_auth`, `shared_preferences`, `crypto`. No other new packages.
10. PIN: 4 to 6 digits. Store only a salted SHA-256 hash and the salt in `flutter_secure_storage`. Put hashing and verifying in one small pure Dart class with unit tests.
11. First launch with no PIN: a "Create a PIN" screen (enter twice, must match), then go to `/work`. Router redirect rules: no PIN set goes to `/setup-pin`; locked goes to `/lock`; otherwise normal. The app is always locked on a cold start.
12. Lock screen (`/lock`): large on-screen number keypad (big buttons, one-handed friendly), dot indicators, delete key. Wrong PIN shows a short error. After 5 wrong attempts, block entry for 30 seconds with a visible countdown; the attempt counter resets after a correct PIN.
13. Fingerprint: Settings toggle "Use fingerprint" (off by default, only shown if the device supports biometrics). When on, the lock screen opens the fingerprint prompt automatically; cancelling it leaves the PIN keypad usable.
14. Auto-lock: Settings option "Lock after" with choices Immediately / 1 minute / 5 minutes / 15 minutes / 30 minutes, default 5 minutes. Use a `WidgetsBindingObserver`: record the time when the app goes to background; on resume, if the elapsed time exceeds the setting, lock. Put the decision in a pure function `shouldLock(now, backgroundedAt, timeout)` with unit tests.
15. Settings > Security also has "Change PIN" (asks for the current PIN, then the new one twice). There is deliberately no "Forgot PIN" in v1: add a note in the About screen saying a forgotten PIN is reset by clearing the app's data in Android settings.
16. Android requirements for `local_auth`: change `MainActivity` to extend `FlutterFragmentActivity` and add the `USE_BIOMETRIC` permission to `AndroidManifest.xml`.

## Tests (`flutter test` must pass)
- PIN hash and verify; wrong PIN fails; two different salts give different hashes.
- `shouldLock` for each timeout choice, including exactly at the limit.
- Widget test: tapping Study in the bottom bar shows the Study placeholder.
- Widget test: tapping "Hospital" in the segmented button shows the Hospital placeholder, tapping "Patients" returns.

## Do not
- Add any database, WebView, networking or sync code.
- Add packages beyond those named here.
- Disable screenshots (no `FLAG_SECURE`).
- Change docs other than as stated below.

## Acceptance criteria (Bereket checks on the Pixel 2 XL)
1. First launch asks to create a PIN, twice; then the Work tab opens.
2. The bottom bar switches Work and Study. In Work, the Patients/Hospital switch works by tapping and by swiping, and stays in sync.
3. The gear opens Settings. Changing theme and text size takes effect immediately and survives closing and reopening the app.
4. Closing and reopening the app asks for the PIN. A wrong PIN is rejected. Five wrong tries give a 30-second wait.
5. With the fingerprint option on, the lock screen shows the fingerprint prompt; cancelling it falls back to the keypad.
6. "Lock after: Immediately" locks as soon as I leave and return; "5 minutes" does not lock if I return within a minute.
7. About shows the version, the disclaimer and the Sources placeholder.
8. `flutter analyze` has no issues, `flutter test` passes, and the GitHub Actions run on the push is green and uploads the APK.

## Report and docs
Write `reports/0002-report.md` as in `docs/BRIEF_TEMPLATE.md`, and list the packages added with their versions and the install command I should use for the APK. Commit with "0002: cleanup, shell and lock", push, update `docs/LOG.md` with one line, and in `docs/PROJECT_STATE.md` update "Where we are" to say Milestone M0 is complete and brief 0002 (shell and lock) is done pending review, and "Next up" to say: review 0002, then module B (patients and notes) design.
