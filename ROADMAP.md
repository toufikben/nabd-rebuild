# خارطة طريق نبض — الحالة الموثقة

**آخر تحديث:** 2026-09-22 بعد تنفيذ Hotfix للتشفير والنسخ والإعلانات وتهيئة المشتريات
**الفرع:** `main`
**آخر commit قبل هذه الدفعة:** `7493fd8` — `fix: restore Android biometric prompt lifecycle`
**حالة التنفيذ:** تعديلات Hotfix محلية جاهزة للمراجعة والرفع إلى `origin/main`

## الحكم التنفيذي

المراحل من **R-Launch إلى R-Personal منفذة فعليًا بدرجات متفاوتة**. تم احتواء مخاطر التشفير والتصدير العاجلة في هذه الدفعة، لكن تدوير المفتاح الآمن الكامل والتحقق runtime ما زالا مطلوبين. كما تم تجهيز AdMob ومعرفات المنتجات للحقن وقت Release، بينما تبقى الاشتراكات الشهرية والسنوية غير مفعلة كـ Pro حتى إضافة verifier موثوق.

| # | المرحلة | الحالة الموثقة | القرار التالي |
|---:|---|---|---|
| 1 | R-Launch & Splash | ✅ منفذة | إبقاء صوت Splash الحالي ومراجعة UX لاحقًا فقط |
| 2 | R-Journal Core | 🟡 منفذة مع ديون صغيرة | تأجيل الأخطاء المعروفة، مع منعها من تعطيل Security وQA |
| 3 | R-Sessions | ✅ منفذة | إضافة اختبارات UI/runtime لاحقًا ضمن Final QA |
| 4 | R-Garden | ✅ منفذة | لا تُعاد إلى قائمة الانتظار؛ يلزم تحقق runtime فقط |
| 5 | R-Stats | ✅ منفذة | مراجعة دقة البيانات وRTL ضمن R-Polish/Final QA |
| 6 | R-Wellbeing | ✅ منفذة | تشمل Gratitude وWorry وBreathing وSilent وMotivation |
| 7 | R-Personal | ✅ منفذة | Letters وEchoes وWeekly Pulse وSage مرتبطة بالمسارات وتملك اختبارات منطق وWidget |
| 8 | R-Settings & Lock | ✅ منفذة جزئيًا | Settings وApp Lock موجودان؛ يلزم اختبار جهاز فعلي وتوحيد i18n |
| 9 | R-Data & Security | ✅ منفذة (تدوير ذري مطبق) | التدوير يعيد تشفير كل الصناديق مع نسخ احتياطية `.rotating` وتراجع تلقائي عند الفشل؛ يلزم إثباته على جهاز حقيقي |
| 10 | R-Monetization | 🟡 مجهزة جزئيًا | معرفات المنتجات قابلة للحقن، لكن Monthly/Yearly لا تمنح Pro قبل verifier خادمي |
| 11 | R-Polish | 🟡 جارية | i18n (6 شاشات أساسية ثم الباقي)، RTL، App Icon ✅ موجود،，声音 Splash موحّد ✅، وتباين الوضع الليلي ✅ |
| 12 | R-Final QA | ⏳ جارية | CI أخضر بـ 81 اختبارًا ✅، وبناء Debug APK/AAB ✅؛ يبقي اختبار جهاز وRelease signing وApp Links |

## R-Launch & Polish — سجل 2026-09-26

| البند | الحالة | التفصيل |
|---|---|---|
| أيقونة التطبيق | ✅ موجودة | `assets/icons/app_icon.png` + `app_icon_fg.png` + `ic_launcher_foreground.png`؛ لا عمل مطلوب |
| شاشة قبل Splash | ✅ مُزالة | `main.dart` كان يفتح 5 صناديق Hive مشفّرة قبل `runApp`، فكانت تشاشة بيضاء. الانتظار الثابت 3200ms أُلغي وصار 900ms كحد أدنى للتنقل |
| صوت Splash | ✅ موحّد | حُذف `splash_bowl/flute/harp/oud/rain` وخُفّض العدد من 5 عشوائيات إلى `tibetan_bowl` واحد؛ لا يقطع أول إطار |
| تباين الوضع الليلي | ✅ مُصلَح | `AppColors.text*/surface/background/border` صارت getters حساسة للسطوع، و`NabdApp` يزامن `AppColors.brightness` مع السمة |
| اختيار مكان حفظ النسخة | ✅ مضاف | Settings → Export Data يختار المسار عبر `FilePicker.saveFile` بدل المشاركة إلى مجلد مؤقت |
| استرجع مع Merge/Replace | ✅ مضاف | حوار اختيار الوضع؛ `RestoreMode.merge` يحافظ على الحالي، و`replace` يستبدل |
| رسالة نجاح/فشل صريحة | ✅ مضافة | SnackBar بعدد عدد المدخلات والصور والصوت، وسبب الفشل عند الرفض |
| تحديث الواجهة بعد الاسترجاع | ✅ مضاف | `dataRevisionProvider`؛ Home/Stats/Weather/Search/Garden/Calendar تعيد القراءة فورًا بلا إعادة تشغيل |
| i18n | ⏳ متبقٍ | 127 نصًا إنجليزيًا مثبتًا في ~30 ملفًا؛ `AppLocalizations` يعلن 16 لغة لكن `_value()` يخدم ar/en فقط |

