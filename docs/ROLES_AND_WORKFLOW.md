# Roles and Workflow

## Roles

**Bereket (product owner, clinical authority, courier)**
- Decides what the app should do. Knows the ward. Final say on anything clinical.
- Verifies every medical formula against its source before it ships.
- Copies briefs from Claude to Gemini and reports from Gemini back to Claude when needed.
- Runs and tests the app on the Pixel 2 XL and in the ward, and reports what he sees.
- Is not expected to read or debug code.

**Claude (architect and reviewer)**
- Owns architecture, data model, decisions and the roadmap.
- Writes task briefs for Gemini. Reviews Gemini's work from the public repo.
- May write code or documents directly when that is quicker than writing a brief. Bereket's free usage is limited, so Claude spends its messages carefully: short answers, decisions over discussion.
- Keeps `docs/PROJECT_STATE.md`, `docs/DECISIONS.md` and `docs/ROADMAP.md` current.
- Never guesses at code it has not seen. If it cannot fetch the repo, it names the exact files it needs.

**Gemini (implementer)**
- Does the coding, running, testing and git work, following one brief at a time.
- Makes no architectural decisions. When a brief is ambiguous or wrong, it stops and asks in its report instead of improvising.
- Writes a report for every brief and updates `docs/LOG.md`.

## The loop

1. Bereket states a goal or a problem to Claude.
2. Claude asks at most one or two questions if needed, then produces one brief.
3. Bereket gives the brief to Gemini. Gemini first saves it verbatim as `briefs/NNNN-slug.md`.
4. Gemini does the work, runs the checks, commits, and writes `reports/NNNN-report.md`, including the commit hash.
5. Bereket tells Claude "report 0003 done" and sends a fresh zip of the repo.
6. Claude reviews the report and the commit diff, then either approves or issues a correction brief.
7. On approval Claude updates the state docs and Gemini tags the commit `ok-NNNN`. A tag is a safe point to roll back to.

## How Claude reads the repo

Claude's session usually cannot browse GitHub (automated access is blocked). Bereket sends a zip of the repo made with the command in `docs/CLAUDE_START.md`. Claude unzips it and reads every file before reviewing, then states what it could not verify (it cannot run Flutter, see git history or CI). If browsing does work, raw files at `https://raw.githubusercontent.com/BerKetKet/ed-companion/main/<path>` are a fallback, and a single commit's diff is at `https://github.com/BerKetKet/ed-companion/commit/<hash>.diff`.

## Rules for briefs (Claude writing)

- One coherent task per brief. Self-contained. States context, stack, files, and what must not change.
- Gives data structures, file names and behavior so Gemini makes no architectural choices.
- Ends with acceptance criteria Bereket can check by running the app, plus the report requirements.
- Uses `docs/BRIEF_TEMPLATE.md`.

## Rules for reports (Gemini writing)

- Files changed, deviations from the brief, errors, open questions, commit hash, how each acceptance criterion was checked.
- Output of `flutter analyze` and `flutter test` summarized (pass or fail, counts).
- Honest about anything not done or not verified.

## Git conventions

- Work on `main` in small commits. One brief equals one or a few commits.
- Commit message: `NNNN: short description`.
- After approval: tag `ok-NNNN`.
- Never commit secrets, patient data, or build output (`.gitignore` covers it).

## Starting a new Claude session

Give it the text in `docs/CLAUDE_START.md`. It points the new session at `docs/PROJECT_STATE.md` and this file, so no history is needed. This works the same on Bereket's account and his sister's.

## Keeping the docs alive

- After every approved brief: Claude (or Gemini on Claude's instruction) updates `docs/PROJECT_STATE.md` and adds a line to `docs/LOG.md`.
- Any decision that changes the design goes into `docs/DECISIONS.md` with a date and the reason.
- Keep `PROJECT_STATE.md` under one page. History goes in `LOG.md`.
