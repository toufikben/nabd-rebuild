# خارطة طريق نبض — الحالة الموثقة

**آخر تحديث:** 2026-09-22 بعد إصلاح biometric prompt والتحقق على هاتف فعلي
**الفرع:** `qa/runtime-emulator`
**آخر commit:** `cd47f6d` — `fix: restore Android biometric prompt lifecycle`
**حالة المستودع بعد التحقق:** إصلاح App Lock مدفوع إلى `qa/runtime-emulator`، ونُسخ إلى `main` كـcommit مستقل

## الحكم التنفيذي

المراحل من **R-Launch إلى R-Personal منفذة فعليًا بدرجات متفاوتة**، ولذلك لم يعد صحيحًا وضع Garden وStats وWellbeing وPersonal تحت «لاحقًا». المرحلة الوحيدة المفتوحة كحاجز أمني فعلي هي **R-Data & Security**. لا ينبغي الانتقال إلى Monetization النهائية أو Final QA قبل إغلاق تدوير المفاتيح، وتوحيد مسار التصدير مع النسخ الاحتياطي المشفر، وإجراء تحقق runtime على جهاز أو emulator.

| # | المرحلة | الحالة الموثقة | القرار التالي |
|---:|---|---|---|
| 1 | R-Launch & Splash | ✅ منفذة | إبقاء صوت Splash الحالي ومراجعة UX لاحقًا فقط |
| 2 | R-Journal Core | 🟡 منفذة مع ديون صغيرة | تأجيل الأخطاء المعروفة، مع منعها من تعطيل Security وQA |
| 3 | R-Sessions | ✅ منفذة | إضافة اختبارات UI/runtime لاحقًا ضمن Final QA |
| 4 | R-Garden | ✅ منفذة | لا تُعاد إلى قائمة الانتظار؛ يلزم تحقق runtime فقط |
| 5 | R-Stats | ✅ منفذة | مراجعة دقة البيانات وRTL ضمن R-Polish/Final QA |
| 6 | R-Wellbeing | ✅ منفذة | تشمل Gratitude وWorry وBreathing وSilent وMotivation |
| 7 | R-Personal | ✅ منفذة | Letters وEchoes وWeekly Pulse وSage مرتبطة بالمسارات وتملك اختبارات منطق وWidget |
| 8 | R-Settings & Lock | 🟡 منفذة مع Runtime جزئي مثبت | تم التحقق على هاتف فعلي من cold start وظهور شاشة القفل ونجاح البصمة؛ ما زال يلزم اختبار background timeout وfailure/retry وlifecycle الكامل |
| 9 | R-Data & Security | 🔴 الحاجز الحالي | إغلاق Key Rotation والتصدير غير المشفر واختبارات runtime للترحيل والنسخ |
| 10 | R-Monetization | 🟡 منفذة جزئيًا | Lifetime يعمل من callback المتجر؛ Monthly/Yearly تحتاج تحقق entitlement خادمي |
| 11 | R-Polish | ⏳ بعد Security | i18n وRTL وcontrast وWater-drop + echo وApp Icon وSilent rain/storm |
| 12 | R-Final QA | ⏳ أخيرة | Release signing وruntime matrix وApp Links وBackup/Restore وStore checklist |

## R-Data & Security — ما تم وما بقي

| الموضوع | الحالة الفعلية | الملاحظة |
|---|---|---|
| تشفير Hive at rest | ✅ مطبق | Migration versioned مع `HiveAesCipher` ومفتاح Secure Storage؛ يحتاج اختبار جهاز فعلي |
| AES-256-GCM للنصوص | ✅ مطبق | Nonce عشوائي وMAC للتحقق من التلاعب |
| Backup/Restore مشفر | 🟡 مطبق مع فجوات | النسخة مشفرة ومتحققة، لكن مسار التصدير في Settings يشارك JSON نصيًا غير مشفر |
| منع entitlement من النسخة | 🟡 جزئي | `restore` يفلتر entitlement، لكن `createBackup` يجمع إعدادات entitlement داخل الأرشيف قبل الفلترة |
| Key Rotation | 🔴 غير مغلق | `rotateKey()` يحذف المفتاح وينشئ مفتاحًا جديدًا دون إعادة تشفير Hive؛ قد يجعل البيانات غير قابلة للقراءة |
| Delete All Data | 🟡 مطبق | يحذف الصناديق والوسائط، لكنه يتعمد إبقاء مفتاح التشفير؛ يجب تثبيت قرار دورة حياة المفتاح باختبار وسياسة واضحة |
| حماية مسارات ZIP | ✅ مطبق | فحص traversal والحجم وعدد الملفات والـschema والـduplicate IDs |
| Runtime migration recovery | ⏳ غير مثبت | يلزم جهاز أو اختبار تكاملي يحاكي ترقية بيانات plaintext وفشل الاستئناف |

## R-Settings & Lock — تحديث 2026-09-22

