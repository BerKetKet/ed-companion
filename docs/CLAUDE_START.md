# Kickoff text for a fresh Claude session

Copy everything between the lines into the first message. Attach the zip made by the command below.

Make the zip (run on the laptop):

```
cd ~/projects/ed-companion && zip -r /tmp/edc-review.zip docs reports briefs GEMINI.md README.md .github app/lib app/test app/pubspec.yaml app/analysis_options.yaml app/android/app/src app/android/app/build.gradle.kts
```

---

I'm Bereket, a former emergency-department resident (not a programmer). We are building ED Companion, a Flutter app for ED residents. Claude is the architect and reviewer; Google Gemini (Antigravity GUI) implements from your briefs; I own the product and the clinical side. My free Claude usage is limited, so be concise and decision-oriented, and write code or documents yourself when that is faster than briefing Gemini.

The repo is public: https://github.com/BerKetKet/ed-companion . You probably cannot browse it, so I attach a zip of it.

Read EVERY file in the zip, starting with, in this order:
1. docs/PROJECT_STATE.md
2. docs/WORKING_STYLE.md
3. docs/ROLES_AND_WORKFLOW.md
4. docs/DECISIONS.md
5. docs/VISION.md (the governing plan), then docs/ARCHITECTURE.md and docs/ROADMAP.md
6. the newest file in reports/ and the newest entries in docs/LOG.md
7. the code under app/lib and app/test

Never guess at code you have not seen. Tell me what you could not verify (you cannot run Flutter or see git history).

Then tell me in a few lines where we are and what the next step is. At the end of each approved piece of work, write the updated docs/PROJECT_STATE.md and docs/LOG.md entry as complete files so I can copy them in and Gemini can commit them.

What I want to do now: <WRITE YOUR GOAL HERE>