## R-Data & Security — ما تم وما بقي

| الموضوع | الحالة الفعلية | الملاحظة |
|---|---|---|
| تدوير المفتاح | ✅ مطبَّق ذرّياً | لقطة لكل صندوق + نسخ `.rotating` + تحقق من كل سجل تحت المفتاح الجديد + تراجع تلقائي؛ترمي `KeyRotationException` إذا لم يوجد صندوق مفتوح |
| تشفير Hive at rest | ✅ مطبق | Migration versioned مع `HiveAesCipher` ومفتاح Secure Storage؛ يحتاج اختبار جهاز فعلي |
| AES-256-GCM للنصوص | ✅ مطبق | Nonce عشوائي وMAC للتحقق من التلاعب |
| Backup/Restore مشفر | ✅ مكتمل | كلمة المرور إلزامية، اختيار مكان الحفظ، Merge/Replace، ورسائل نجاح/فشل صريحة |
| منع entitlement من النسخة | ✅ مطبق عند الإنشاء والاستعادة | `is_pro` و`is_lifetime` و`pro_expiry` تُستبعد قبل بناء payload وتُفلتر عند الاستعادة |
| Key Rotation | 🟡 احتواء عاجل | `rotateKey()` الهدام معطل بفشل صريح؛ يلزم تنفيذ تدوير ذري أو إبقاء API معطلًا نهائيًا |
| Delete All Data | ✅ مسار مفتاح جديد بعد الحذف | لا يستخدم API التدوير الهدام؛ يلزم اختبار هاتف للتأكد من دورة الحياة |
| حماية مسارات ZIP | ✅ مطبق | فحص traversal والحجم وعدد الملفات والـschema والـduplicate IDs |
| Runtime migration recovery | ⏳ غير مثبت | يلزم جهاز أو اختبار تكاملي يحاكي ترقية بيانات plaintext وفشل الاستئناف |

## القرارات المؤجلة التي تبقى كما هي

يبقى تأجيل أخطاء Journal الصغيرة مقبولًا. تبقى ملفات Android الثلاثة المولدة سابقًا دينًا تقنيًا للمراجعة، لكنها ليست تغييرات غير متتبعة في working tree الحالي. يبقى Splash sound الحالي. يؤجل Water-drop + echo، وApp Icon، وSilent rain/storm الجديد إلى R-Polish.

## شروط إغلاق Security

لا تُغلق R-Data & Security قبل تنفيذ تدوير مفتاح ذري يحافظ على البيانات أو اعتماد قرار إبقاء API معطلًا، ثم اختبار migration وbackup/restore وdelete-all وkey lifecycle على جهاز أو emulator. التصدير أصبح مشفرًا وفلترة entitlement عند الإنشاء مطبقة، لكن ذلك لا يغني عن تحقق runtime.

## التحقق الأخير

- `git diff --check`: **PASS** بعد تعديلات Hotfix.
- تحقق XML/Info.plist: **PASS** محليًا.
- `flutter analyze` و`flutter test`: **بانتظار CI بعد رفع Hotfix**؛ Flutter SDK غير متاح في بيئة الفحص الحالية.
- اختبار الهاتف: **متبقٍ** ويشمل التصدير المشفر والحذف والمشتريات والإعلانات.
- AdMob Android: جاهز بعد إضافة `ADMOB_ANDROID_APP_ID` و`ADMOB_ANDROID_REWARDED_ID`.
- Google Play products: جاهزة للحقن عبر `NABD_PRO_MONTHLY_ID` و`NABD_PRO_YEARLY_ID` و`NABD_LIFETIME_ID`، لكن verifier الاشتراكات غير موجود.

## الترتيب التنفيذي بعد التدقيق

1. تشغيل CI بعد Hotfix وتصحيح أي أخطاء تحليل أو اختبار.
2. فحص الهاتف: backup مشفر، restore، Delete All، lock، وقراءة البيانات بعد إعادة التشغيل.
3. إضافة verifier موثوق للاشتراكات الشهرية والسنوية قبل منح Pro.
4. تشغيل Release مع متغيرات AdMob وGoogle Play والتحقق من عدم استخدام Test IDs.
5. نشر `assetlinks.json` ببصمة Release واختبار App Links.
6. تنفيذ R-Polish وR-Final QA ثم مراجعة المتجر والخصوصية.

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
