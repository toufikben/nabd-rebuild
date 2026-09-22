# خارطة الطريق الكبرى وحالة اكتمال مشروع نبض

**تاريخ التدقيق:** 2026-09-22  
**الفرع المفحوص:** `qa/runtime-emulator`  
**آخر SHA:** `04f2ae0037a0f176c551c39e54128d76a51eff80`
**نطاق التدقيق:** بنية التطبيق، الميزات، الأمن، الاختبارات، Runtime QA، إعدادات Android، الأصول، الترجمة، monetization، ومتطلبات المتاجر.

## الحكم التنفيذي

المشروع **ليس MVP ناقصًا من ناحية الواجهات**؛ معظم نطاق المنتج الوظيفي موجود في الكود: Journal، Garden، Stats، Wellbeing، Personal، Sessions، Settings، App Lock، Backup، وتشفير محلي. لكن المشروع **ليس جاهزًا للإطلاق الإنتاجي بعد**. الحواجز المتبقية ليست مجرد تجميل، بل تشمل دورة حياة مفاتيح التشفير، مسار التصدير، التحقق الفعلي للنسخ والترحيل على جهاز، Runtime App Lock، release signing، التحقق الحقيقي للمشتريات الاشتراكية، إعدادات AdMob الإنتاجية، App Links، والمراجعة النهائية للمتجر.

التقدير العملي:

| البعد | التقدير | التفسير |
|---|---:|---|
| اكتمال النطاق الوظيفي داخل الكود | 80–90% | معظم الشاشات والخدمات والمسارات الأساسية موجودة |
| اكتمال الاختبارات المحلية/المنطقية | 65–75% | توجد تغطية جيدة للمنطق والأمن وبعض Widgets، لكن تغطية UI/runtime محدودة |
| الجاهزية الأمنية للإطلاق | 45–55% | التشفير الأساسي موجود، لكن key rotation والتصدير ودورة entitlement غير مغلقة |
| جاهزية Android runtime | 65–75% | Analyze/Test وDebug APK/AAB نجحت في Build `35720099863`، وApp Lock الأساسي نجح على هاتف فعلي؛ ما زالت مصفوفة Runtime والنسخ التلقائي الميداني غير مكتملة |
| جاهزية المتجر والإطلاق | 35–45% | توجد أصول وملفات إعداد، لكن signing والمنتجات وAdMob وApp Links والنماذج لم تُثبت إنتاجيًا |
| الجاهزية الكلية للإطلاق | **حوالي 55–65%** | التطبيق متقدم وظيفيًا، لكنه ليس Release Candidate مغلق المخاطر |

هذه النسب **تقديرية تنظيمية وليست نتائج اختبار آلية**. لا تعني أن أي سيناريو Runtime أو App Lock ناجح ما لم يُنفذ فعليًا.

## حالة المستودع والحدود

- الفرع الحالي هو `qa/runtime-emulator`.
- الفرع متطابق مع `origin/qa/runtime-emulator` عند SHA `cd47f6d`.
- إصلاح App Lock موجود على `qa/runtime-emulator`، ونُسخ إلى `main` كـcommit مستقل `7493fd8` دون merge لتغييرات QA.
- تم تعديل ثلاثة ملفات مرتبطة مباشرة بـApp Lock: `MainActivity.kt` و`lock_screen.dart` و`biometric_service.dart`.
- لم يُعدّل `lib/app.dart` ولا الاختبارات.

## تقييم المراحل الكبرى

