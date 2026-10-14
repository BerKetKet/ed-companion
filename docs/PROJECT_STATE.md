# Project State

Last updated: 2026-10-15 by Claude (design phase, no code yet)

## What this is
ED Companion: a Flutter app for emergency-department residents. They document patients quickly on their phones (typed or by voice), then paste into the hospital's existing web system, which they cannot modify and which is reachable only on the hospital wifi (10.x.x.x). Built by Bereket, a former resident, who is not a programmer. Free services only.

## Where we are
Design phase. Workflow and docs are drafted. The repository is being created. No app code yet.

## Next up
1. Create the repo and push these docs (spell `ed-repo-init`).
2. Brief 0001: environment setup (Flutter, Android SDK, JDK) and the empty app scaffold with CI.
3. Spike S1: test whether phones can reach each other on the hospital wifi (decides how LAN sync works).
4. Module A (shell and lock), then B (patients and notes).

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
