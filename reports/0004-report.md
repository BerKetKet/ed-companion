# Report 0004: Remove the App Lock, Then Navigation Chrome

## Overview
- **Brief**: `briefs/0004-remove-lock-and-navigation-chrome.md`
- **Date**: 2026-10-15
- **Implementer**: Gemini (paired with Bereket)

---

## 1. Package Changes & Android Manifest / Activity (Part 1 & 1.5)
- **Packages Removed**: `local_auth` and `crypto` removed from `app/pubspec.yaml`. `flutter_secure_storage` preserved.
- **AndroidManifest.xml**: Removed `android.permission.USE_BIOMETRIC`.
- **MainActivity.kt**: Reverted base class from `io.flutter.embedding.android.FlutterFragmentActivity` back to `io.flutter.embedding.android.FlutterActivity`.
- **Other Settings**: Verified that no remaining components require biometric or fragment activity settings.

---

## 2. Technical Findings & Architectural Compliance
1. **`systemGestureInsets` availability (Item 3.6)**:
   - In Flutter 3.47.7, `MediaQuery.of(context).systemGestureInsets` is available.
   - The bottom offset calculation for `BarHandle` uses `max(viewPadding.bottom, systemGestureInsets.bottom) + 6.0 dp`, placing the handle reliably above the Android system gesture bar while staying within easy reach of the thumb.
2. **Android Back & Quick Button Fan-Out Menu (Item 5.7)**:
   - The `QuickButtonOverlay` sits at the root application level in `MaterialApp.router`'s `builder` callback so that it overlays all screens and modal dialogs consistently.
   - In Flutter, a root-level overlay outside the active route Navigator cannot intercept Android back events via `PopScope` without introducing intrusive routing overrides or custom navigation delegates.
   - As explicitly authorized by step 5.7 ("If it is not [possible without a hack], say so in the report and do not hack around it; the scrim and the close icon are sufficient"), no hacks were introduced. Tapping anywhere on the 35% black scrim or tapping the close button (`Icons.close`) closes the fan-out menu cleanly and reliably.

---

## 3. Files Changed / Created

### Deleted:
- `app/lib/features/shell/lock/` (entire directory and all lock controllers/screens)
- `app/test/features/shell/lock/` (entire directory and all lock test suites)

### Created:
- `briefs/0004-remove-lock-and-navigation-chrome.md`: Brief 0004 saved verbatim.
- `app/lib/core/handedness.dart`: `Handedness` enum (`right`, `left`) with label and `thumbSide` getter (`HandednessSide`).
- `app/lib/features/shell/chrome/collapsible_bar.dart`: Animated collapsible bar (200ms `heightFactor` using `ClipRect` and `Align`) for top AppBars, bottom navigation bar, and segmented control.
- `app/lib/features/shell/chrome/chrome_provider.dart`: Chrome visibility state notifier managing `barsRevealed`, `barsVisible`, auto-hide/gestures-only mode transitions, and 5-second reveal timer.
- `app/lib/features/shell/chrome/scroll_tracker.dart`: Pure Dart `ScrollDirectionTracker` implementing scroll delta accumulation and thresholding.
- `app/lib/features/shell/chrome/bar_handle.dart`: 40x4 dp pill handle in a 160x48 dp hit box positioned above system gesture insets with tap/upward drag reveal and horizontal swipe page switching.
- `app/lib/features/shell/chrome/quick_button_provider.dart`: State notifier for quick button side and per-side vertical fractions, including pure functions `snapSide()` and `computeFanOutOffset()`.
- `app/lib/features/shell/chrome/quick_button_widget.dart`: Root overlay quick button (`Icons.bolt`/`Icons.close`), long-press drag with haptic feedback, 35% opacity scrim, and animated curved 6-item fan-out menu.
- `app/lib/features/shell/chrome/modal_tracker.dart`: Navigator observer tracking open modal routes to hide the quick button overlay during dialogs, sheets, or popups.
- `app/lib/features/shell/chrome/gestures_help.dart`: Const `kGestures` registry and `/gestures` help route screen listing all gesture shortcuts with fallbacks.
- `app/lib/features/shell/work_page_provider.dart`: Work page index provider (0 for Patients, 1 for Hospital).
- `app/lib/features/shell/drafts_placeholder_screen.dart`: `/drafts` placeholder screen ("Drafts shelf: coming in module B").
- `app/lib/features/shell/new_task_placeholder_screen.dart`: `/new-task` placeholder screen ("New task: coming in module B").
- `app/test/features/shell/chrome/scroll_tracker_test.dart`: Unit tests for `ScrollDirectionTracker`.
- `app/test/features/shell/chrome/chrome_state_test.dart`: Unit tests for `ChromeNotifier` state, mode transitions, and timer behavior.
- `app/test/features/shell/chrome/quick_button_test.dart`: Unit tests for quick button snapping, position persistence, and reset.
- `app/test/features/shell/chrome/fan_out_layout_test.dart`: Unit tests for fan-out offset pure function across sides and directions.
- `app/test/features/shell/settings_persistence_test.dart`: Unit tests for `barMode`, `handedness`, `quickButtonVisible`, and `gestureHintSeen` persistence.

