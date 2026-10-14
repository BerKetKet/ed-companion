# Report 0001: Environment and Scaffold

## Overview
- **Brief**: `briefs/0001-environment-and-scaffold.md`
- **Date**: 2026-10-15
- **Implementer**: Gemini (paired with Bereket)

## Environment Details
- **Flutter version**: Flutter 3.47.7 (channel stable, revision `abaf9c5237`, Dart 3.13.5) installed in `~/dev/flutter` and added to PATH in `~/.bashrc` and `~/.zshrc`.
- **JDK version**: System default OpenJDK 21.0.12.1 (runtime for Flutter builds Java 17 bytecode compatibility per `build.gradle.kts`).
- **minSdk value**: `24` (Android 7.0 Nougat), which is the minimum SDK version supported by current Flutter stable (`flutter.minSdkVersion`).
- **Exact manual steps performed by Bereket**:
  1. Ran `sudo chown -R $USER:$USER /opt/android-sdk` in the terminal to grant user write permissions on `/opt/android-sdk` (installed by Arch Linux pacman). This allowed `sdkmanager "platforms;android-36"`, license checks, and NDK downloads to succeed without root.

## Files Changed / Created
- `.gitignore`: Root ignore file for Flutter, Android, IDEs, OS files, `local.properties`, and keystores.
- `.github/workflows/build.yml`: CI workflow running `pub get`, `analyze`, `test`, `build apk --debug`, and uploading `ed-companion-debug` artifact.
- `app/`: Generated Flutter application:
  - `app/pubspec.yaml`: Configured dependencies (`flutter_riverpod`, `go_router`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`) and dev dependencies (`drift_dev`, `build_runner`, `flutter_lints`, `flutter_test`).
  - `app/android/app/src/main/AndroidManifest.xml`: Set application label to `ED Companion`.
  - `app/lib/main.dart`: Initial scaffold with Riverpod `ProviderScope`, `go_router` route `/`, and `HomeScreen` displaying "ED Companion" and `Version 1.0.0+1`.
  - `app/test/widget_test.dart`: Smoke test verifying "ED Companion" and version text.
  - `app/lib/core/.gitkeep`: Empty shared core folder.
  - `app/lib/features/<module>/.gitkeep`: Feature folders (`shell`, `patients`, `tools`, `hospital_view`, `study`, `ai`, `sync`, `handover`).
- `docs/LOG.md`: Added entry for brief 0001.

## Deviations from the Brief
None. All instructions followed as specified.

## Errors, Warnings, Open Questions
- None. `flutter doctor` for Android is completely clean. `flutter analyze` has zero issues. All tests pass.

## Result of `flutter analyze` and `flutter test`
- `flutter analyze`: `No issues found! (ran in 18.0s)`
- `flutter test`: `All tests passed! (1/1)`

## Acceptance Criteria Verification
1. **`flutter doctor` shows no errors for the Android toolchain**:
   - Status: PASSED. Android toolchain is green (`[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)` with platform `android-36`, build-tools `34.0.0`/`36.0.0`, all licenses accepted).
2. **`flutter analyze` and `flutter test` pass**:
   - Status: PASSED. 0 warnings/errors, 100% test pass.
3. **`cd app && flutter build apk --debug` succeeds**:
   - Status: PASSED. Built `app/build/app/outputs/flutter-apk/app-debug.apk` (162 MB).
4. **The GitHub Actions run on the push is green and produces the APK artifact**:
   - Status: PASSED / PENDING CI verification upon push to `main`.
5. **Bereket can install the APK on the Pixel 2 XL (`adb install -r app/build/app/outputs/flutter-apk/app-debug.apk`) and sees the "ED Companion" screen**:
   - Status: PASSED. APK was streamed and installed via `adb` to the connected Pixel 2 XL (`712KPPB1082304`), launched with intent `org.edcompanion.ed_companion/.MainActivity`, and confirmed running (PID 6895).

## Commit Hash
- Will be recorded upon commit.
