# Brief NNNN: <title>

## Context
Two to five lines: what the project is and where this task fits. Point to `docs/ARCHITECTURE.md` for the stack and data model; restate only what this task needs.

## Goal
One sentence.

## Do
Numbered steps. Name exact files and folders, data structures and behavior. No architectural choices left to the implementer.

## Do not
What must not change or be added (other modules, packages, behavior).

## Acceptance criteria
Things Bereket can check by running the app or reading the output. Each one is a yes or no.

## Report
Write `reports/NNNN-report.md` containing:
- Files changed (paths)
- Deviations from this brief and why
- Errors, warnings, open questions
- Result of `flutter analyze` and `flutter test`
- How each acceptance criterion was checked
- Commit hash

Then commit with message `NNNN: <short description>` and push. Update `docs/LOG.md` with one line.
