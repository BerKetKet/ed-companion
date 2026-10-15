# Decisions

Append only, newest at the bottom. Format: date, who, decision, reason.
Cleaned on 2026-10-15 at Bereket's request: a block that was pasted twice is now single, proposals that were accepted are marked accepted, and entries overtaken by later decisions are folded into the entry that replaced them.

## 2026-10-15 (Bereket)
- Flutter, Android first, iOS later. Reason: one codebase, Gemini knows it well.
- Free services only. The hospital may fund a server later if the prototype proves itself.
- Privacy is deferred, not forgotten: identifiers are isolated in the data layer so they can be encrypted later. Reason: the ward already shares patient details over Telegram, and quality must not suffer.
- All ward patients are visible to every doctor, matching the hospital system. A doctor adds patients to a personal list with a plus button, picking a bed or choosing from the list.
- Offline-first: every phone keeps a full local copy. Sync happens automatically (see the sync entry below).
- Handover feature: events are logged during the shift and turned into a timed handover note, shared through sync.
- The Gemini key stays a core feature, stored securely.
- Voice transcription: English only for now. Amharic maybe much later.
- Calculators are verified by Bereket; sources are listed in About.
- Study is a major feature: uploads, optional sharing, Gemini summaries and reminders, notes, browser access to guidelines and sites.
- The hospital web system is assumed to work in a phone WebView over the hospital wifi; Bereket will test (spike S2).
- Devices: development on a CachyOS laptop under `~/projects`; test on a Pixel 2 XL (Android 15); aim for wide compatibility with older phones.
- Roles: Claude architect (and coder when quicker), Gemini implementer, Bereket owner and courier. Docs and a log let any new Claude session resume.

## 2026-10-15 (Claude with Bereket): stack and sync, accepted
- Local DB: Drift via drift_flutter (sqlite3_flutter_libs was end-of-life and was removed). State: Riverpod. Navigation: go_router. CI pins Flutter 3.47.7.
- Sync: record-based protocol with hybrid logical clocks and per-device cursors; transports sit behind one interface. Reason: avoids conflict headaches and works the same on every transport.
- LAN transport depends on spike S1. Evidence so far: LocalSend worked between Bereket's PC and phone on the hospital wifi, so discovery and direct connections appear allowed. Phone to phone is unconfirmed. Develop and debug sync at home with two phones. Fallback: Google Nearby Connections.
- Notes are versioned, not overwritten, so no one's text is lost in a conflict.
- Study PDF reader: pdfrx (PDFium, MIT). Build column mode first (one column at a time with auto-advance, night and sepia themes); optional text-reflow mode later for digital PDFs only. Verify text-extraction and search support before the module E brief. Syncfusion rejected for licensing and weight.
- The hospital WebView stays a placeholder until spike S2 is done.
- Working agreement: ask Bereket for his ideas before starting each new module.

## 2026-10-15 (Claude with Bereket): vision
- The full feature vision and release plan are in `VISION.md` (R1 pocket notebook, R2 ward sync, R3 server and chat, R4 study and learning). It is the governing plan; `ARCHITECTURE.md`, `ROADMAP.md` and `PROJECT_STATE.md` follow it.
- One app with role-based screens (resident, intern, nurse, senior), not separate apps. The data model has `User(id, name, role)` in place of the earlier `Doctor` table.
- Pings, tasks, consults and chat messages are addressed synced records; each phone raises a local notification for records meant for its user.
- The server is a headless peer running the same sync protocol (Dart) on a spare hospital PC. This replaces the earlier idea of a cloud backend as the main shared store; a cloud relay stays optional and is decided before R3, if needed at all.
- Photos and videos are a separate sync lane, compressed on capture, thumbnails first.
- UI: right-handed default with a mirror option; bars hide; one draggable quick button; gestures always paired with visible buttons.

## 2026-10-15 (Bereket): app lock removed
- The app lock (App PIN, phone screen lock, fingerprint) is removed entirely for now. The app is open to anyone who has the phone and relies on the phone's own screen lock. Reason: not a priority; it was costing effort and bugs.
- Briefs 0003 and 0003b (lock types and lock corrections) are overtaken by this. The last version with the lock is kept in git under the tag `lock-last-version`.
- Revisit before any pilot with real patient data (see VISION risks).

## 2026-10-15 (Bereket with Claude): navigation chrome
- Bars setting with three modes: Always show, Auto-hide (hide on scroll down, show on scroll up), Gestures only. A thin handle near the bottom brings hidden bars back.
- One quick button, on every screen. A tap opens a fan-out menu (Patients, Hospital, Study, Tools, Drafts, New task); press and hold, then drag, moves it. It snaps to the left or right edge and remembers its height per side.
- Handedness setting: right by default, left as mirror; it sets the quick button's side and is read by every thumb-reach control.
- No gestures in the outer 24 dp of the left and right screen edges (Android back gesture). On the Hospital page the page swipe is off (the WebView needs it); the handle's sideways swipe switches back.
- A one-time gesture hint, and a Gestures help screen listing each gesture with its visible fallback.

## 2026-10-15 (Claude): process
- Claude's session cannot reliably browse GitHub (automated access is blocked). The repo is reviewed from a zip Bereket makes with the command in `CLAUDE_START.md`, and Claude reads every file in it before reviewing or deciding.
- Claude writes doc updates as complete files; Bereket copies them into the repo and Gemini commits them.
