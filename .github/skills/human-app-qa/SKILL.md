---
name: human-app-qa
description: Human-level QA for the Nabd Flutter Android app. Use when validating a release, investigating regressions, or testing build, runtime, UI navigation, persistence, security, backup/restore, and adversarial behavior on a real device or emulator.
---

# Nabd Human-Level QA

Treat the application as an adversarial tester, not as a code reviewer. Never infer runtime success from static analysis, unit tests, or a successful build. Record the exact commit, tool versions, device state, commands, outputs, screenshots or logcat evidence, and the final status for every important test.

## Evidence statuses

Use only the following status labels:

- `STATIC_PASS`: source/configuration evidence only.
- `UNIT_PASS`: unit or widget tests passed.
- `INTEGRATION_PASS`: multi-service or persistence test passed without a real device.
- `RUNTIME_PASS`: the packaged app was installed and the user flow completed on a real device or emulator with evidence.
- `FAIL`: a reproducible defect or source-proven unsafe behavior exists.
- `BLOCKED`: the test could not be executed because of a documented environment, permission, or device limitation.
- `NOT_TESTED`: the test was intentionally not attempted; explain why.

Do not use “probably works”, “looks fine”, or “no issue found” as results.

## 1. Preserve the baseline

1. Record `git rev-parse HEAD`, branch, `git status --short`, and `git diff --check`.
2. Do not modify application source during diagnosis. Run generated-code commands in a clean copy or disposable worktree.
3. Do not commit or push during investigation.
4. Keep all evidence under a disposable QA directory, not inside the app source tree.
5. If a tool changes files, restore the clean copy and report the mutation separately.

## 2. Prepare the toolchain

Use the repository’s declared versions first. For Nabd, use Flutter 3.27.0, Dart 3.6.0, Java 17, Android SDK/platform tools, build-tools, and an API 35 system image when available.

Check:

```bash
flutter --version
dart --version
java -version
adb version
adb devices -l
emulator -version
```

Install missing packages when permitted. Check `/dev/kvm`; prefer hardware acceleration. If KVM is absent, try software rendering once with `-accel off` and `-gpu swiftshader_indirect`, but bound the wait and classify a non-booting emulator as `BLOCKED — ENVIRONMENT`. Do not claim a runtime test from a device that never reaches `sys.boot_completed=1`.

## 3. Static and build gates

Run in a clean copy:

