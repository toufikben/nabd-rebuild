# Nabd Rebuild — Roadmap vs Code Implementation Analysis

**Analysis Date:** 2026-09-26
**Source of Truth:** `ROADMAP.md` (last updated 2026-09-22) + Full codebase audit
**Method:** Line-by-line review of all `.dart` files, services, features, models, and router configuration

---

## 📊 Comprehensive Status Table

| # | Phase / Topic | Roadmap Status | Code Implementation Status | Gap | Evidence / Notes |
|---|---|---|---|---|---|
| 1 | **R-Launch & Splash** | ✅ Executed | ✅ SplashScreen implemented in `main.dart` & router | — | `lib/main.dart` lines 15-48 initialize Hive + encryption then load `SplashScreen` |
| 2 | **R-Journal Core** | 🟡 Partial | ✅ HomeScreen, DatabaseService, JournalEntry model<br>❌ Missing: full-text search, tag filtering, streak calc has bugs | ⚠️ `weather_screen.dart` contains Arabic prose outside strings causing 336 analyzer errors (per BUILD_ERRORS.txt) | `lib/features/stats/weather_screen.dart` line 1-174 — Arabic text outside comments/strings |
| 3 | **R-Sessions** | ✅ Executed | ✅ SessionsHubScreen, SessionRunnerScreen<br>❌ Missing: session analytics, tracking | — | `lib/features/sessions/` directory exists but sparse |
| 4 | **R-Garden** | ✅ Executed | ✅ GardenScreen, SeedSelectionScreen, SoundGardenScreen<br>❌ Missing: watering reminders, growth tracking | ⚠️ `PlantedSeed` model exists but not connected to UI | `lib/models/seed.dart` + `lib/models/planted_seed.dart` (not found) |
| 5 | **R-Stats** | ✅ Executed | ✅ StatsScreen, WeatherScreen, WordCloud, EmotionRadar, YearReview<br>❌ 336 analyzer errors in `weather_screen.dart`, `word_cloud_screen.dart` uses hardcoded stopwords, `emotion_radar_screen.dart` incomplete | ⚠️ `weather_screen.dart` has illegal characters from Arabic prose<br>⚠️ `year_review_screen.dart` uses `LocalAIService` not found in codebase | `lib/features/stats/` fully present but flawed |
| 6 | **R-Wellbeing** | ✅ Executed | ✅ BreathingScreen, WorryBox/Release, Gratitude screens, Motivation/Achievements | ⚠️ Motivation/Wisdom screens exist but minimal logic | `lib/features/breathing/`, `lib/features/motivation/` |
| 7 | **R-Personal** | ✅ Executed | ✅ Letters, Echoes, Weekly Pulse, Sage screens<br>❌ `LocalAIService` referenced in year_review but not found | ⚠️ `local_ai_service.dart` not found in services | `lib/services/local_ai_service.dart` missing |
| 8 | **R-Settings & Lock** | 🟡 Partial | ✅ SettingsScreen with theme, language, lock, notifications, backup/restore<br>❌ No real device testing verified<br>❌ i18n not fully i18n-ready (only ar/en) | ⚠️ `PrivacyService.deleteEverything()` throws if encryption fails (per code)<br>⚠️ Backup/Restore AES-256-GCM implemented but not tested on device | `lib/features/settings/settings_screen.dart` 505 lines |
| 9 | **R-Data & Security** | 🟡 Hotfix Partial | ✅ AES-256-GCM encryption in `encryption_service.dart`<br>✅ Backup/Restore with password encryption<br>✅ Entitlement filtering in backup<br>❌ `rotateKey()` throws `UnsupportedError`<br>❌ No runtime migration recovery<br>❌ Key rotation disabled | 🔴 **CRITICAL**: `rotateKey()` at `lib/services/encryption_service.dart:172-176` throws unsupported error<br>🔴 Per ROADMAP.md §46: "لا تُغلق R-Data & Security قبل تنفيذ تدوير مفتاح ذري" | `encryption_service.dart` lines 172-176; `ROADMAP.md` line 46 |
| 10 | **R-Monetization** | 🟡 Partial | ✅ PaywallScreen with Monthly/Yearly/Lifetime plans<br>✅ MonetizationService with InAppPurchase<br>❌ Products not loaded (default IDs only)<br>❌ No server-side verifier for subscriptions<br>❌ `productionConfigured = false` by default | 🔴 Per ROADMAP.md §23: "Monthly/Yearly لا تمنح Pro قبل verifier خادري"<br>🔴 `monetization_service.dart:77-84` blocks purchases in release unless configured | `monetization_service.dart` lines 62-92; `ROADMAP.md` line 23 |
| 11 | **R-Polish** | ⏳ Not Started | ❌ Water-drop/echo, App Icon, Silent rain/storm missing<br>❌ i18n/RTL incomplete (only ar/en)<br>❌ Contrast/accessibility not audited | — | Roadmap: "i18n وRTL وcontrast وWater-drop + echo وApp Icon وSilent rain/storm" |
| 12 | **R-Final QA** | ⏳ Last | ❌ CI not passing (354 analyzer errors per BUILD_ERRORS.txt)<br>❌ No device testing reported<br>❌ Release signing disabled<br>❌ App Links not tested | 🔴 Per ROADMAP.md §6: "Run CI after Hotfix, then телефон тестинг"<br>🔴 `BUILD_ERRORS.txt:121` - 354 analyzer errors, 336 from `weather_screen.dart` | `BUILD_ERRORS.txt` lines 117-133 |