| المرحلة | الحالة | ما هو موجود | ما يمنع الإغلاق |
|---|---|---|---|
| R-Launch & Splash | منفذة وظيفيًا | Splash متعددة المشاهد، منع تكرار، صوت وtransition | تحسينات صوتية/بصرية اختيارية ومراجعة أجهزة مختلفة |
| R-Journal Core | منفذة مع ديون | editor، entries، mood، tags، search، calendar، favorites، media paths | نقص تغطية UI/integration لمسارات create/edit/delete/media ومراجعة بعض النصوص |
| R-Sessions | منفذة | models، breathing engine، runner، controls، audio ownership | Runtime على جهاز، واختبار القفل التجاري للجلسات المدفوعة |
| R-Garden | منفذة | seeds، growth، watering، certificate، screens، sound | Runtime flow واختبار persistence عبر إعادة التشغيل |
| R-Stats | منفذة وظيفيًا | stats، heatmap، weather، word cloud، emotion radar، year review | مراجعة دقة الحسابات، RTL، contrast، واختبار بيانات حقيقية |
| R-Wellbeing | منفذة وظيفيًا | Gratitude، Worry، Breathing، Silent، Motivation، Wisdom، Achievements، Challenges | توحيد i18n، تغطية Widgets/runtime، وتحسينات Silent الصوتية |
| R-Personal | منفذة وظيفيًا | Letters، Echoes، Weekly Pulse، Sage وربطها بالـrouter | توسيع UI/runtime coverage؛ بعض الاختبارات المنطقية موجودة |
| R-Settings & Lock | جزئية ومثبتة على هاتف فعلي | settings، themes، language، notifications، deletion، App Lock cold start وbiometric prompt | background timeout، failure/retry المنهجي، lifecycle الكامل، ونقص i18n |
| R-Data & Security | **الحاجز الحالي المتبقي** | AES-256-GCM، Hive encryption، Backup/Restore مشفر، WorkManager للجدولة، مجلد افتراضي وإشعارات الحالة | إثبات هاتف فعلي للنسخ التلقائي، key rotation الآمن، migration وkey lifecycle |
| R-Monetization | جزئية | IAP products، purchase stream، lifetime callback، Paywall، rewarded ads config | server-side subscription entitlement، real store products، sandbox purchase/restore/failure |
| R-Polish | غير مغلقة | أساس theme وARB عربي/إنجليزي وأصول موجودة | i18n/RTL/contrast، hardcoded English، app icon verification، water-drop/echo، Silent rain/storm |
| R-Final QA | غير منفذة بالكامل | Workflow، APK debug artifact، runtime diagnostics | release matrix، App Links، backup/restore، lock، notifications، widget، media، store build |

## ما تم إنجازه فعليًا

### التطبيق والميزات

يحتوي `lib/` على وحدات كاملة لـ:

- Journal وEditor وSearch وTags وCalendar.
- Garden وSeed selection وSound Garden.
- Stats وHeatmap وWeather وAdvanced analytics.
- Breathing وSessions وSession runner.
- Gratitude وWorry وSilent Companion وMotivation.
- Personal: Letters وEchoes وWeekly Pulse وSage.
- Settings وBilling وPaywall وLock.
- Backup، database migration، encryption، privacy، local AI، notifications، audio، voice.

### الأمن والخصوصية

- `EncryptionService` يطبق AES-256-GCM للنصوص مع nonce وMAC.
- Hive boxes تستخدم `HiveAesCipher` ومفتاحًا محفوظًا في secure storage.
- النسخ الاحتياطية تستخدم envelope مشفرًا مع version/magic header/salt/nonce/MAC.
- توجد حماية لمسارات ZIP وقيود للحجم والعدد والـschema والـduplicate IDs.
- توجد اختبارات للـround-trip، المفتاح الخاطئ، tampering، MAC، وPBKDF2.
- `PrivacyService` يملك مسار Delete All، وقد أضيفت له تغطية key lifecycle أساسية.

### الاختبارات

توجد اختبارات لـ:

- App Lock policy.
- Backup/restore وbackup security.
- Database migration.
- Encryption وPBKDF2.
- Garden.
- Journal models.
- Local AI.
- Mood.
- Privacy.
- R-Personal.
- Personal widgets.
- Basic widget smoke.

السجلات السابقة في `ROADMAP.md` توثق نجاح `flutter analyze` و`flutter test` وdebug/release builds في بيئة Flutter-enabled، لكن Flutter غير مثبت في sandbox الحالي؛ لذلك لم أعد تنفيذ هذه الأوامر محليًا في هذا التدقيق، ولا أستبدل السجل التاريخي بإثبات جديد.

### إدارة قاعدة البيانات والنسخ الاحتياطي

تمت إضافة:

- `Backup Database` لحفظ نسخة `.nabd` مشفرة بكلمة مرور.
- `Restore Database` مع `Merge` و`Replace` وتأكيد قبل الاستبدال.
- `Default Backup Folder`.
- `Automatic Database Backup` يومي أو أسبوعي عبر WorkManager.
- كلمة مرور النسخ التلقائي محفوظة في Secure Storage.
- إشعار Android منفصل للنجاح أو الفشل، وحالة آخر تشغيل داخل Settings.

الاختبارات البرمجية وBuild نجحت، لكن التشغيل الدوري الفعلي على هاتف لم يُثبت بعد؛ Android يحدد التوقيت وقد يؤجل المهمة.

### QA infrastructure

