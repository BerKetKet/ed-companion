Brief 0004: Remove the app lock, then navigation chrome

Context
ED Companion is an offline-first Flutter app for ED residents (read docs/PROJECT_STATE.md, docs/ARCHITECTURE.md and docs/DECISIONS.md first; the section "UI conventions" in ARCHITECTURE.md and the entries "app lock removed" and "navigation chrome" in DECISIONS.md apply here). Bereket decided to remove the app lock entirely: the app is open to anyone who holds the phone. Then we build the navigation chrome. Brief 0003b (lock corrections) was just finished; this brief supersedes the lock work. Save this brief verbatim as briefs/0004-remove-lock-and-navigation-chrome.md.

Part 0: Prepare
0.1 Run git status. Bereket has copied updated files into docs/ and GEMINI.md. Commit only those files as "docs: reconcile docs with VISION.md, record lock removal". Read the new docs and GEMINI.md.
0.2 Create and push the git tag lock-last-version on the current HEAD (the last commit that still contains the lock).

Part 1: Remove the lock completely
1.1 Delete the folder app/lib/features/shell/lock/ and the folder app/test/features/shell/lock/.
1.2 main.dart: remove RouterListenable, the redirect, the lock routes (/choose-lock, /setup-pin, /lock, /change-pin), the lock initialization in main(), and the WidgetsBindingObserver auto-lock code. EdCompanionApp can become a plain ConsumerWidget. Keep the theme, text scale and the shared_preferences override.
1.3 settings_provider.dart: remove useFingerprint, autoLockTimeout and their keys. settings_screen.dart: remove the whole Security section, the lock type picker and the verify-PIN sheet.
1.4 about_screen.dart: remove the "Security & Reset" section. core/constants.dart: remove kForgottenPinNote.
1.5 pubspec.yaml: remove local_auth and crypto. Keep flutter_secure_storage (reserved for the Gemini key; do not use it yet). AndroidManifest.xml: remove the USE_BIOMETRIC permission. MainActivity.kt: change the base class back from FlutterFragmentActivity to FlutterActivity. If anything else still needs the old setting, say so in the report instead of improvising.
1.6 Do not write any migration for old stored lock values. Bereket will clear the app data on his phone.
1.7 Fix tests: remove the lock overrides from test/widget_test.dart; keep its two tests passing.

Part 2: Settings model and handedness
2.1 Create app/lib/core/handedness.dart: enum Handedness { right, left } with a label, plus a helper that gives the thumb side (right-handed: the right edge, left-handed: the left edge). All thumb-reach controls use this.
2.2 In settings_provider.dart add, all persisted in shared_preferences: barMode (enum BarMode { alwaysShow, autoHide, gesturesOnly }, labels "Always show", "Auto-hide", "Gestures only", default autoHide, key bar_mode); handedness (default right, key handedness); quickButtonVisible (bool, default true, key quick_button_visible); gestureHintSeen (bool, default false, key gesture_hint_seen), with setters.
2.3 Create app/lib/features/shell/chrome/quick_button_provider.dart: a Riverpod notifier holding side (left or right) and a vertical position as a fraction 0 to 1 for each side, stored as quick_side, quick_dy_left, quick_dy_right. Defaults: the side from handedness; fraction 0.65 for both. Changing handedness in Settings sets the side to the handedness side and uses that side's saved fraction. A reset method restores the defaults.
2.4 Add core/constants.dart: kEdgeGuard = 24.0 (dp).

