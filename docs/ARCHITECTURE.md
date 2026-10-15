# Architecture

Status: reconciled with `VISION.md` on 2026-10-15. Where this file and VISION.md disagree, VISION.md wins. Change this file only through `DECISIONS.md`.

## Stack
- Flutter (Dart), Android first, iOS later. Minimum Android version: the lowest the current Flutter stable supports (minSdk 24 today). CI pins Flutter 3.47.7.
- State: Riverpod. Navigation: go_router. Local database: Drift via drift_flutter (SQLite).
- Settings: shared_preferences. flutter_secure_storage is kept for the Gemini key (module F). There is no app lock.
- Later, chosen when briefed: speech_to_text (English), webview_flutter, pdfrx (PDF reader), camera and video packages, local notifications.
- Prefer small, popular, maintained packages. Gemini must not add a package without saying so in the report.

## Principles (from VISION.md)
- One app, many roles (resident, intern, nurse, senior). Roles decide which screens and actions are shown.
- Offline-first. Every phone works alone; sync adds teamwork.
- Few actions: bars hide, one draggable quick button and gestures reach everything, and every gesture has a visible fallback.
- AI is always an optional enhancement.
- Each release is useful on its own and demo-able to colleagues.

## UI conventions (navigation chrome)
- Chrome means the top bar, the bottom navigation bar and the in-screen switch rows. A setting chooses Always show, Auto-hide (hide on scroll down, show on scroll up) or Gestures only. A thin handle near the bottom brings hidden bars back.
- One quick button, available on every screen, draggable to either side, position remembered per side. Tap opens a fan-out menu.
- Handedness (right by default, left as mirror) lives in `app/lib/core/`. Every thumb-reach control, in every module, reads it. Nothing hard-codes left or right.
- No gesture starts in the outer 24 dp of the left and right screen edges (Android back gesture).
- Inside a WebView, horizontal swipes belong to the page; the handle is used to switch away.
- Gestures are listed in one registry that feeds the Gestures help screen; modules add their gestures there.

## Modules
Small and isolated, each under `app/lib/features/<module>/`. Letters B, C, D, E are fixed because placeholders in the code use them.

| Id | Module | Release | Notes |
|---|---|---|---|
| A | Shell and navigation chrome | R1 | Navigation, settings, About, quick button, handedness. No app lock. |
| B | Patients | R1 | Ward board, patient page, notes with drafts, quick capture |
| C | Hospital view | R1 if spike S2 passes | WebView of the hospital system, copy-for-hospital button, swipe and handle bridge |
| D | Tools | R1 and R2 | Calculators, each with formula, source and tests, prefilled from the patient |
| I | Capture and media | R1 local, R2 sync | Camera photo and video for ECG and ultrasound, compression, thumbnails |
| J | Tasks and timers | R1 local, R2 shared | Per-patient timers, tasks, delegation, local notifications |
| G | Sync | R2 | Identity, roles, LAN transport, media lane |
| H | Handover and duty mode | R2 | Event timeline, timed handover note, persistent reminder |
| K | Consult and round mode | R2 | Consult button, read-only round view |
| L | Server and chat | R3 | Headless peer on a spare PC, patient and general chat, reliable pings |
| E | Study | R4 | PDF library and reader, snippets, notes, flashcards, teaching pages |
| F | AI assist | R4 | Gemini key, voice to structured note, summaries, handover draft |
| M | Hospital data fetch | R4 | Read-only, inside the WebView with the user's own login, agreed with hospital IT |

Build order inside R1: A (chrome), B, J, D, I, then C when S2 allows. Sync (G) is designed into every record type from the start, even though it ships in R2.

## Data model (offline-first, sync-ready)
Every synced record has: `id` (UUID v4), `createdAt` and `updatedAt` (hybrid logical clock values), `deviceId`, `authorId`, `deleted` (tombstone; nothing synced is hard-deleted), and an optional `audience` (user ids or roles) so the record can be addressed.

Conflict rule: last writer wins per record by (`updatedAt`, `deviceId`). Notes are versioned: editing creates a new version and old versions stay in history, so no text is lost.

Synced tables:
- `User` (id, name, role: resident | intern | nurse | senior). Replaces the earlier `Doctor` table. Tasks, consults and messages reference users.
- `Bed` (id, label, ward)
- `Patient` (id, bedId, age, sex, weightKg, allergies, status, admittedAt); identifiers are isolated in `PatientIdentity` (patientId, name, record number) so they can be encrypted or dropped from sync later
- `Assignment` (id, userId, patientId): a user's personal list
- `Note` (id, patientId, kind: history | orders | plan | free | exam | result, body, structuredJson, authorId)
- `Event` (id, patientId, kind: medication | transfusion | bleeding | vomiting | deterioration | procedure | result | other, occurredAt, text, authorId): feeds handover and round mode
- `Task` (id, patientId, text, ownerId, creatorId, dueAt, reminderAt, doneAt, doneById)
- `Timer` (id, patientId, label, dueAt, attachedTo)
- `Consult` (id, patientId, text, addressedTo)
- `Message` (id, scope: patient | general, patientId, text, addressedTo): chat; same sync engine
- `Handover` (id, fromUserId, toUserId, shiftEndAt, body, patientIds)
- `Media` (id, patientId, noteId, kind, contentHash, thumbnail): the file itself travels in the media lane
- `TeachingPage` (id, patientId, body): separate from the care page

Local only, never synced: `Draft` (id, scope, targetId, body, updatedAt; autosaved), `Setting`, `SyncCursor`, `Snippet`.

## Sync design (one protocol, several transports)
Each device keeps, per origin device, the highest sequence number it has received. An exchange is: "here are my cursors; send me everything after them", answered in both directions. Records are idempotent, so repeated or out-of-order delivery is harmless.

Transports implement one interface, `SyncTransport`:
1. LAN: each phone runs a small HTTP server while the app is open and finds peers with mDNS. Fallback: Google Nearby Connections if the wifi blocks device-to-device traffic (spike S1).
2. Server peer (R3): a spare hospital PC runs the same protocol, written in Dart so it shares code with the app. Always on, stores everything.
3. Cloud relay: optional and late, only if no hospital server exists. Backend (Firebase or Supabase free tier) is decided before R3, if at all.

A ward code (entered once, with name and role) keeps strangers on the wifi out. Real accounts can come later.

Addressed records: pings, tasks, consults and chat messages are ordinary synced records with an `audience`. Each phone raises a local notification for records meant for its user, so the same logic works over every transport.

## Media lane
Photos and videos are files with a content hash, synced separately from records: compressed on capture, thumbnails first, full files on demand, with a retention policy for phones with little storage.

## Reminders and background
Timers, tasks and duty reminders are scheduled on each phone as local notifications derived from records, so they fire with no network (exact-alarm permission on newer Android). Receiving pings from other phones needs the app alive in the background (an Android foreground service); some old phones kill background apps, so this must be tested on colleagues' real phones.

## Hospital view bridge (module C)
The Work screen holds Patients and Hospital pages in a `PageView`. Horizontal swipes conflict with scrolling inside the web page, so on the Hospital page the swipe is off and the handle and the switch row are used. One-tap "copy note formatted for the hospital system"; the user pastes with the normal long-press.

## AI layer (module F)
Gemini key from Settings, stored in secure storage. One service with context builders: structure a dictated note, summarize a note or document, write the handover draft, find learning material, make flashcards. Every feature shows the raw text alongside and is optional.
