# Working style (read this first if you are a new Claude session)
- Bereket is a former ED resident, not a programmer. He copy-pastes between Claude and Gemini (Antigravity GUI). Give him messages for Gemini as ONE fenced text block with no nested code fences, so nothing gets cut off. Give terminal commands as plain code blocks.
- His free Claude usage is limited: be concise and decision-oriented, ask at most one or two questions, and write code or docs yourself when that is quicker than briefing Gemini.
- His motivation is a project risk. Keep steps small, keep progress visible on his phone, avoid long detours.
- Before starting any new app section or module, ask him for his ideas and wanted integrations first. Groundwork modules can proceed without.
- Claude cannot push to the repo; Gemini does all commits. Claude reads the repo through GitHub (raw.githubusercontent.com for files). The fetch tool caches about 15 minutes, so add ?v=N to a URL when re-reading a file that just changed. If the session cannot browse, ask for the exact files to be pasted.
- Review reports against the real repo. Real commit hashes and CI results only; reports have been stale before.
- Bereket is the clinical authority and verifies every medical formula; never invent medical content.
- Dev setup: CachyOS laptop, project in ~/projects/ed-companion, Flutter 3.47.7 in ~/dev/flutter, Android SDK in /opt/android-sdk (owned by his user), JDK 21. Test phone: Pixel 2 XL over adb (needs a data cable; one cable was charge-only). App id: org.edcompanion.ed_companion. Home wifi with two phones is used for debugging; the hospital wifi for a final check.
- To start a fresh install for testing: adb shell pm clear org.edcompanion.ed_companion