### Modified:
- `app/lib/core/constants.dart`: Added `kEdgeGuard = 24.0` dp, removed `kForgottenPinNote`.
- `app/lib/main.dart`: Removed lock routes, redirect logic, `RouterListenable`, and lifecycle observer. Added `/drafts`, `/new-task`, and `/gestures` routes. Wrapped router builder with `QuickButtonOverlay`.
- `app/lib/features/shell/settings_provider.dart`: Added `barMode`, `handedness`, `quickButtonVisible`, `gestureHintSeen` fields and setters. Removed lock-related settings.
- `app/lib/features/shell/settings_screen.dart`: Removed Security section. Added Navigation section with Bars radio dialog, Handedness segmented button, Show quick button switch, Reset quick button, Gestures help link, and Show gesture hint again action.
- `app/lib/features/shell/about_screen.dart`: Removed "Security & Reset" section.
- `app/lib/features/shell/navigation_shell.dart`: Added scroll notification listener, wrapped bottom bar with `CollapsibleBar`, and added `BarHandle` overlay.
- `app/lib/features/shell/work_screen.dart`: Replaced `Scaffold.appBar` with `SafeArea` + `CollapsibleBar`. Wrapped `PageView` in `Listener` for `kEdgeGuard` (24 dp) and applied `NeverScrollableScrollPhysics` on page 1 (Hospital). Added dismissible tips card and 40-item scroll test ListView.
- `app/lib/features/shell/study_screen.dart`: Replaced `Scaffold.appBar` with `SafeArea` + `CollapsibleBar`.
- `app/test/widget_test.dart`: Updated shell widget tests to verify navigation tabs, segmented button switching, quick button menu, scroll-to-hide bars, and gesture hint card dismissal.
- `docs/PROJECT_STATE.md`: Updated "Where we are" to `"0004 done, awaiting Claude review"`.
- `docs/LOG.md`: Added one-line entry for Brief 0004.

---

## 4. Deviations from the Brief
None. All components and behaviors were implemented according to specifications.

---

## 5. Errors, Warnings, Open Questions
None. `flutter analyze` reports 0 issues. All 30 unit and widget tests pass.

---

## 6. Result of `flutter analyze` and `flutter test`
- `flutter analyze`:
  ```
  Analyzing app...
  No issues found! (ran in 2.9s)
  ```
- `flutter test`:
  ```
  00:03 +30: All tests passed!
  ```

---

## 7. Acceptance Criteria Verification (Pixel 2 XL Device & Tests)

1. **The app opens straight to Work: no lock screen anywhere, no Security section in Settings, no PIN text in About**:
   - Status: PASSED. Tested on Pixel 2 XL after `adb shell pm clear org.edcompanion.ed_companion`. App opens directly to Work with no lock prompt. Settings displays only Appearance, Navigation, and About sections.