```bash
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git diff --check
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

Verify that APK/AAB files exist, record byte sizes, inspect package/application ID, and distinguish local evidence from remote CI evidence. A build is not a UI or security pass.

## 4. Install and launch

With a booted emulator or device:

```bash
adb devices -l
adb install -r <apk>
adb shell am force-stop com.nabd.journal
adb shell monkey -p com.nabd.journal 1
adb logcat -c
adb logcat -v time > runtime-logcat.txt
```

Capture cold start, first launch, repeated launch, background/foreground, force-stop/relaunch, crashes, fatal exceptions, and ANR indicators. Stop log capture after each scenario and archive the output with the scenario name.

## 5. Human interaction matrix

For every major screen, open it as a user would, wait for loading to finish, use Android Back, enter and clear text, invoke the keyboard, tap buttons twice, navigate rapidly, leave while an async operation is pending, return to the screen, and test empty, populated, loading, and error states.

Cover at least:

- Launch, onboarding, lock, language, RTL, dark mode, and lifecycle.
- Bottom navigation, Journal, editor, calendar, search, tags, settings, deep links, and unknown/invalid IDs.
- Journal create, save, autosave, edit, pin/unpin, search, calendar, delete, Delete All, restart, and force-stop persistence.
- Every Session: start, pause, resume, stop, completion, repeated start/stop, audio, background/foreground, and return to Journal.
- Garden seed selection, interaction, audio, persistence, and restart.
- Stats with empty and populated data, refresh, navigation, and consistency with Journal/Sessions.
- Silent Companion start/stop, volume, navigation, and lifecycle.

Use a test ledger with: `TEST`, preconditions, exact steps, expected result, observed result, evidence path, status, and severity.

## 6. Data, security, and destructive flows

Test with real app data and a second run after restart:

- Hive encryption, secure key creation, missing key, invalid key, corrupted storage, and reopen.
- Plaintext-to-encrypted migration, interrupted migration, incomplete staging, corrupted staging, restart recovery, and data preservation.
- Delete All: database, settings, media, key lifecycle, force-stop, relaunch, and proof that old data is absent.
- Key rotation: data must remain readable after rotation; changing a key without re-encrypting data is a failure.
- Backup: required password, wrong password, corrupted MAC, duplicate payloads, invalid metadata, oversized archive, traversal names, duplicate IDs, media, entitlement leakage, and plaintext export.
- Restore replace and merge, failure during database/media commit, rollback, media rollback, repeated restore, and restart after restore.
- Validate all persisted file paths remain inside the app-owned media roots. Never allow a backup to cause deletion of arbitrary app-accessible files.
- Verify that security policy values such as App Lock are allowlisted, typed, and not silently weakened by restore.

Use fault injection or process termination only in a disposable data directory. Repeat every confirmed failure at least twice before classifying it as confirmed.

## 7. Adversarial testing

Try double taps, repeated save/delete/restore, rapid navigation, Back during loading, background or force-stop during save/restore/migration, wrong passwords, malformed and huge payloads, long Arabic text, empty and unexpected input, denied permissions, unavailable storage/network, and repeated lifecycle transitions.

When a defect is found:

1. Save the first evidence.
2. Reproduce it a second time without changing code.
3. Record root cause and exact file/line evidence.
4. Do not fix it during baseline diagnosis unless the user explicitly starts a repair phase.
5. After a repair phase, repeat the failing test and the related regression set.

## 8. Independent review

Request an independent review for security/data, backup/restore, navigation, and runtime risks. Resolve disagreements by returning to source lines, command output, or device evidence. Never average two opinions.

## 9. Final report

Report these rows at minimum: Build, Runtime, Launch, Navigation, Journal, Sessions, Garden, Stats, Silent, Encryption, Migration, Delete All, Key Rotation, Backup, Restore, Security. Include separate sections for `Confirmed Bugs`, `Suspected Problems`, `Blocked Tests`, `Fixed During QA`, and `Untested`.

For each claim include evidence. State clearly whether the app passed Runtime QA. A successful Flutter test or build must never be presented as a runtime pass.

## 10. GitHub-hosted Runtime QA

When local Android Emulator cannot boot because KVM is absent or inaccessible, use `.github/workflows/android-runtime-qa.yml` before declaring Runtime QA blocked. The workflow must use a GitHub-hosted runner, Java 17, the repository Flutter version, Android API 35 or the project-compatible API, an x86_64 Google APIs image, and a trusted emulator action such as `reactivecircus/android-emulator-runner@v2`.

The workflow must build the debug APK, boot the AVD, wait for `sys.boot_completed=1`, record `adb devices`, install `com.nabd.journal`, launch it, force-stop and relaunch it, capture screenshots, package/activity information, logcat, crash/ANR signatures, APK metadata, and upload all evidence as artifacts. It must stop the emulator in an `always()` cleanup step.

Do not label Runtime `PASS` until the workflow run proves emulator boot, APK installation, app launch, smoke-flow execution, and saved evidence. A workflow configuration that was not executed is not runtime evidence. If GitHub runner execution fails, read the run log, correct only QA infrastructure, rerun it, and report the exact remaining GitHub limitation.

The initial smoke flow is intentionally narrow: install, cold launch, Home, Journal, Sessions, Garden, Stats, Silent Companion, Back navigation, force-stop, and relaunch. Do not repair application bugs during this infrastructure phase.
