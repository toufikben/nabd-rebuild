# MODIFY Checklist — مراجعة يدوية

هذه قائمة بكل `MODIFY` لم تُطبَّق آليًا. يجب مراجعتها يدويًا بعد تشغيل المشروع في بيئة Flutter.

## ✅ تم تجاوزها بـ REPLACE

| # | الملف | الحالة |
| :--- | :--- | :--- |
| 1 | `lib/main.dart` | ✅ استُبدل كاملًا (v2) |
| 2 | `lib/app.dart` | ✅ استُبدل كاملًا |
| 3 | `lib/core/router.dart` | ✅ استُبدل كاملًا (المرحلة السابعة) |
| 4 | `pubspec.yaml` | ✅ استُبدل كاملًا (v2) |
| 5 | `l10n.yaml` | ✅ استُبدل كاملًا (v2) |

## ⚠️ تحتاج مراجعة يدوية

### 1. `lib/features/home/home_screen.dart`

**ما يجب التحقق منه:**

- [ ] أيقونة `Icons.insights_outlined` → `/stats`
- [ ] أيقونة `Icons.calendar_today_outlined` → `/calendar`
- [ ] أيقونة `Icons.settings_outlined` → `/settings`
- [ ] أيقونة `Icons.spa_outlined` → `/garden` (جديد)
- [ ] استيراد `go_router`
- [ ] عرض `DailyQuoteWidget`
- [ ] شريط البحث

### 2. `lib/features/editor/editor_screen.dart`

**ما يجب التحقق منه:**

- [ ] استدعاء `GardenService.water(entry)` بعد كل حفظ
- [ ] عرض `GardenWateringDialog`
- [ ] import `garden_service.dart`
- [ ] import `garden_watering_dialog.dart`

### 3. `lib/features/settings/settings_screen.dart`

**ما يجب التحقق منه:**

- [ ] قسم `Mind & Soul`:
  - [ ] Mood Weather → `/weather`
  - [ ] Release a Worry → `/worry-release`
  - [ ] Worry Box → `/worry-box`
  - [ ] Breathing → `/breathing`
  - [ ] Gratitude Garden → `/gratitude-garden`
  - [ ] Letters to Future Me → `/future-letters`
  - [ ] Dream Journal → `/dream-journal`
  - [ ] Daily Gratitude → `/gratitude-journal`
- [ ] قسم `Advanced Stats`:
  - [ ] Word Cloud → `/word-cloud`
  - [ ] Emotion Radar → `/emotion-radar`
  - [ ] Year Review → `/year-review`
  - [ ] Heatmap → `/heatmap`
- [ ] قسم `Social (Local)`:
  - [ ] Unsent Letters → `/unsent-letters`
  - [ ] Legacy Journal → `/legacy-journal`
  - [ ] Time Capsule → `/time-capsule`
- [ ] قسم `Motivation`:
  - [ ] Achievements → `/achievements`
  - [ ] Challenges → `/challenges`

### 4. `lib/features/chat/voice_search_screen.dart`

**ما يجب التحقق منه:**

- [ ] `item['op']?.toString() ?? ''` بدل `item['op'] ?? ''`
- [ ] حذف unused import

### 5. `lib/services/model_manager.dart` (إن وُجد)

**ما يجب التحقق منه:**

- [ ] `// ignore_for_file: avoid_slow_async_io` في السطر الأول
- [ ] `if (totalBytes > 0) { onProgress?.call(...); }`

## 🔍 أوامر التحقق

