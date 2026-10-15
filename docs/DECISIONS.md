# Decisions

Append only. Newest at the bottom. Format: date, decision, reason.

## 2026-10-15 (Bereket)
- Flutter, Android first, iOS later. Reason: one codebase, Gemini knows it well.
- Free services only. Hospital may fund a server later if the prototype proves itself.
- Privacy is deferred, not forgotten: identifiers are isolated in the data layer so they can be encrypted later. Reason: the ward already shares patient details over Telegram, and quality must not suffer.
- All ward patients are visible to every doctor, matching the hospital system. A doctor adds patients to a personal list with a plus button, picking a bed or choosing from the list.
- Offline-first: every phone keeps a full local copy. Sync happens automatically over the LAN and through a free cloud server.
- Handover feature: events are logged during the shift and turned into a timed handover note, shared over LAN or cloud.
- Gemini key stays a core feature, stored securely.
- Voice transcription: English only for now. Amharic maybe much later.
- Calculators are verified by Bereket; sources are listed in an About section.
- Study section is a major feature: uploads, optional sharing, Gemini summaries and reminders, notes, browser access to guidelines and sites.
- Hospital web system is assumed to work in a phone WebView over the hospital wifi; Bereket will test.
- Devices: development on a CachyOS laptop under `~/projects`; test on Pixel 2 XL (Android 15); aim for wide compatibility with older phones.
- Roles: Claude architect (and coder when quicker), Gemini implementer, Bereket owner and courier. Docs and a log keep any new Claude session able to resume.

## 2026-10-15 (Claude, proposed, awaiting Bereket's nod)
- Local DB: Drift (SQLite). State: Riverpod. Navigation: go_router.
- Sync: record-based protocol with hybrid logical clocks and per-device cursors; two transports (LAN, cloud) behind one interface. Reason: avoids conflict headaches and works the same on both transports.
- LAN transport depends on a hospital-wifi test (spike S1) because many wifi networks block phone-to-phone traffic; fallback is Google Nearby Connections.
- Notes are versioned, not overwritten, so no one's text is lost in a sync conflict.

## 2026-10-15 (later, Claude with Bereket)
- Lock types: user chooses App PIN, Phone screen lock, or No lock (brief 0003). The app lock is a convenience; privacy is deferred by decision.
- Database: Drift through drift_flutter; sqlite3_flutter_libs was end-of-life and was removed. CI pins Flutter 3.47.7.
- Study PDF reader: pdfrx (PDFium, MIT license) as the engine. Build "column mode" first (one column at a time with auto-advance, night and sepia themes); optional text-reflow mode later for digital PDFs only. Verify the library's text-extraction and search support before the module E brief. Syncfusion's viewer was rejected for licensing and weight.
- Sync evidence: LocalSend worked between Bereket's PC and phone on the hospital wifi, so device discovery and direct connections appear allowed there. Phone-to-phone on the hospital wifi is still unconfirmed. Develop and debug sync at home with two phones.
- Hospital WebView: stays a placeholder until Bereket tests the hospital system's 10.x.x.x address in phone Chrome on the ED wifi (spike S2).
- Working agreement: ask Bereket for ideas before starting each new module.
