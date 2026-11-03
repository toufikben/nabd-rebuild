# On-device QA — Pulse 1.0.2 (265) — 2026-11-03

Device: Realme RMX3910 (serial omitted) — Android 16 — 720×1604, 320 dpi.
Build: `device-test-output/release-41603334340/app-release.aab` (uploaded/installed manually by owner).
Install proof: versionCode **265**, versionName **1.0.2**, minSdk 24, targetSdk 36.
All UI evidence from `device-test-output/qa/run-20261103-191941/`.

| Check | Result | Evidence |
|---|---|---|
| Release installed and matches Play upload | PASS | `install_verify.txt`, `package_dump.txt`, Settings screenshot dump (`window8.xml`) |
| Cold start | PASS | `am start -W`: 3246 ms on 265; 2375 ms after cache warm-up |
| Rendering / jank | PASS | `gfxinfo framestats`: 173 frames, 4.62% janky, 50th/95th = 5/19 ms |
| Memory | PASS | PSS 134.4 MB, total RSS 226.9 MB |
| Screens render (FLAG_SECURE intentional) | PASS | uiautomator dumps; screenshots black by design |
| Entry creation and persisted state | PASS | `window12.xml` (test entry created), `window45.xml` (1 day streak, 1 this month, 3% garden growth) |
| Encrypted backup created | PASS | `nabd_backup_1793730525208.nabd` in Downloads, 1.33 KB |
| Restore backup — Replace | PASS | Backup now the only content; marker2 disappeared; `window42.xml` snackbar: “Replaced with 1 entry (0 images, 0 audio, 1 seed)”; `window43/46` confirm only `BACKUPTESTMARKER` remains |
| Restore backup file is hard to find in DocumentsUI | OBSERVATION | `.nabd` file not listed in Downloads/Documents category; visible under Recent files and searchable by exact name. Restorable but needs instruction |
| Voice recording (RECORD_AUDIO live) | PASS | Permission granted via system dialog; live recording UI shown with timer; stop/play controls appeared; no crash |
| Play output | PASS | `AudioFlinger` engaged, no `FATAL/AndroidRuntime` |
| Arabic UI / RTL | PASS | Arabic locale renders correctly and layout mirrors; switched back to English successfully |
| Font scale 130% | PASS | App relaunched, text grows, no crash or overlap in main layout; scale reset to 1.0 |
| Back navigation / tab bar | PASS | `PopScope` behavior gives Back→Today; Today/Journal/Practice/Garden/Insights tabs tappable after fresh start |
| Widget provider registered with system | PASS | `appwidget_dump.txt` index [132], `cmp=com.nabd.journal/com.nabd.journal.JournalWidgetProvider` |
| Widget appears in Realme widget picker | FAIL / NOT VERIFIED | Picker listed Clock, ADM, AI…, YouTube, etc.; Pulse absent after full scroll. Provider is registered, so this is likely launcher caching or Realme limitation — but placement/rendering/taps could not be verified |
| Crash on main flows | PASS | No `FATAL`, `AndroidRuntime`, or `E/flutter` in logcat |

## Not pass / not verified

1. **Home-screen widget placement** — NOT VERIFIED on this device. Pulse is invisible to the Realme widget picker.
2. **Real purchase/restore** — NOT VERIFIED. Requires license tester account and Play user opt-in.
3. **Voice dictation** — RECORD_AUDIO path verified; online dictation left OFF; offline speech pack not tested.
4. **App Lock / biometrics** — not exercised in this run.
5. **Backup restore with other users’ real data** — test used synthetic data only.

## Observations

- `.nabd` files are shown in file picker under “Recent files”, not under “Downloads/Documents”. Restore works, but users should look in Recent or search exact filename.
- Release screen is correctly protected by `FLAG_SECURE`: screenshots black. UI checks relied on UI hierarchy and logs.
- A restore “Replace” creates an automatic safety snapshot (`Undo last replace`) and reports the count — both worked.
- Device shows dark mode by default; app renders correctly.

## Recommendation

Do not release to production from this build until the widget placement issue is either resolved or waived by the owner. All other checks passed. Internal testing release 263/265 may continue; ask owner about Realme picker behavior or add launcher-cache/QA account retest after permission grant/install. If picker still omits Pulse, check `widget_journal_info` and Realme launcher widget blacklist or install validation.
