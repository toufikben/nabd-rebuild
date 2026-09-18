# خارطة طريق نبض — Nabd

**آخر تحديث:** 2026-09-16 بعد حزمة UI/UX  
**الفرع:** `main`  
**آخر commit:** `defd8fd` — `feat: refresh Nabd navigation and Material 3 theme`

## الحالة الحالية

المستودع مرفوع بالكامل إلى GitHub، والفرع المحلي `main` متزامن مع `origin/main`. آخر تشغيل GitHub Actions نجح في التحليل والاختبارات وبناء Debug APK وDebug AAB ورفع الـArtifacts.

| الأولوية | البند | الحالة | الملاحظات المتبقية |
|---|---|---|---|
| P0 | حماية بيانات Hive at rest | ✅ مطبق | Migration versioned إلى `HiveAesCipher` مع مفتاح Secure Storage؛ يلزم اختبار runtime على جهاز فعلي |
| P0 | تشفير النصوص والنسخ الاحتياطي | ✅ مطبق | AES-256-GCM ومفتاح غير hardcoded |
| P0 | منع entitlement من النسخ الاحتياطي | ✅ مطبق | restore يتجاهل `is_pro` و`is_lifetime` و`pro_expiry` مع regression tests |
| P0 | اشتراكات المتجر | ⚠️ صادق جزئيًا | lifetime يعتمد على callback فعلي؛ monthly/yearly تحتاج server-side receipt/entitlement verification |
| P0 | Android package وManifest وWidget وShortcuts | ✅ متحقق | CI بنى المشروع بنجاح |
| P1 | CI Analyze/Test | ✅ ناجح | GitHub Actions run `35025782130` |
| P1 | Debug APK | ✅ ناجح | بُني على GitHub runner وتم رفعه كـArtifact |
| P1 | Debug AAB | ✅ ناجح | بُني على GitHub runner وتم رفعه كـArtifact |
| P1 | Release APK/AAB | ⏳ متبقٍ | يحتاج keystore production وSecrets وتهيئة signing داخل workflow |
| P1 | App Links routes | ✅ مطبق | custom scheme وHTTPS routes مرتبطة بالـGoRouter |
| P1 | App Links domain verification | ❌ غير مكتمل | `https://nabd.app/.well-known/assetlinks.json` يعيد 404؛ يلزم SHA-256 لشهادة Release ونشر الملف |
| P1 | Backup validation | ✅ مطبق | metadata/schema/duplicate IDs/path traversal/ZIP limits/entitlement filtering |
| P1 | UI/UX navigation refresh | ✅ مطبق | Material 3 theme، bottom navigation، Writing/Journey/Insights hubs، ودعم dark/gender themes |
| P1 | Localization وRTL وTheme | ⚠️ static فقط | يلزم اختبار runtime على جهاز أو emulator |
| P2 | Physical runtime validation | ⏳ متبقٍ | لا يوجد جهاز أو emulator متاح في بيئة التدقيق |
| P2 | iOS scaffold/release | ⏳ متبقٍ | لم يُجهز مسار release كامل لـiOS |

## التحقق المنجز

- `flutter analyze`: **PASS — No issues found**
- `flutter test`: **PASS — 42 tests passed**
- `dart format` للملفات المعدلة: **PASS**
- `git diff --check`: **PASS**
- GitHub Actions Analyze/Test: **PASS**
- GitHub Actions Debug APK: **PASS**
- GitHub Actions Debug AAB: **PASS**
- فحص secrets داخل source: لم توجد مفاتيح أو tokens مضمّنة.
- البناء المحلي لم يُنفذ بنجاح بسبب عدم وجود Android SDK، لذلك الاعتماد في APK/AAB على نتيجة GitHub Actions الفعلية.

## خارطة الطريق التالية

### 1. تفعيل Release signing

إضافة keystore production إلى GitHub Actions Secrets، ثم تعديل workflow ليستخدم `ANDROID_KEYSTORE_BASE64` و`ANDROID_KEYSTORE_PASSWORD` و`ANDROID_KEY_PASSWORD` و`ANDROID_KEY_ALIAS`، وبعدها تشغيل Release APK/AAB.

### 2. إكمال App Links

استخراج SHA-256 من شهادة Release الفعلية، إنشاء `/.well-known/assetlinks.json` بالقيم الحقيقية، نشره على `nabd.app`، ثم اختبار `/journal` و`/garden` على Android.

### 3. إكمال entitlement verification

ربط `PurchaseProvider` بخدمة تحقق موثوقة للـGoogle Play/App Store لتحديد renewal وexpiry وcancellation، وعدم اعتبار الاشتراك Pro قبل وصول entitlement موثوق.

### 4. اختبار runtime

على جهاز أو emulator: install، onboarding، إنشاء/تعديل/حذف entry، البحث، tags، garden، lock، background/resume، notification، widget، shortcut، deep link، Arabic RTL، dark mode، backup/restore، وdelete-all.

### 5. Release readiness

بعد إغلاق signing وApp Links وentitlements وruntime tests، تشغيل release builds، مراجعة الأذونات، سياسة الخصوصية، AdMob IDs الإنتاجية، وPlay Store checklist.

## القيود المعروفة

- لا يمكن اعتبار App Links verified قبل نشر `assetlinks.json` ببصمة Release حقيقية.
- لا يمكن اعتبار monthly/yearly subscriptions verified دون server-side receipt validation.
- لا توجد نتيجة physical device/emulator في هذه البيئة.
- صلاحية GitHub Secrets نفسها لم يمكن قراءتها عبر token الحالي؛ قيم الأسرار لا تُكشف ولا تُفحص من داخل المصدر.