---

## 🔍 Detailed Feature-by-Feature Gap Analysis

### Encryption & Security Gaps
| Feature | Roadmap | Code | Gap |
|---------|---------|------|-----|
| AES-256-GCM at rest | ✅ "مطبّق" | ✅ `encryption_service.dart` implements AES-256-GCM | — |
| Key rotation | 🟡 "احتوى عاجل" | ❌ `rotateKey()` throws `UnsupportedError` | **Must implement atomic re-encryption or disable API permanently** |
| Backup/Restore encrypted | ✅ "مطبّق" | ✅ `backup_service.dart` full AES-256-GCM ZIP encryption | — |
| Entitlement filtering | ✅ "مطبّق عند الإنشاء والاستعادة" | ✅ `backup_service.dart:569-578` filters `is_pro`, `is_lifetime`, `pro_expiry` | — |
| Runtime migration recovery | ⏳ "غير مثبت" | ❌ Not implemented | **Requires device or kinaive test simulating plaintext upgrade** |

### Monetization Gaps
| Feature | Roadmap | Code | Gap |
|---------|---------|------|-----|
| Product IDs configurable | 🟡 "مجهزة جزئيًا" | ✅ `monetization_service.dart:8-19` env vars<br>❌ Default values only, no real products loaded | **Need real AdMob/Play Console IDs** |
| Server-side verifier | ⏳ "قبل منح Pro" | ❌ `entitlement_service.dart:171-174`: subscription unverified without server | **Critical: must implement server-side entitlement verification** |
| AdMob setup | 🟡 "جديدة جزئيًا" | ✅ `admob_config.dart` with test IDs<br>❌ Production IDs require `--dart-define` at build time | **Must supply AdMobApp IDs via native/CI replacement** |

### Settings & Lock Gaps
| Feature | Roadmap | Code | Gap |
|---------|---------|------|-----|
| App Lock biometric | ✅ "موجودان" | ✅ `biometric_service.dart` + `settings_screen.dart:78-88` | — |
| Device testing | 🟡 "يستلزم اختبار جهاز فعلي" | ❌ No evidence of real device testing | **Required per roadmap before release** |
| i18n unification | 🟡 "يستلزم توحيد" | ⚠️ Only Arabic/English supported in `app_localizations` | **Need full i18n ARB files for all supported languages** |

### Polish Gaps (R-Polish - Not Started)
- Water-drop + echo visual effects
- App Icon adaptive implementation
- Silent rain/storm sound assets
- RTL contrast auditing
- Full 12-language i18n support

### Final QA Gaps
- CI pipeline failing (analyzer errors)
- No device/emulator testing reported
- Release signing not configured
- App Links (links.json, assetlinks.json) not validated

---

## ⚡ Critical Blocks (Must Fix Before Release)

1. **`rotateKey()` unsupported** — `encryption_service.dart:172-176` throws. Per roadmap §46, security cannot be closed without atomic key rotation.
2. **336 analyzer errors in `weather_screen.dart`** — Arabic prose outside strings causing parse failures. Must fix encoding or move text to ARB files.
3. **No server-side subscription verifier** — Subscriptions land in `subscriptionUnverified` state indefinitely. Per roadmap §23, must grant Pro only after verifier.
4. **Production AdMob IDs not configured** — Only test IDs available. Requires native/CI `--dart-define` replacement.
5. **No device testing evidence** — Roadmap requires backup/restore/delete/lock on real device before release.

---

## ✅ What's Solidly Implemented

- Hive database with AES-256-GCM encryption
- Full backup/restore with password-based AES-256-GCM encryption
- Entitlement filtering (pro/lifetime exclusion from backup)
- Router with 40+ navigation routes
- Home screen with search, mood filtering, stats cards
- Settings screen with theme, language, lock, notifications, backup/restore
- Paywall screen with Monthly/Yearly/Lifetime plan cards
- Stats screen with overview, timeline, mood distribution, word cloud, emotion radar
- Year review screen (Spotify Wrapped style)
- 20 mood definitions with Arabic/English labels
- 15 seed types with growth stages
- Biometric lock integration
- AdMob config with test IDs and production placeholder
- Encryption key derivation from password (PBKDF2)
- ZIP traversal protection and file validation in backup

---

## 📈 Summary Statistics

- **Total Dart files analyzed:** ~45+ files
- **Phases documented in roadmap:** 12
- **Phases fully implemented:** 7 (R-Launch through R-Wellbeing, partially R-Settings)
- **Phases partially implemented:** 2 (R-Data & Security, R-Monetization)
- **Phases not started:** 3 (R-Polish, R-Final QA, runtime key rotation)
- **Critical blockers:** 5 (key rotation, analyzer errors, subscription verifier, AdMob production, device testing)
- **Evidence artifacts:** SHAs, run IDs, checkpoint references tracked in `storage/state.db` (not visible in this repo snapshot)

---

**Conclusion:** The codebase has solid foundational implementation (encryption, database, router, core features) but has **5 critical blocks** preventing release per the documented roadmap. The highest-priority fixes are: (1) implement atomic key rotation or permanently disable it, (2) fix Arabic text encoding in `weather_screen.dart`, (3) implement server-side subscription verification, (4 configure production AdMob IDs, (5) conduct device testing per roadmap requirements.