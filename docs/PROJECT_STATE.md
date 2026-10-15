# Project State

Last updated: 2026-10-15 by Gemini (Brief 0003 complete)

## What this is
ED Companion: a Flutter app for emergency-department residents. They document patients quickly on their phones (typed or by voice), then paste into the hospital's existing web system, which they cannot modify and which is reachable only on the hospital wifi (10.x.x.x). Built by Bereket, a former resident, who is not a programmer. Free services only.

## Where we are
Briefs 0001 and 0002 approved (tags ok-0001, ok-0002). 0003b done, awaiting Claude review.

## Next up
- (a) Review 0003.
- (b) Brief 0004, navigation chrome: auto-hiding bars, bottom handle, draggable quick button, gestures with visible fallbacks, handedness setting (right by default, mirror option).
- (c) Then ask Bereket for ideas and plan module B (patients and notes).

## Open decisions (Claude owns these)
- Cloud backend choice for sync (leaning Firebase Firestore free tier or Supabase). Decide before module G.
- LAN transport: depends on spike S1.

## Open items for Bereket
- Answer two questions: is the release order in docs/VISION.md right; which R1 features should reach colleagues first?
- Test the hospital web system inside a phone WebView (open 10.x.x.x in phone Chrome on the ED wifi, spike S2).
- Test whether wifi client isolation blocks phone-to-phone traffic in the ED.
- Confirm the GitHub username so Claude can fetch the repo.

## Key constraints
- Offline-first: every phone holds a full local copy and works with no network.
- Sync is automatic: phone to phone over the LAN, and through a free cloud server.
- All ward patients are visible to every doctor. A doctor adds a patient to their own list with a plus button.
- The AI layer (Gemini, user's own key) must never be required for the manual flow.
- Privacy is deferred by decision, but identifiers must be isolated in the data layer so they can be protected later.
- Old phones matter: support the lowest Android version Flutter allows.
- Never put patient data or keys in the repo.

See `ARCHITECTURE.md`, `DECISIONS.md`, `ROADMAP.md`.
