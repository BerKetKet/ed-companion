# Project State

Last updated: 2026-10-15 by Claude (docs reconciled with VISION.md; app lock removed by decision)

## What this is
ED Companion: a Flutter app for emergency-department residents. They document patients quickly on their phones (typed or by voice), then paste into the hospital's existing web system, which they cannot modify and which is reachable only on the hospital wifi (10.x.x.x). Built by Bereket, a former resident, who is not a programmer. Free services only. The governing plan is `VISION.md` (feature catalog and releases R1 to R4); `ARCHITECTURE.md` and `ROADMAP.md` follow it.

## Where we are
- Briefs 0001 and 0002 approved (tags ok-0001, ok-0002).
- Brief 0003 (lock types) is implemented and 0003b (lock corrections) is being finished by Gemini. Both are overtaken by Bereket's decision to remove the app lock entirely (see DECISIONS.md). They are not reviewed further.
- Brief 0004 (remove the lock, then navigation chrome) is written and goes to Gemini after 0003b.
- Release R1 (pocket notebook) is in progress. Shell and settings exist; there are no patients, notes or tools yet.

## Next up
1. Gemini finishes 0003b and tags `lock-last-version`. Bereket copies the updated docs into the repo. Gemini runs brief 0004.
2. Claude reviews 0004 from a zip of the repo.
3. Claude asks Bereket for his ideas, then plans module B (patients, beds, notes, drafts).

## Open decisions (Claude owns these)
- LAN transport: depends on spike S1 (phone to phone on hospital wifi); fallback is Google Nearby Connections.
- Whether a cloud relay is needed at all once the server peer (R3) exists. Decide before R3.
- Whether the Hospital view (WebView, module C) is part of R1. It depends on spike S2.

## Open items for Bereket
- Answer the VISION questions: is the release order right; which R1 features reach colleagues first; handover note contents (R2); which roles need what on day one.
- Spike S2: open the hospital system's 10.x.x.x address in phone Chrome on the ED wifi.
- Spike S1: test whether phone-to-phone traffic works on the ED wifi.

## Key constraints
- Offline-first: every phone holds a full local copy and works with no network.
- Sync is automatic and record-based: phone to phone over the LAN, later through a server peer (spare hospital PC).
- All ward patients are visible to every doctor. A doctor adds a patient to their own list with a plus button.
- The AI layer (Gemini, user's own key) is never required for the manual flow.
- Privacy is deferred by decision. There is no app lock: anyone holding the phone can open the app. Identifiers stay isolated in the data layer so they can be protected later. Revisit before any pilot with real patient data.
- Old phones matter: support the lowest Android version Flutter allows.
- One-handed use: right-handed layout by default with a mirror option; no gestures on the outer screen edges; every gesture has a visible fallback.
- Never put patient data or keys in the repo.

See `VISION.md`, `ARCHITECTURE.md`, `DECISIONS.md`, `ROADMAP.md`.
