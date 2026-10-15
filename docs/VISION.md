# Vision, feature catalog and release plan

Written 2026-10-15 by Claude from Bereket's ideas; reconciled with the other docs the same day. This is the governing plan and the idea inbox. `ARCHITECTURE.md`, `ROADMAP.md` and `PROJECT_STATE.md` follow it. Nothing here is built unless `PROJECT_STATE.md` and `LOG.md` say so. Priorities: P1 build early, P2 next, P3 later.

## Principles
- One app, many roles: residents, interns, nurses and seniors use the same app with role-based screens, not separate apps.
- Offline-first. Every phone works alone; sync adds teamwork.
- Few actions. Navigation bars hide, a draggable quick button and gestures reach everything, and every gesture has a visible button as a fallback. Right-handed layout by default, with a mirror option for left-handed users.
- AI is always an optional enhancement. The manual flow never depends on it.
- Each release must be useful on its own and demo-able to colleagues.

## Roles
- **Resident:** full use. Owns patients, writes notes, delegates, consults, writes handovers.
- **Intern:** assigned beds, receives delegated tasks, ticks them off, sees teaching content.
- **Nurse:** sees patients and orders, gets medication and observation reminders, ticks tasks done, posts to chat.
- **Senior:** sees all, answers consults, adds recommended reading and teaching notes, uses round mode.
Roles control which screens and actions are shown. They are chosen when a user joins the ward (ward code plus name plus role).

## Feature catalog

### Capture and media (P1)
- In-app photo and video capture for ECGs and FAST ultrasound, using the phone camera.
- Insert from inside a patient file or from within a note: tap Insert, choose Photo, Video or Existing.
- Automatic compression on capture (Ethiopia's networks are slow), small thumbnails always, full media on demand.
- Media syncs between phones, which replaces handing phones around during consultations.

### Timers and reminders (P1)
- Per-patient timers: "result ready in 40 min", "recheck pain after analgesia". Local notification when due, no network needed.
- A timer can be attached to a note, an order or a task.

### Tasks and delegation (P1 local, P2 shared)
- A task has an owner, a due time, an optional reminder, and a done check with who and when.
- Delegate to an intern or nurse; the delegator is reminded if it is not ticked.
- Nurses get medication-administration reminders.

### Duty mode (P2)
- A mode on the Patients section for nights, lunch times and holidays, when few physicians cover many patients. Extra tools appear.
- Configurable hours (regular: 08:00 to 12:00 and 13:30 to 17:00). At a set time (for example 16:30) the app reminds persistently until a handover note is marked prepared.
- Handover note content: to be defined with Bereket. AI can draft it from the logged events.

### Chat and pings (P2/P3, needs the server for ward-wide reach)
- Patient-specific chat and a general ward chat.
- Messages can be addressed. A patient chat pings the people responsible for or recently involved with that patient.
- Examples: "did the surgical team see this patient?", "did the pharmacy send the drugs for the procedure?"

### Consult button (P2)
- On every patient: write what you are unsure about. It is visible passively to everyone, and optionally addressed to named people who get a ping.

### Round mode (P2)
- A clean, scrollable read-only view of the patient's latest history, investigations and plan, for teaching rounds. Large text, easy to read aloud.

### Teaching page per patient (P3)
- Separate from the care page. The responsible physician writes an academic description of the case and the reasoning.
- "Add to patient discussion" from the PDF reader saves a selected snippet to the patient's teaching page. Seniors add recommended websites, books and notes.

### Study (P3)
- PDF library and reader (pdfrx, column mode first), snippets, notes, flashcards, optional sharing with everyone. See `DECISIONS.md`.

### AI across the app (P3, designed in from the start)
- Structure a dictated note, summarize a note or document, write the handover draft, find learning material from the patient context, make flashcards.
- Each user's own Gemini key. All AI goes through one service with context builders, so every feature reuses the same plumbing and none is required.

### Hospital data fetch (P3, risky)
- Reading investigation results from the hospital web interface automatically. Best done read-only by script inside the in-app WebView using the user's own login, not by a separate scraper holding passwords. It will break when the hospital page changes. Agree it with hospital IT before relying on it.

### Calculators (P1/P2)
- Verified by Bereket, with sources in About. Prefilled from the patient's age and weight.

## Architecture consequences (cheap now, expensive later)
1. **Users and roles in the data model** from the start: `User(id, name, role)` replaces the old `Doctor` table. Tasks, consults and messages reference users.
2. **Everything addressable.** A record can carry an audience (users or roles). A ping is just a synced record addressed to someone; every phone raises a local notification when it receives a record meant for its user. The same logic works over LAN sync and over the server.
3. **Chat is synced records too.** Messages use the same sync engine, so they work offline and catch up later. A server is only needed for ward-wide reach when the right phones are not online at the same moment.
4. **The server is a headless peer.** A spare hospital computer runs the same sync protocol and stores everything, always on. We write it in Dart so it shares code with the app. No separate backend design.
5. **Media is a separate lane.** Photos and videos are stored as files with a content hash, synced lazily: thumbnails first, full files on demand, with a retention policy for old phones with little storage.
6. **Reminders are local.** Timers, tasks and duty reminders are scheduled on each phone as local notifications derived from synced records, so they fire without network. Exact-alarm permission is needed on newer Android versions.
7. **Background running is the hard part.** Pings from other phones need the app alive in the background (an Android foreground service). Some old phones kill background apps aggressively; we must test on real colleagues' phones.
8. **Role-based feature flags** in the app shell.
9. **Handedness setting** (right by default, mirror option) in the navigation chrome.
10. **Round mode and handover need structured data**: notes have kinds, investigations are structured records, events are timestamped.

## Release plan (proposal, Bereket decides)
- **R1 Pocket notebook (useful on one phone, first thing to show colleagues):** shell (done; the app lock was removed by decision, see `DECISIONS.md`), navigation chrome and gestures, ward board, patient page, notes with drafts, quick capture, per-patient timers, camera attachments (local), calculators.
- **R2 Ward sync:** identity and roles, LAN sync, media sync with compression, shared tasks and delegation with local pings, duty mode and handover, consult button, round mode.
- **R3 Server and chat:** the headless peer on a spare PC, patient and general chat, reliable pings, central media store.
- **R4 Study and learning:** PDF reader and library, snippets, teaching pages, AI features, hospital data fetch.

## Risks
- Scope: this is a large product. We protect motivation by shipping R1 early and testing it with real residents.
- Background notifications on old phones (see above).
- Storage and bandwidth for media.
- Patient images and chat raise the stakes of the deferred privacy decision. Before a real pilot with patient data, get the hospital's agreement, consider encrypting identifiers and media, and revisit the lock decision (the app has no lock today).
- Scraping the hospital system is fragile and may need IT approval.

## Open questions for Bereket
- Confirm or change the release order.
- Handover note contents for duty mode.
- Which roles need what on day one.
- Is the Hospital view (WebView, module C) part of R1? It is the paste target of the whole workflow but depends on spike S2.