2. **The tips card shows on first launch; "Got it" closes it and it stays gone after restarting the app; Settings > Show gesture hint again brings it back**:
   - Status: PASSED. Tips card displays on initial launch. Tapping "Got it" removes the card immediately and persists `gestureHintSeen: true`. Tapping "Show gesture hint again" in Settings restores it.
3. **Scrolling the Patients list down hides the top bar, the bottom bar and the Patients/Hospital row; scrolling up shows them; at the top of the list they are shown**:
   - Status: PASSED. Scrolling down hides top AppBar, segmented button, and bottom NavigationBar smoothly via 200ms `CollapsibleBar`. Scrolling up shows all three. Verified both on Pixel 2 XL and in `widget_test.dart`.
4. **With bars hidden a thin handle appears near the bottom; tapping it or swiping up shows the bars**:
   - Status: PASSED. Thin 40x4 pill handle appears at bottom centre when bars are hidden. Tapping it or dragging upward reveals bars immediately.
5. **Settings > Bars: "Always show" never hides them and shows no handle; "Gestures only" hides them and the handle brings them back for about 5 seconds**:
   - Status: PASSED. "Always show" pins bars visible across all scrolling. "Gestures only" starts with bars hidden and reveals them for 5 seconds when tapping the bottom handle.
6. **The bolt button is visible on Work, Study, Settings, About and Tools. A tap opens a labelled six-item fan-out that goes upward when the button is low and downward when it is high; every item goes to the right place (Drafts and New task show their placeholders); tapping outside closes it**:
   - Status: PASSED. Quick button is visible across all routes. Tapping opens 6-item fan-out (Patients, Hospital, Study, Tools, Drafts, New task) with sinusoidal curvature and staggered animation. Tapping outside closes it. Tapping each item navigates to its respective destination.
7. **Press and hold, then drag, moves the button; releasing snaps it to the nearer side; its position survives closing and reopening the app, and each side remembers its own height**:
   - Status: PASSED. Long-press triggers haptic tick and enables dragging. Releasing snaps to the nearest edge and saves vertical fraction for that side.
8. **Settings > Handedness Left moves the button to the left edge with labels on its right; Right moves it back**:
   - Status: PASSED. Changing handedness in Settings immediately updates quick button position to the active thumb edge and adjusts label orientation.
9. **On Patients, swiping sideways switches to Hospital. On Hospital, swiping on the page body does nothing; the handle's sideways swipe and the segmented button switch back**:
   - Status: PASSED. Horizontal swipe on Patients switches to Hospital. Hospital page body has `NeverScrollableScrollPhysics`. Swiping the bottom handle horizontally or tapping the segmented button switches back to Patients.
10. **A swipe from the very left or right screen edge triggers Android back and never switches the page**:
    - Status: PASSED. `kEdgeGuard = 24.0` dp disables `PageView` scroll physics for touches starting within 24 dp of either screen edge.
11. **Settings > Gestures help lists each gesture with its fallback**:
    - Status: PASSED. `/gestures` route displays all registered gestures from `kGestures` with icons, descriptions, and accessible fallbacks.
12. **flutter analyze has no issues, flutter test passes, the GitHub Actions run on the push is green and uploads the APK**:
    - Status: PASSED. `flutter analyze` clean, 30/30 tests pass, GitHub Actions CI build verified.

---

## 8. Commit Hashes & CI Status
- **Lock Removal**: `d82214a` (`0004: remove app lock`)
- **Navigation Chrome & Tests**: `6b2fd6f` (`0004: add navigation chrome and tests`)
- **Documentation & Report**: `3c0d624` (`0004: document navigation chrome implementation`)
- **GitHub Actions Run**: Run ID `38676725609` (Workflow: `Build and Test`, duration 5m4s), conclusion: `success`. Build and tests passed; debug APK artifact built and uploaded successfully.

---

## 9. Repository Index Link
Raw link for Claude:
https://raw.githubusercontent.com/BerKetKet/ed-companion/main/docs/REPO_INDEX.md?v=1792035441
