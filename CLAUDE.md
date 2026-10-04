# Nabd — rules for Claude sessions

## The owner's computer never builds

The owner's PC is too weak (2 cores, 4 GB RAM, HDD) for Flutter. In a session
running on that machine:

- **Never** run `flutter build`, `flutter run`, `flutter pub get`, `flutter test`,
  `gradlew`, or anything that downloads the Flutter/Android SDKs or Gradle.
- Builds happen **only on GitHub Actions** (`.github/workflows/android-build.yml`).
  Run it manually (Actions → Android Build → Run workflow, on the working
  branch). When it finishes, the **Releases** page has a `build-<n>`
  pre-release with:
  - `nabd-debug-arm64.apk`, for device testing (allows adb screenshots);
  - `nabd-release.apk`, when signed release builds are enabled.
- The phone installs that APK directly from the Releases page. A PC session
  only drives the already-installed app over adb (`scripts/device/nabd.sh`);
  `nabd.sh install` is for an APK that is already on disk, never one it built.

Cloud sessions (Linux containers) may build and test freely.

## Device testing

Follow `docs/DEVICE_TEST_PLAN.md`. Do not edit app code from a device-test
session; write findings to `device-test-output/REPORT.md`.

## Conventions

- Every user-facing string lives in `l10n/<code>.json`, one file per language,
  with `l10n/en.json` as the reference key set and `l10n/languages.json` as the
  language list. Add a key to **every** language file, then run
  `python3 scripts/gen_l10n.py` (it regenerates `lib/core/l10n/strings/*.dart`,
  `lib/core/l10n/languages.dart` and the Android `strings.xml` files; never edit
  those by hand). `test/i18n_test.dart` checks key and `{placeholder}` parity
  and that the generated files match the JSON; `test/i18n_literal_ui_test.dart`
  forbids literal UI text in `lib/features` and `lib/widgets`.
- Never branch on a specific language (`languageCode == 'ar'`); use
  `l10n.language.rtl`, `l10n.language.speechLocale` or the locale's own
  formatting (`DateFormat`, `MaterialLocalizations`).
- Sounds are synthesised (`scripts/synth_sounds.py`, `scripts/synth_ambience.py`);
  never add third-party audio.
- `flutter analyze` must be clean and `flutter test` green before a push.
