# Roadmap

The plan is `VISION.md`. This file orders the work inside each release and keeps the spikes and the idea backlog. Release order is a proposal until Bereket confirms it.

## Releases
- **R1 Pocket notebook** (useful on one phone, first thing to show colleagues). Order:
  1. Shell (done) and navigation chrome (brief 0004; the app lock is removed there).
  2. Module B: ward board, patient page, notes with drafts, quick capture.
  3. Module J, local part: per-patient timers and tasks with local notifications.
  4. Module D: calculators, verified by Bereket.
  5. Module I, local part: camera photo and video attached to notes.
  6. Module C: Hospital view in the WebView, when spike S2 allows.
- **R2 Ward sync**: identity and roles, LAN sync (G), media sync, shared tasks and delegation, duty mode and handover (H), consult button and round mode (K).
- **R3 Server and chat**: the headless peer on a spare PC, patient and general chat, reliable pings, central media store (L).
- **R4 Study and learning**: PDF library and reader, snippets, flashcards, teaching pages (E); AI features (F); hospital data fetch (M).

Rule: R1 must be useful by itself before R2 is built on it.

## Spikes (small experiments, do early)
- **S1** Largely de-risked: LocalSend worked PC to phone on hospital wifi. Still to confirm: phone to phone on hospital wifi.
- **S2** Pending: Bereket opens the hospital system in phone Chrome on the ED wifi.
- **S3** Does Android speech recognition handle clinical English acceptably on the target phones, offline?

## Convenience features by release
R1:
- Autosaved drafts everywhere, with a Drafts shelf to resume.
- Quick button on every screen (new note, new task, jump to any section).
- Ward board with bed colors, last-updated time and open tasks per patient.
- One-handed layout: large tap targets, handedness setting, hideable bars.
- Copy buttons: copy a note, a section or the whole patient summary as plain text for the hospital system.
- Personal snippets: a short code expands to a template (for example an ABCDE skeleton).
- Dark mode and font size setting (done).
- Per-patient timers ("recheck in 30 min") with notifications; pending results list per patient.
- Calculators prefilled from the patient's age, weight and allergies.

R2:
- Shift mode ("my patients" first, handover button at shift end), duty mode with the persistent handover reminder.
- Search across patients and notes; vitals quick entry with a small trend display.
- Undo for deletes; version history for notes.

Later:
- Lock-screen or home-screen shortcut straight to voice capture.
- Case log: de-identified interesting cases for learning and portfolios.

## Study ideas (R4)
- PDF reader with highlights that turn into saved snippets in one tap; "add to patient discussion" saves a snippet to the patient's teaching page.
- Snippets and notes with tags and search.
- Gemini: summarize a document or snippet, ask questions about a document, generate flashcards.
- Spaced-repetition review with a daily reminder.
- Shared ward library: upload once, optionally share to everyone; syncs like other data.
- Guidelines and sites: built-in browser with a bookmark list. Content behind a login stays the user's own login.

## Backlog log
Add new ideas here as one-liners with the date.
