# Brief 0001: Development environment and empty app scaffold

## Context
ED Companion is a Flutter Android app for emergency-department residents (see README.md and docs/ARCHITECTURE.md). The machine is a CachyOS (Arch Linux) laptop. The project folder is the current git repository, already connected to GitHub. This brief only prepares the tooling and creates an empty app that builds. No features.

## Goal
`flutter doctor` is green for Android, and an empty app named "ED Companion" builds a debug APK on this machine and in GitHub Actions.

## Do
1. Check what is already installed (`flutter`, `java`, `adb`, Android SDK). Install only what is missing, using the safest method for Arch (pacman or AUR, or the official Flutter and Android command-line tools downloaded into `~/dev/`). For anything needing `sudo` or a license prompt, stop and tell Bereket exactly what command to run and what to press, then continue after he confirms.
2. Use JDK 17 if Flutter requires it. Accept Android SDK licenses (`flutter doctor --android-licenses`). Install platform-tools, build-tools and one recent platform.
3. Create the Flutter app in `app/` with organization `org.edcompanion` and project name `ed_companion`. Android only (`--platforms=android`).
4. Set the app display name to "ED Companion". Set minSdk to the lowest value the current Flutter stable allows, and note that value in the report.
5. Add packages: flutter_riverpod, go_router, drift, drift_dev (dev), build_runner (dev), sqlite3_flutter_libs, path_provider, path. Nothing else.
6. Create the folder structure: `app/lib/core/`, `app/lib/features/` (empty subfolders `shell`, `patients`, `tools`, `hospital_view`, `study`, `ai`, `sync`, `handover`, each with a `.gitkeep`).
7. Replace the default counter screen with a single screen showing the text "ED Companion" and the app version. Use Riverpod's `ProviderScope` and go_router with one route, so later modules plug in.
8. Add a root `.gitignore` for Flutter, Android and IDE files, and make sure no build output, `local.properties` or keystores are committed.
9. Add `.github/workflows/build.yml`: on every push to `main`, run `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, and upload the APK as a workflow artifact named `ed-companion-debug`.
10. Add one trivial widget test that checks the "ED Companion" text appears.
11. Commit and push.

## Do not
- Add features, extra packages, or extra screens.
- Change anything under `docs/` except one line in `docs/LOG.md`.

## Acceptance criteria
- `flutter doctor` shows no errors for the Android toolchain.
- `flutter analyze` and `flutter test` pass.
- `cd app && flutter build apk --debug` succeeds.
- The GitHub Actions run on the push is green and produces the APK artifact.
- Bereket can install the APK on the Pixel 2 XL (`adb install -r app/build/app/outputs/flutter-apk/app-debug.apk`) and sees the "ED Companion" screen.

## Report
Write `reports/0001-report.md` as described in `docs/BRIEF_TEMPLATE.md`, plus: Flutter version, JDK version, minSdk value, and the exact install steps Bereket had to do by hand.
