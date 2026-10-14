# ED Companion

A Flutter app (Android first, iOS later) that lets emergency-department residents document patients quickly on their own phones, then paste the result into the hospital's existing web system. It works alongside that system and does not replace it.

**Status and next steps:** see `docs/PROJECT_STATE.md` (read this first).
**Who does what and how we work:** see `docs/ROLES_AND_WORKFLOW.md`.

## Folder map

| Path | Purpose |
|---|---|
| `docs/PROJECT_STATE.md` | One-page current state. The resume point for any new session. |
| `docs/ROLES_AND_WORKFLOW.md` | Roles (Bereket, Claude, Gemini) and the working loop. |
| `docs/ARCHITECTURE.md` | Stack, data model, sync design, module map. |
| `docs/DECISIONS.md` | Decisions made and why. Append only. |
| `docs/ROADMAP.md` | Milestones and the ordered backlog. |
| `docs/LOG.md` | What was done, newest first. |
| `docs/BRIEF_TEMPLATE.md` | The format of every task brief. |
| `docs/CLAUDE_START.md` | Kickoff text for a fresh Claude session. |
| `GEMINI.md` | Standing instructions for Gemini (read automatically by Gemini CLI). |
| `briefs/` | Task briefs, numbered `NNNN-slug.md`. |
| `reports/` | Gemini's report for each brief, `NNNN-report.md`. |
| `app/` | The Flutter project (created by brief 0001). |

## Hard rules

- No patient data, real or realistic, ever goes in this repository. Use obviously fake test data.
- No API keys, passwords or tokens in this repository. The repo is public.