Part 3: Collapsible bars, handle, auto-hide
3.1 Create app/lib/features/shell/chrome/collapsible_bar.dart: a widget CollapsibleBar(visible, edge, child) that animates (200 ms) between full height and zero using ClipRect, Align with heightFactor and TweenAnimationBuilder, so the space is given back to the content and a hidden bar receives no taps. Use it for: the top app bar of Work and Study, the NavigationBar in navigation_shell.dart, and the Patients/Hospital segmented row in work_screen.dart.
3.2 Work and Study: stop using Scaffold.appBar. Body becomes SafeArea(bottom: false) containing a Column of CollapsibleBar(AppBar with primary: false) and the Expanded content. The Tools and Settings buttons and titles stay exactly as they are. Tools, Settings, About and the new placeholder screens keep their normal AppBar and are not affected by hiding.
3.3 Create chrome_provider.dart: a Riverpod notifier with a boolean barsRevealed and a derived value barsVisible: true if barMode is alwaysShow, otherwise barsRevealed. When barMode changes: autoHide sets barsRevealed true, gesturesOnly sets it false. Methods: hide(), show(), reveal(). In gesturesOnly mode, reveal() starts a 5 second timer that hides the bars again; any later reveal() restarts it. Switching to another branch (Work or Study) shows the bars.
3.4 Create scroll_tracker.dart: a pure Dart class ScrollDirectionTracker with update(scrollDelta, pixels) that returns true (show), false (hide) or null (no change). Rules: pixels <= 0 returns true; accumulated downward scrolling of at least 24 dp while pixels > 56 returns false; accumulated upward scrolling of at least 12 dp returns true; the accumulators reset when the direction changes.
3.5 In navigation_shell.dart wrap the shell body in a NotificationListener<ScrollUpdateNotification>. Only notifications whose metrics.axis is vertical are fed to the tracker; horizontal ones (the PageView) are ignored. Act only in autoHide mode. Return false from the callback so nothing is swallowed.
3.6 Create bar_handle.dart and place it in the shell as an overlay at the bottom centre, shown only when barMode is not alwaysShow and the bars are hidden. Visible part: a pill 40 dp by 4 dp. Hit area: 160 dp by 48 dp, transparent, positioned above the system gesture area: bottom offset = the larger of MediaQuery viewPadding.bottom and systemGestureInsets.bottom, plus 6 dp (if systemGestureInsets is unavailable in this Flutter version, use viewPadding.bottom plus 24 dp and say so in the report). Gestures on the handle: tap or upward drag calls reveal(); a horizontal drag of at least 40 dp, when the current branch is Work, switches the Patients/Hospital page (drag left goes to Hospital, drag right goes to Patients).
3.7 So that scrolling can be tested now: in work_screen.dart replace the Patients placeholder with a ListView whose first item is the existing text "Patients: ward board coming in module B" followed by 40 rows labelled "Scroll test row 1" to "Scroll test row 40" (obviously fake). Keep the Hospital placeholder text exactly as it is.

Part 4: Work page state and swipe rules
4.1 Lift the Patients/Hospital page index out of WorkScreen into a provider workPageProvider (int, 0 or 1). WorkScreen listens to it and animates its PageController; swiping and the segmented button update it.
4.2 Hospital page rule: when the current page is 1 (Hospital), the PageView physics is NeverScrollableScrollPhysics, so a sideways swipe on the page body does nothing (a WebView will live there later). On page 0 the swipe works as today. The segmented button and the handle's sideways drag always work.
4.3 Edge guard: wrap the PageView in a Listener that notes pointer-down positions; if a touch starts within kEdgeGuard of the left or right screen edge, the PageView physics are NeverScrollable until that pointer is released or cancelled. No other app gesture may start in those edges.

Part 5: Quick button and fan-out menu (all in features/shell/chrome/)
5.1 The quick button is an app-level overlay: in MaterialApp.router builder, wrap the child in a Stack and add the overlay above it, so it appears on every screen. Keep the existing text scale wrapper. Navigate with ref.read(routerProvider), not a BuildContext.
5.2 Hide the overlay while a dialog, bottom sheet or popup menu is open: add a NavigatorObserver (modal_tracker.dart) that counts open PopupRoutes, pass it to GoRouter observers, and expose the count through a provider.
5.3 The button: a 56 dp circle, icon Icons.bolt (Icons.close while the menu is open), placed at the saved side with a 12 dp margin from the screen edge and the saved fraction of the usable height (from top inset plus 8 dp to bottom inset plus 8 dp). Hidden when quickButtonVisible is false.
5.4 Tap opens the fan-out menu. Press and hold (long press) starts a drag with a haptic tick and a slight scale-up; on release the button snaps to the nearer side and the fraction is saved for that side. Write the snapping as a pure function and test it.
5.5 Fan-out menu: a scrim (black, 35 percent opacity, tap closes) and six items in this order nearest to farthest: Patients, Hospital, Study, Tools, Drafts, New task. Each item is a 48 dp circle with an icon and a text label beside it on the inner side (toward the screen centre; so the label is to the left of a right-side button and to the right of a left-side button). Spacing 60 dp. The items run upward if the button's centre is in the lower half of the screen, downward otherwise. Add a gentle curve: each item is shifted toward the inner side by 24 * sin(pi * i / 5) dp. Opening animation 180 ms, scale and fade, 25 ms stagger. Write the layout as a pure function (side, direction, index to offset) and test it. When closed, the menu builds no item labels at all (so find.text in widget tests is not ambiguous).
5.6 Actions: Patients sets workPage 0 and goes to /work; Hospital sets workPage 1 and goes to /work; Study goes to /study; Tools pushes /work/tools; Drafts pushes /drafts; New task pushes /new-task. After any choice the menu closes. Create /drafts and /new-task as simple placeholder screens (AppBar with back, centred text "Drafts shelf: coming in module B" and "New task: coming in module B").
5.7 Android back should also close an open menu if that is possible without a hack. If it is not, say so in the report and do not hack around it; the scrim and the close icon are sufficient.

