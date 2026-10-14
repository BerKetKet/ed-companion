# Architecture

Status: proposed by Claude, 2026-10-15. Change only through `DECISIONS.md`.

## Stack
- Flutter (Dart), Android first. Minimum Android version: the lowest the current Flutter stable supports.
- State management: Riverpod. Navigation: go_router.
- Local database: Drift (SQLite). Mainstream, typed, migrations supported.
- Secure storage for the Gemini key and lock PIN: flutter_secure_storage.
- Voice (v1): speech_to_text (Android's built-in recognizer, English).
- WebView: webview_flutter.
- Prefer small, popular, maintained packages. Gemini must not add a package without saying so in the report.

## Modules
Small and isolated, each in its own folder under `app/lib/features/`.

| Id | Module | Notes |
|---|---|---|
| A | Shell and lock | Login by PIN or fingerprint, bottom navigation, settings, About |
| B | Patients | Ward board, patient page, notes, drafts, tasks |
| D | Tools | Calculators, each with formula, source and tests |
| C | Hospital view | WebView plus the swipe/tab bridge |
| E | Study | Library, snippets, notes, flashcards |
| F | AI assist | Gemini key, voice to structured note, summaries |
| G | Sync | LAN and cloud transports over one protocol |
| H | Handover | Event timeline and handover note |

Build order: A, B, D, C, G (local sync engine first), H, E, F, then cloud transport. Sync is early because every record type must be designed for it from the start.

## Data model (offline-first, sync-ready)

Every synced record has:
- `id`: UUID v4
- `createdAt`, `updatedAt`: hybrid logical clock values (sortable, safe against bad phone clocks)
- `deviceId`: which phone wrote this version
- `authorId`: which doctor
- `deleted`: boolean tombstone (nothing is ever hard-deleted from synced tables)

Conflict rule: last writer wins per record by (`updatedAt`, `deviceId`). To avoid losing text, notes are append-style: editing a note creates a new version rather than overwriting the old one, and old versions stay in history.

Tables (synced):
- `Doctor` (id, name, role)
- `Bed` (id, label, ward)
- `Patient` (id, bedId, **identifiers isolated in `PatientIdentity`**, age, sex, weightKg, allergies, status, admittedAt)
- `PatientIdentity` (patientId, name, record number): kept separate so it can be encrypted or dropped from sync later
- `Note` (id, patientId, kind: history | orders | plan | free | exam | result, body, structuredJson, authorId)
- `Event` (id, patientId, kind: medication | transfusion | bleeding | vomiting | deterioration | procedure | result | other, occurredAt, text, authorId): feeds handover
- `Task` (id, patientId, text, dueAt, doneAt): pending results, rechecks
- `Handover` (id, fromDoctorId, toDoctorId, shiftEndAt, body, patientIds)
- `Assignment` (id, doctorId, patientId): a doctor's personal list ("mine")

Tables (local only, never synced):
- `Draft` (id, scope, targetId, body, updatedAt): half-written text, autosaved every few seconds
- `Setting`, `SyncCursor`, `Snippet` (personal text shortcuts)

## Sync design (one protocol, two transports)

Each device keeps, per origin device, the highest sequence number it has received. A sync exchange is: "here are my cursors; send me everything after them", answered in both directions. Records are idempotent, so repeated or out-of-order delivery is harmless.

Transports implement one interface, `SyncTransport`:
1. **LAN**: each phone runs a tiny HTTP server while the app is open and discovers peers with mDNS. Falls back to Google Nearby Connections if the wifi blocks device-to-device traffic. Decision depends on spike S1.
2. **Cloud**: the server only stores and forwards records. Backend chosen later (Firebase Firestore or Supabase free tier).

Ward-wide shared secret (a ward code entered once) prevents strangers on the wifi from reading or writing. Real accounts can come later.

## Hospital view bridge (module C)
Left: the app. Right: WebView of the hospital system. Both a swipe gesture and a bottom switch work, because horizontal swipes conflict with scrolling inside the web page. One-tap "copy note formatted for the hospital system". Paste still done by the user with the normal long-press.

## AI layer (module F)
Gemini key from Settings, stored securely. Functions: structure a dictated note, summarize a document, build flashcards, write the handover note from events. All AI features are optional enhancements and show the raw text alongside.

## Convenience features (see ROADMAP for ordering)
Quick-capture button reachable from any screen, autosaved drafts everywhere, personal text snippets, reassessment timers with notifications, one-handed bottom navigation, dark mode for night shifts, large tap targets, patient search, calculators prefilled from the patient's age and weight.