تم تطوير `.github/workflows/android-runtime-qa.yml` ليشمل:

- `workflow_dispatch`.
- API 34 و`google_apis` و`x86_64` وGPU off في آخر commit.
- انتظار `sys.boot_completed=1` و`dev.bootcomplete=1` وADB/input/System UI.
- storage readiness gate لـ`emulated;0` و`/sdcard`.
- diagnostics لـmount، media extractor، providers، volumes، logcat، windows، activity.
- تحقق install وpackage path وPID وlaunch.
- simple Maestro smoke منفصل عن deep UI flow.
- حفظ exit codes وscreenshots وUI hierarchy وartifacts عند الفشل.

## الحواجز الأمنية التي يجب إغلاقها قبل Release Candidate

### 1. Key rotation

المسار الحالي لـ`rotateKey()` لا يكفي كتدوير آمن إذا حذف المفتاح القديم وأنشأ مفتاحًا جديدًا دون إعادة تشفير كل الصناديق بنقل ذري قابل للاسترجاع. المطلوب أحد خيارين:

1. تنفيذ rotation حقيقي: فتح القديم، إنشاء الجديد، إعادة تشفير كل البيانات إلى staging، التحقق، تبديل ذري، recovery marker، ثم حذف القديم بعد نجاح التحقق.
2. إزالة API الحالي وتحويله إلى مسار غير متاح بوضوح بدل الاحتفاظ بسلوك قد يجعل البيانات غير قابلة للقراءة.

### 2. Export Data

Settings ما زال يملك مسار تصدير JSON نصي غير مشفر. يجب توحيده مع encrypted backup، أو إبقاؤه كتصدير نصي مع تحذير أمني صريح وتأكيد من المستخدم.

### 3. Entitlements داخل النسخ

يجب حذف `is_pro` و`is_lifetime` و`pro_expiry` من payload عند إنشاء النسخة، وليس الاعتماد فقط على فلترة restore.

### 4. Migration وdata lifecycle

يلزم runtime/integration verification لـ:

- plaintext إلى encrypted migration.
- انقطاع migration واستئنافه.
- wrong key وmissing key.
- backup/restore بكلمة صحيحة وخاطئة.
- MAC corruption.
- Delete All ثم إعادة تشغيل التطبيق.
- key lifecycle بعد الحذف وإعادة الاستخدام.

## Runtime وApp Lock

ما ثبت سابقًا:

- Emulator API 35 أقلع في Run `35658063511`.
- `sys.boot_completed=1` وADB `device` تحققَا.
- APK install نجح.
- `com.nabd.journal` أُطلق وظهر PID.
- System UI فشل بسبب timeout في emulated FUSE storage وcontent providers.
- لم يثبت Maestro في ذلك Run.

ما ثبت الآن على هاتف فعلي:

- بعد إغلاق وفتح التطبيق ظهرت شاشة `Journal Locked`.
- بعد إصلاح `MainActivity` إلى `FlutterFragmentActivity` ظهرت نافذة المصادقة ونجحت البصمة وفتح التطبيق.

ما لم يثبت بعد:

- cold start lock.
- background/hidden/paused/resumed lifecycle على جهاز.
- biometric success/failure.
- timeout lock.
- navigation إلى/من lock دون loop.
- App Lock-specific Maestro flow.
- R-Settings & Lock production readiness.
- Automatic Database Backup execution and success/failure notification on a physical phone.

Run الإصلاح `35713141865` على SHA `cd47f6d` شُغّل للتحقق الآلي من الإصلاح؛ اختبار الهاتف الفعلي هو الدليل الحالي لنجاح App Lock الأساسي.

## Release readiness

### Android

الموجود:

- `applicationId = com.nabd.journal`.
- namespace صحيح.
- `minSdk = 23`.
- signingConfig مشروط بوجود `key.properties`.
- assets وstore screenshots موجودة.

غير المغلق:

- لا يوجد دليل أن production keystore وsecrets شُغّلا في Release CI الحالي.
- لا يوجد Release AAB موثق من آخر commit في هذا التدقيق.
- يجب التحقق من ProGuard/R8، versioning، Play signing، وrelease manifest.

### iOS

يوجد `ios/Runner/Info.plist` فقط ضمن الهيكل المفحوص؛ لا توجد أدلة كافية هنا على اكتمال Xcode workspace/Podfile/entitlements/build. iOS ليس جاهزًا للإطلاق بناءً على هذا التدقيق.

### AdMob

