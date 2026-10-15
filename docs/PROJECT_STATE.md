# Project State

Last updated: 2026-10-15 by Gemini (Brief 0002 complete)

## What this is
ED Companion: a Flutter app for emergency-department residents. They document patients quickly on their phones (typed or by voice), then paste into the hospital's existing web system, which they cannot modify and which is reachable only on the hospital wifi (10.x.x.x). Built by Bereket, a former resident, who is not a programmer. Free services only.

## Where we are
Milestone M0 is complete and brief 0002 (shell and lock) is done pending review.

## Next up
1. Review 0002, then module B (patients and notes) design.

## Open decisions (Claude owns these)
- Cloud backend choice for sync (leaning Firebase Firestore free tier or Supabase). Decide before module G.
- LAN transport: depends on spike S1.

## Open items for Bereket
- Test the hospital web system inside a phone WebView.
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
