# Roadmap

## Milestones
- **M0 Setup**: repo, environment, empty app that builds, CI.
- **M1 Ward notebook (usable alone)**: shell and lock, ward board, patient page, notes, drafts, tasks. A resident can already use this on one phone.
- **M2 Tools and hospital view**: calculators, WebView, swipe and tab switching, copy formatting.
- **M3 Sync**: local sync engine, LAN transport, ward code. Phones share data.
- **M4 Handover**: event timeline, handover note, sharing.
- **M5 Study**: library, snippets, flashcards, sharing.
- **M6 AI**: key storage, voice to structured note, summaries, handover writer.
- **M7 Cloud**: cloud transport so data flows when the LAN is down.
- **M8 Polish and pilot**: with a few residents in the ward, fix what hurts.

Rule: M1 must be useful by itself before anything else is built on it.

## Spikes (small experiments, do early)
- **S1** Largely de-risked: LocalSend worked PC to phone on hospital wifi. Still to confirm: phone to phone on hospital wifi.
- **S2** Pending: Bereket will open the hospital system in phone Chrome on the ED wifi.
- **S3** Does Android speech recognition handle clinical English acceptably on the target phones, offline?

## Convenience features (ordered by value for a busy ward)
Tier 1, build with M1:
- Autosaved drafts everywhere, with a Drafts shelf on the home screen to resume.
- Quick-capture button on every screen: new note, voice note, or task for the current or a chosen patient.
- Ward board with bed colors, last-updated time and open tasks per patient.
- One-handed layout: bottom navigation, large tap targets.
- Copy buttons: copy a note, copy a section, copy the whole patient summary, formatted as plain text for the hospital system.
- Personal snippets: type a short code to expand common phrases or templates (for example an ABCDE skeleton).
- Dark mode and font size setting.

Tier 2:
- Reassessment timers ("recheck in 30 min") with notifications.
- Pending results list per patient and ward-wide.
- Calculators prefilled from the patient's age, weight and allergies.
- Search across patients and notes.
- Vitals quick entry with a small trend display.
- Undo for deletes; version history for notes.

Tier 3:
- Lock-screen or home-screen shortcut straight to voice capture.
- Shift mode: "my patients" first, handover button at shift end.
- Case log: de-identified interesting cases for learning and portfolios.

## Study ideas
- PDF reader with highlights that turn into saved snippets in one tap.
- Snippets and notes with tags and search.
- Gemini: summarize a document or snippet, ask questions about a document, generate flashcards.
- Spaced-repetition review with daily reminder notifications.
- Shared ward library: upload once, optionally share to everyone; syncs like other data.
- Guidelines and sites: built-in browser with a bookmark list (UpToDate, open-access guidelines, EM podcasts and sites). Content behind a login stays the user's own login.

## Backlog log
Add new ideas here as one-liners with the date.