المشروع يحتوي Test IDs وآلية dart-define للـRewarded IDs، لكن production App IDs في native Manifest/Info.plist وAd Units الحقيقية تحتاج إعدادًا خارجيًا واختبار جهاز حقيقي.

### IAP

- Lifetime يمكن تفعيله من purchase callback.
- Monthly/Yearly مصنفان subscription غير متحققين server-side.
- لا توجد أدلة شراء sandbox/restore/failure من متجر حقيقي.

### App Links

توجد intent filters لـ`nabd.app` في المصدر المادي، لكن لا يوجد إثبات domain verification فعلي أو `assetlinks.json` ببصمة release certificate.

### Store

الأصول الأساسية موجودة: app icon، splash، 6 screenshots، feature graphic، وملفات صوت كثيرة. لكن checklist المتجر ما زالت تحتوي بنودًا مفتوحة: الحسابات، المنتجات، privacy/data safety، content rating، signing، testing tracks، وsubmission.

## خارطة الطريق التنفيذية الكبرى

### المرحلة 0 — إغلاق وحصر الحالة

**الحالة:** App Lock الأساسي وإدارة النسخ البرمجية مثبتان، مع Runtime ميداني مطلوب.
**المخرج المطلوب:** تشغيل Backup/Restore والجدولة والإشعارات وDelete All وmigration على الهاتف.

### المرحلة 1 — Security closure

**الأولوية:** حرجة.  
**المهام:** key rotation أو إزالة API، تصحيح export، حذف entitlement عند الإنشاء، migration recovery، key lifecycle.  
**شرط الخروج:** اختبارات منطقية وتكاملية/runtime موثقة.

**الخطوة التالية المباشرة:** تثبيت APK الأخير على الهاتف، تنفيذ Backup/Restore ثم تفعيل الجدولة والتحقق من ملف `.nabd` وإشعار النجاح أو الفشل.

### المرحلة 2 — Runtime matrix

**الأولوية:** حرجة.  
**المهام:** Android API 34/35 أو جهاز حقيقي، install/launch، App Lock lifecycle، backup/restore، migration، delete-all، notifications، widget، media، Arabic/RTL، dark mode.  
**شرط الخروج:** لا يوجد سيناريو معلن دون تنفيذ فعلي؛ artifacts لكل flow.

### المرحلة 3 — Monetization وprivacy production setup

**الأولوية:** عالية قبل النشر المدفوع.  
**المهام:** Play/App Store products، subscription entitlement verification، restore/failure، AdMob production IDs، privacy consent/metadata.  
**شرط الخروج:** sandbox purchase evidence وrelease configuration review.

### المرحلة 4 — Release engineering

**الأولوية:** عالية.  
**المهام:** production keystore، signed AAB، versioning، R8/ProGuard، App Links/assetlinks، Android/iOS build validation.  
**شرط الخروج:** signed artifacts وinstall/upgrade verification.

### المرحلة 5 — R-Polish

**الأولوية:** متوسطة بعد Security.  
**المهام:** توحيد i18n facade، إزالة النصوص الإنجليزية الثابتة، RTL، contrast، أحجام الشاشات، App Icon، Silent audio polish، water-drop/echo.  
**شرط الخروج:** visual review وlocalized screenshots.

### المرحلة 6 — Store submission وpost-launch readiness

**الأولوية:** أخيرة.  
**المهام:** Play/App Store metadata، privacy policy، Data Safety، ratings، internal/closed testing، crash monitoring مع احترام الخصوصية، ASO وsupport process.  
**شرط الخروج:** قبول internal testing ثم قرار production.

## تعريف «انتهاء المشروع»

لا يُعتبر المشروع منتهيًا عند وجود الشاشات أو نجاح Debug APK فقط. الإغلاق الكامل يتطلب:

1. Security closure بلا key-loss path.
2. Runtime App Lock وbackup/restore/migration مثبتة فعليًا.
3. Signed release AAB/IPA قابلة للتثبيت.
4. Monetization وAdMob production configuration مثبتة أو معطلة بقرار منتج واضح.
5. App Links وpermissions وprivacy/store forms مكتملة.
6. Final QA matrix ناجحة مع artifacts.
7. لا توجد ديون حرجة معروفة في `ROADMAP.md` أو `PRE_LAUNCH_CHECKLIST.md`.

**الخلاصة:** نبض قريب من تطبيق وظيفي واسع النطاق، لكنه ما زال في مرحلة **Feature-complete / Security-and-release-hardening**، وليس في مرحلة **Production-ready**.
