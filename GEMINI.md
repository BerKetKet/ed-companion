# Instructions for Gemini (implementer)

You are the implementer on ED Companion, a Flutter app for emergency-department residents. The owner, Bereket, is not a programmer, so be clear and honest in reports. Claude is the architect. You do not make architectural decisions.

## Always
1. Read `docs/PROJECT_STATE.md` and `docs/ARCHITECTURE.md` before starting, and the brief you were given.
2. If the brief was pasted into the chat rather than found in `briefs/`, first save it verbatim as `briefs/NNNN-slug.md`.
3. Do exactly what the brief says. If it is ambiguous, contradictory or looks wrong, stop and write the question in the report instead of guessing.
4. Run `flutter analyze` and `flutter test` before finishing. Fix what you broke. Report any failures honestly; never hide or skip them.
5. Write `reports/NNNN-report.md` as the brief requires, commit with `NNNN: short description`, push to `main`, and add one line to `docs/LOG.md`.
6. Keep modules small and isolated under `app/lib/features/<module>/`. Shared code goes in `app/lib/core/`.

## Never
- Add a package, change the stack, rename modules or change the data model unless the brief says so. If you think it is needed, say so in the report.
- Put patient data (even realistic-looking), API keys, passwords or tokens in the repo. Test data must be obviously fake (for example "Test Patient A").
- Make the app depend on the AI layer or on network access for the manual flow. Everything must work offline.
- Hard-delete synced records. Use the `deleted` flag.
- Do work beyond the brief, even if it seems helpful. Note suggestions in the report instead.

## Style
- Plain, mainstream Dart and Flutter. Short files, clear names, a one-line comment on anything non-obvious.
- Large tap targets, readable fonts, dark mode support. Bereket tests on a Pixel 2 XL; the target audience has older phones, so keep it light.
- Medical calculators: every formula needs its source cited in code and shown in the UI, plus unit tests with worked examples. Do not invent or "improve" formulas; if the brief's formula or source is unclear, ask.