Part 6: Gesture hint and Gestures help
6.1 gestures_help.dart: a const registry kGestures (icon, name, how to do it, visible fallback). Entries: swipe sideways on Patients (fallback: the Patients/Hospital switch or the quick button); scroll to hide or show bars (fallback: the handle, or Settings > Bars: Always show); the bottom handle (tap or swipe up shows the bars, swipe sideways switches Patients and Hospital, also on the Hospital page); quick button (tap opens the menu, press and hold then drag moves it; fallback: Settings > Navigation); screen edges are kept free for the Android back gesture. Route /gestures shows this list.
6.2 One-time hint: a dismissible card at the top of the Work content, shown while gestureHintSeen is false. Text: "Tips: swipe sideways to switch Patients and Hospital. Scroll down to hide the bars; the small handle at the bottom brings them back. Press and hold the bolt button to move it." Buttons "Got it" (sets gestureHintSeen) and "All gestures" (sets it and opens /gestures).

Part 7: Settings layout
Sections in this order: Appearance (unchanged); Navigation (rows: Bars, a radio dialog with the three modes; Handedness, a Right / Left segmented control; Show quick button, a switch; Reset quick button position; Gestures help, opens /gestures; Show gesture hint again, sets gestureHintSeen to false); About & Information (unchanged).

Tests (flutter test must pass)
- ScrollDirectionTracker: rules in 3.4, including direction change and the top-of-list case.
- Chrome state: mode changes, reveal timer in gesturesOnly (use fake time), autoHide never hides through reveal, branch switch shows bars.
- Quick button: snapping function, position persistence per side, handedness change moves the side, reset.
- Fan-out layout function for both sides and both directions.
- Settings persistence for the new settings.
- Widget tests: Study tab and Patients/Hospital switch still pass; tapping the quick button shows the six labels, choosing Study opens the Study placeholder; scrolling the Patients list down hides the segmented row and scrolling up shows it; the hint card shows once and not again.

Do not
- Add packages (only remove local_auth and crypto).
- Add any other feature, database code, WebView or patient data.
- Touch the docs beyond Part 0 and the report and log lines below.
- Hard-code left or right for the quick button or the fan-out; use Handedness.

Acceptance criteria (Bereket checks on the Pixel 2 XL; first run: adb shell pm clear org.edcompanion.ed_companion)
1. The app opens straight to Work: no lock screen anywhere, no Security section in Settings, no PIN text in About.
2. The tips card shows on first launch; "Got it" closes it and it stays gone after restarting the app; Settings > Show gesture hint again brings it back.
3. Scrolling the Patients list down hides the top bar, the bottom bar and the Patients/Hospital row; scrolling up shows them; at the top of the list they are shown.
4. With bars hidden a thin handle appears near the bottom; tapping it or swiping up shows the bars.
5. Settings > Bars: "Always show" never hides them and shows no handle; "Gestures only" hides them and the handle brings them back for about 5 seconds.
6. The bolt button is visible on Work, Study, Settings, About and Tools. A tap opens a labelled six-item fan-out that goes upward when the button is low and downward when it is high; every item goes to the right place (Drafts and New task show their placeholders); tapping outside closes it.
7. Press and hold, then drag, moves the button; releasing snaps it to the nearer side; its position survives closing and reopening the app, and each side remembers its own height.
8. Settings > Handedness Left moves the button to the left edge with labels on its right; Right moves it back.
9. On Patients, swiping sideways switches to Hospital. On Hospital, swiping on the page body does nothing; the handle's sideways swipe and the segmented button switch back.
10. A swipe from the very left or right screen edge triggers Android back and never switches the page.
11. Settings > Gestures help lists each gesture with its fallback.
12. flutter analyze has no issues, flutter test passes, the GitHub Actions run on the push is green and uploads the APK.

Report and docs
Write reports/0004-report.md as in docs/BRIEF_TEMPLATE.md, including: packages removed, whether systemGestureInsets was available, whether Android back closes the menu, anything in 1.5 that needed a different change, and the real commit hashes and CI result (check them before writing). Commit in small commits starting with "0004: ..."; push; add one line to docs/LOG.md; in docs/PROJECT_STATE.md set "Where we are" to "0004 done, awaiting Claude review". Do not tag ok-0004.