| الموضوع | الحالة الفعلية | الدليل أو المتبقي |
|---|---|---|
| `inactive` لا يبدأ lock timeout | ✅ مطبق | `lib/app.dart` يتجاهل الحالة transient لحماية biometric prompt |
| `hidden` و`paused` يسجلان الخلفية | ✅ مطبق | كلاهما يستدعي `BiometricService.markBackgrounded()` |
| `resumed` يفحص القفل دون navigation loop | ✅ مطبق | يفحص `shouldShowLock()` ولا ينتقل إلى `/lock` إذا كان المسار الحالي هو `/lock` |
| تكرار أحداث الخلفية | ✅ مختبر | اختبار مضاف في `test/app_lock_policy_test.dart` يثبت حفظ وقت الخلفية الأصلي |
| Android biometric Activity | ✅ أصلحت | `MainActivity` أصبحت `FlutterFragmentActivity` المطلوبة لـ`local_auth` |
| Cold start lock | ✅ مثبت جزئيًا | المستخدم أغلق وفتح التطبيق، وظهرت `Journal Locked` على هاتف فعلي |
| Biometric prompt وفتح القفل | ✅ مثبت جزئيًا | بعد الإصلاح ظهرت نافذة المصادقة ونجحت البصمة وفتح التطبيق |
| Failure ثم Retry | 🟡 يحتاج إعادة تحقق | ظهرت مشكلة سابقة بعد فشل المحاولة؛ أضيف reset للحالة و`useErrorDialogs`، ويلزم اختبار فشل ثم إعادة المحاولة |
| Background/timeout lifecycle | ⏳ غير مثبت | يلزم اختبار إرسال التطبيق للخلفية والعودة بعد المهلة |

## القرارات المؤجلة التي تبقى كما هي

يبقى تأجيل أخطاء Journal الصغيرة مقبولًا. تبقى ملفات Android الثلاثة المولدة سابقًا دينًا تقنيًا للمراجعة، لكنها ليست تغييرات غير متتبعة في working tree الحالي. يبقى Splash sound الحالي. يؤجل Water-drop + echo، وApp Icon، وSilent rain/storm الجديد إلى R-Polish.

## شروط إغلاق Security

لا تُغلق R-Data & Security قبل تنفيذ تدوير مفتاح آمن أو إزالة API الحالي واستبداله بمسار واضح يحافظ على البيانات. يجب أن يصبح Export Data إما نسخة احتياطية مشفرة أو أن يوضح للمستخدم صراحة أنه تصدير نصي غير مشفر مع تأكيد أمني. يجب حذف entitlement من محتوى النسخة عند الإنشاء، لا الاكتفاء بتجاهله عند الاستعادة. بعد ذلك يجب اختبار migration وbackup/restore وdelete-all وkey lifecycle على جهاز أو emulator.

## التحقق الأخير

- `dart format --output=none --set-exit-if-changed lib/app.dart test/app_lock_policy_test.dart`: **PASS**.
- `flutter analyze`: **PASS — No issues found**.
- `flutter test`: **PASS — All tests passed** (72 test completions في السجل).
- `flutter build apk --debug`: **PASS** محليًا باستخدام JDK 17 — `app-debug.apk`.
- `flutter build apk --release`: **PASS** محليًا باستخدام JDK 17 — `app-release.apk`.
- `flutter build appbundle --release`: **PASS** محليًا باستخدام JDK 17 — `app-release.aab`.
- Runtime Emulator: **BLOCKED سابقًا** — لا يوجد `/dev/kvm` محليًا؛ أما App Lock فقد تم التحقق جزئيًا على هاتف فعلي.
- GitHub Actions على commit `a889014`: **PASS** في run `35501185195`.
- `git diff --check`: **PASS**.
- working tree: **clean** على `qa/runtime-emulator`؛ `main` بقي دون تعديل.

## الترتيب التنفيذي بعد التدقيق

1. إعادة اختبار App Lock على الهاتف: بصمة خاطئة ثم `Unlock`، ثم background/timeout.
2. إغلاق R-Data & Security: key rotation، تصدير آمن، entitlement filtering عند الإنشاء، واختبارات runtime.
3. تنفيذ Runtime backup/restore وmigration وDelete All على الهاتف.
4. تشغيل Release APK/AAB مع keystore production والتحقق من نتيجة CI الفعلية.
5. تنفيذ App Links domain verification ونشر `assetlinks.json` ببصمة Release.
6. إكمال R-Polish، مع التركيز على i18n وRTL وcontrast قبل التجميل الصوتي والبصري.
7. تنفيذ R-Final QA على جهاز أو emulator، ثم مراجعة الأذونات وAdMob وسياسة الخصوصية ومتطلبات المتجر.
8. اعتبار Monetization مغلقة فقط بعد وصول entitlement موثوق للاشتراكات الشهرية والسنوية.

## مراجع الكود الأساسية

- [EncryptionService][1]
- [BackupService][2]
- [PrivacyService][3]
- [MonetizationService][4]
- [AppLockPolicy وBiometricService][5]
- [SettingsScreen][6]
- [CI Workflow][7]

[1]: lib/services/encryption_service.dart "تشفير البيانات وإدارة المفتاح"
[2]: lib/services/backup_service.dart "إنشاء واستعادة النسخ الاحتياطية"
[3]: lib/services/privacy_service.dart "حذف البيانات المحلية"
[4]: lib/services/monetization_service.dart "حالة المشتريات والتحقق المحلي"
[5]: lib/services/biometric_service.dart "سياسة قفل التطبيق والمصادقة الحيوية"
[6]: lib/features/settings/settings_screen.dart "إعدادات التطبيق والتصدير والحذف"
[7]: .github/workflows/android-build.yml "فحص وبناء Android عبر GitHub Actions"
