# خارطة طريق نبض — الحالة الموثقة

**آخر تحديث:** 2026-09-29 بعد قفل كلمة السر وإصلاح عيوب التدقيق الثلاثة على الجهاز
**الفرع:** `main`
**آخر commit:** `e5ba5b3` — `fix: reject an impossible gratitude day and assert the limit against entries`
**حالة التنفيذ:** `origin/main` أخضر في CI بـ 154 اختبارًا، وبناء Debug APK/AAB ناجح، والتثبيت على هاتف Realme تم

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
| 8 | R-Settings & Lock | ✅ منفذة | Settings و App Lock موجودان؛ لوحة رمز 4–6 أرقام مع PBKDF2 وبوابة في الإعدادات، ومثبتة باختبارات CI. يبقى التحقق runtime على الجهاز (لا يشغّل CI نافذة مصادقة حيوية) |
| 9 | R-Data & Security | ✅ منفذة (تدوير ذري مطبق) | التدوير يعيد تشفير كل الصناديق مع نسخ احتياطية `.rotating` وتراجع تلقائي عند الفشل؛ يلزم إثباته على جهاز حقيقي |
| 10 | R-Monetization | 🟡 مجهزة جزئيًا | معرفات المنتجات قابلة للحقن، لكن Monthly/Yearly لا تمنح Pro قبل verifier خادمي |
| 11 | R-Polish | 🟡 جارية | i18n للواجهة منتهٍ ✅، RTL يعمل ✅، App Icon ✅، صوت Splash موحّد ✅، تباين الوضع الليلي ✅؛ بقيت جُمل طبقة الخدمات |
| 12 | R-Final QA | 🟡 جارية | CI أخضر بـ 154 اختبارًا ✅ وبناء Debug APK/AAB ✅ والتثبيت على Realme ✅؛ بقيت جولة الشاشات باللقطات، ثم Release signing و App Links |

## R-Launch & Polish — سجل 2026-09-26

| البند | الحالة | التفصيل |
|---|---|---|
| أيقونة التطبيق | ✅ مُصلَحة (جولة ثانية) | `mipmap-*/ic_launcher_foreground.png` كانت 72dp بدل 108dp، فكان المشغّل يصغّرها داخل مساحةAdaptive. أُعيدت على 108dp لكل كثافة مع وضع الشعار داخل منطقة الأمان 66dp، مع adaptive + monochrome وخلفية `#0A0D14` |
| صوت البداية | ✅ توقيع جديد `splash_nabd.wav` | قطرة ماء بصدى مرتين (0.03–0.25ث) ثم نبضتان منخفضتان (0.50 و0.74ث عند 44–74 هرتز) ثم أربيجي جرس A-E-A-C# بذيل حتى 3.0ث، فوق طبقة نَفَس مُرَشَّح. مُولَّف رقميًا بـ Node (44.1kHz · ستيريو · 16-bit · 3.2ث · ذروة 0.62 بلا قصّ) ومُتحقَّق من ترويسة RIFF بحجم صحيح — وهو الخطأ الذي كان يُسقط الملف القديم صامتًا. `splash_drop.wav` بقي كخيار احتياطي في سلسلة المرشحين، ومدة البقاء صارت 3.2ث كي لا يُقطع الرنين |
| شاشة قبل Splash | ✅ مُزالة | `main.dart` كان يفتح 5 صناديق Hive مشفّرة قبل `runApp`، فكانت تشاشة بيضاء. الصوت صار `unawaited` مع `timeout` 4 ثوانٍ، والتنقل في مسار مستقل `_routeAway` لا يُحجب أبدًا بالصوت |
| تباين الوضع الليلي | ✅ مُصلَح | `AppColors.text*/surface/background/border` صارت getters حساسة للسطوع، و`NabdApp` يزامن `AppColors.brightness` مع السمة |
| اختيار مكان حفظ النسخة | ✅ مضاف ومُصلَح | Settings → Export Data يختار المسار عبر `FilePicker.saveFile` بدل المشاركة إلى مجلد مؤقت. على أندرويد/iOS يجب تمرير `bytes:` وإلا يفشل بـ `Invalid argument: bytes are required on Android and iOS`، فصارت البايتات تُقرأ قبل النداء |
| استرجع مع Merge/Replace | ✅ مضاف | حوار اختيار الوضع؛ `RestoreMode.merge` يحافظ على الحالي، و`replace` يستبدل |
| رسالة نجاح/فشل صريحة | ✅ مضافة | SnackBar بعدد عدد المدخلات والصور والصوت، وسبب الفشل عند الرفض |
| تحديث الواجهة بعد الاسترجاع | ✅ مضاف | `dataRevisionProvider`؛ Home/Stats/Weather/Search/Garden/Calendar تعيد القراءة فورًا بلا إعادة تشغيل |
| i18n | ✅ مكتمل للواجهة | الشاشات كلها تمر عبر `app_strings.dart` (486 مفتاحًا)؛ المتبقي جُمل داخل طبقة الخدمات وبعض التلميحات |

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

يبقى تأجيل أخطاء Journal الصغيرة مقبولًا. يبقى Splash sound الحالي. يؤجل Silent rain/storm الجديد إلى R-Polish.

## ملفات لا تُدفع أبدًا (حيل بناء محلية)

ستة ملفات معدّلة محليًا ومقصورة على جهاز التطوير، ولا يجوز رفعها إلى `origin/main` لأنها تُغيّر إصدارات الأدوات التي يبني بها CI:
`pubspec.yaml`، `pubspec.lock`، `analysis_options.yaml`، `android/gradle.properties`، `android/gradle/wrapper/gradle-wrapper.properties`، `android/app/build.gradle`.
كذلك المجلدات والملفات المولّدة غير المتتبَّعة (`lib/l10n/generated/`، `ios/Flutter/`، `apk-out/`، `flutter_01.log`، `l10n_untranslated.txt`) تبقى خارج الـ commit.

## شروط إغلاق Security

لا تُغلق R-Data & Security قبل تنفيذ تدوير مفتاح ذري يحافظ على البيانات أو اعتماد قرار إبقاء API معطلًا، ثم اختبار migration وbackup/restore وdelete-all وkey lifecycle على جهاز أو emulator. التصدير أصبح مشفرًا وفلترة entitlement عند الإنشاء مطبقة، لكن ذلك لا يغني عن تحقق runtime.

## التحقق الأخير

سياسة ثابتة منذ 2026-09-29: **GitHub Actions هو المتحقّق الوحيد**. لا يُشغَّل `flutter analyze` ولا `flutter test` محليًا لأن جهاز التطوير (معالجان، 4 غيغابايت RAM، قرص HDD) لا يحتمل البناء، فأي نتيجة محلية تعتبر غير موثوقة.

| التحقق | الحالة | الدليل |
|---|---|---|
| `flutter analyze` | ✅ نظيف | `No issues found! (ran in 18.1s)` في التشغيل `36541628570` |
| `flutter test` | ✅ 154 اختبارًا | `🎉 154 tests passed.` في نفس التشغيل |
| بناء Debug APK/AAB | ✅ ناجح | الـ artifact باسم `nabd-debug-apk` (23,403,627 بايت) حُمِّل وثُبِّت على الهاتف |
| بناء Release الموقّع | ⏳ `skipped` بشكل مقصود | أسرار ومتغيرات التوقيع غير موجودة في المستودع، ولا يُسمح بإضافتها من هنا |
| اختبار الهاتف | 🟡 بدأ | التطبيق مثبَّت على Realme RMX3910 (`IR7X5DJ7KZGEHMS8`, Android 16)؛ جولة الشاشات باللقطات لم تُوثَّق بعد |
| AdMob Android | ✅ جاهز | بعد إضافة `ADMOB_ANDROID_APP_ID` و `ADMOB_ANDROID_REWARDED_ID` |
| Google Play products | 🟡 جاهزة للحقن فقط | عبر `NABD_PRO_MONTHLY_ID` و `NABD_PRO_YEARLY_ID` و `NABD_LIFETIME_ID`، لكن verifier الاشتراكات غير موجود |

## R-Final QA — سجل 2026-09-29

### قفل التطبيق برمز سري

| البند | التفصيل |
|---|---|
| التخزين | الرمز نفسه لا يُحفظ أبدًا: `salt` عشوائي 16 بايت و PBKDF2 digest لـ `pin + salt` تحت مفتاحي `nabd_passcode_salt` و `nabd_passcode_hash` في `FlutterSecureStorage` (keystore نظام التشغيل، `encryptedSharedPreferences: true`)، لا في صناديق Hive (commit `cd0b4fa`) |
| اللوحة | `PasscodePad` في `lib/features/lock/passcode_pad.dart` — أرقام 0–9 بمفاتيح `ValueKey<int>`، زر `backspace`، وزر `submit` (`ValueKey('submit')`) يبقى `onPressed == null` حتى يبلغ الإدخال `minLength` |
| الطول | من 4 إلى 6 أرقام (`PasscodeService.minLength` / `maxLength`)، وأرقام فقط وإلا `PasscodeFormatException` (commit `1cfc08a`) |
| العرض | نقاط `_PasscodeDots` بعدد `maxLength` لا تُظهر الرقم، فلا يُقرأ من فوق الكتف |
| النسيان | زر `forgot` يظهر فقط عند تمرير `onForgotTap`، ويطلب بيانات اعتماد الجهاز للسماح باختيار رمز جديد؛ لا يوجد مسار إعادة تعيين عبر الخادم |
| الحماية من التخمين | `PasscodeAttempts`: خمس محاولات فاشلة تُقفل اللوحة 30 ثانية، والأزرار تتعطّل والعدّاد يظهر في `lock.pin.cooldown` |
| البوابة | التفعيل والإزالة من `passcode_setup_sheet.dart` داخل شاشة الإعدادات؛ تفعيل القفل صار يتطلب رمزًا، وهذا يسدّ الفخّ الذي كان يقفل الجهاز نهائيًا إذا لم تكن هناك بصمة مسجّلة |
| المظهر | `dark: true` لشاشة القفل على التدرّج الداكن، و `dark: false` لورقة الإعدادات الفاتحة |
| الاختبارات | `test/passcode_pad_test.dart` — سبع حالات Widget، وكلها تحتاج `await tester.pump()` بعد `pumpWidget` لأن `AppLocalizations.delegate` يستغرق إطارًا ليُحلّ وإلا وجدت كل الـ finders شجرة فارغة (commit `ee51f7f`) |
| CI | التشغيل `36538021011` أخضر بـ 134 اختبارًا |
| غير مثبت | نافذة المصادقة الحيوية نفسها: لا يملك أي CI runner بصمة، فتحتاج جولة الهاتف |

### ثلاثة عيوب من تدقيق الجهاز — صُحّحت

| العيب | الإصلاح | commits |
|---|---|---|
| الأحلام كانت تُحسب كمدخلات يوميات (العدد، البحث، الكلمات، توزيع المزاج، streak، وحصّة الشهر المجاني) | حقل `isDream` على `JournalEntry` مع تمريره عبر `toMap`/`fromMap`/`copyWith`، ثم `getAllEntries()` و `getEntryCount()` يستبعدانها في `database_service.dart`. خدمة النسخ لم تُمسّ فتبقى الأحلام تُصدَّر | `59a3228` → `a306e4d` |
| 5 من 8 جلسات تنفّس مقفلة دائمًا للأبد | حُذف `const bool _hasPremium = false` وصار القرار `sessionIsLocked(isFree:, isPro:)` يقرأ `monetizationProvider`، والمحرّك يبدأ بعد إطار الاستحقاق | `a306e4d` |
| شاشة الإنجازات لا تفتح شيئًا أبدًا ولا تعدّ الامتنان | `AchievementsScreen` صار `ConsumerStatefulWidget` يستدعي `unlockEligible(...)` في `addPostFrameCallback`، و`gratitudeDayCount()` يعدّ الأيام الصحيحة ويتجاهل مفاتيح الحديقة | `a306e4d` |

فخّان واجها الدفعة:
1. `DateTime.parse` متساهل: `'2026-9-31'` ينتقل إلى أكتوبر، فصار كل مفتاح تحقَّق من أجزائه مقابل التاريخ الذي يبنيه (commit `e5ba5b3`).
2. `flutter test` يفصل كل ملف اختبار، ففشل ملف واحد لا يمنع بقية الملفات من النجاح — لذلك كان الرقم 152/2 طبيعيًا في التشغيل الأحمر.

أدلة RED ثم GREEN: `36540351838` (137 نجحت / 17 فشلت كما هو مقصود) ← `36540932035` (152/2) ← `36541628570` (154 نجحت، التحليل نظيف، APK و AAB مبنيان).

## الترتيب التنفيذي بعد التدقيق

1. ~~تشغيل CI بعد Hotfix وتصحيح أي أخطاء تحليل أو اختبار~~ ✅ منتهٍ (154 اختبارًا).
2. جولة الهاتف الحالية بالترتيب: شاشة القفل واللوحة ونسيان الرمز والانتظار 30 ثانية وبوابة الإعدادات ← الأحلام (تختفي من العدد والبحث) ← الجلسات المجانية ← الإنجازات ← التصدير المشفر و Delete All ← جولة عربية + إنجليزية باللقطات.
3. إضافة verifier موثوق للاشتراكات الشهرية والسنوية قبل منح Pro.
4. تشغيل Release مع متغيرات AdMob و Google Play والتحقق من عدم استخدام Test IDs (يتطلب أسرار من صاحب الحساب).
5. نشر `assetlinks.json` ببصمة Release واختبار App Links.
6. مرحلة تحسين الهيكل وإزالة التكرار (مؤجّلة غير ملغاة): قائمة 21 → 5، `push` ← `go` في overflow الشاشة الرئيسية، حذف `/gratitude` المكرر، `sage` → `motivation`، ودمج الرسائل (لا يحتاج هجرة بيانات).
7. مراجعة المتجر والخصوصية.

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

## i18n — الحالة بعد 2026-09-28

| البند | الحالة | التفصيل |
|---|---|---|
| جدول النصوص المركزي | ✅ | `lib/core/l10n/app_strings.dart` يحمل 520 مفتاحًا لكل لغة |
| لغات معلنة | ✅ | `ar` و `en` فقط. كانت 16 لغة تُعلن بلا ترجمة، والـ fallback للإنجليزية |
| تغطية الشاشات | ✅ | كل شاشات `lib/features` و`lib/widgets` تمر عبر `AppLocalizations.of(context).t(...)` |
| اختبار التكافؤ | ✅ | `test/i18n_test.dart` يفشل البناء عند نقص مفتاح في أي لغة أو قيمة فارغة |
| اختبار نظافة المصدر | ✅ | `test/i18n_source_hygiene_test.dart` يمنع `const` حول استدعاء المترجم، أو استدعاء بلا استيراد، أو BOM |
| التواريخ والتقويم | ✅ | `initializeDateFormatting('ar')` في `main()`، و`locale` يمر لـ `TableCalendar` وبطاقات المدخل |
| نصوص طبقة الخدمات | ✅ | رسائل سقي الحديقة صارت مفاتيح (`garden.water.*`) تُترجم عند العرض؛ و`AIPattern` في `local_ai_service` غير مستهلك من أي شاشة |
| أسماء الوسوم الافتراضية | ✅ | الوسوم المُزرّعة تُخزَّن بأسمائها اللاتينية (لأنها قيمة تصفية)، والعرض يمر عبر `localizedTagName` في `lib/models/tag.dart` |
| متبقٍ | ⏳ | رأس ملف التصدير في `legacy_journal_screen` (تنسيق ملف لا واجهة)، ونص إقلاع `StorageFailureApp` لأنه يُرسم قبل تهيئة اللغات |

### أخطاء صُحّحت أثناء التنفيذ

| الخطأ | السبب |
|---|---|
| مفاتيح تظهر كنصوص خام على الشاشة | `AppLocalizations.t` يعيد المفتاح نفسه عند غيابه؛ `dialog.delete.action` استُعمل دون أن يُعرَّف |
| `const` حول استدعاء المترجم | استدعاء دالة ليس تعبيرًا ثابتًا؛ أُزيل `const` من أكثر من 40 موضعًا |
| حقول `titleAr` داخل النماذج | Challenges وSeeds وAchievements كانت تحمل العربية داخل النموذج بدل الجدول؛ صارت `nameFor` و`descriptionFor` |
| تعطّل عند الإلغاء في المحرر | `TextEditingController` كان يُتلف في `finally` قبل اكتمال تفكيك الحوار؛ نُقلت الحيازة إلى `_AddTagDialog` |
| تاريخ إنجليزي داخل الواجهة العربية | `DateFormat` و`TableCalendar` بلا `initializeDateFormatting('ar')` |
| بطاقات الأصوات بالإنجليزية | `SoundTrack.name` نص حرفي داخل الشاشة؛ صار `nameKey` يمر عبر الجدول |
| ثلاثة قيم إنجليزية داخل خريطة التحديات العربية | نُقلت القيم الإنجليزية إلى `S.ar` بالخطأ أثناء التوليد |
| وسوم افتراضية بالإنجليزية في `/search` و`/tags` و`/editor` | `Tag.defaultTags` تُخزَّن كما تُصفّى؛ أُضيف `tryT` + `localizedTagName` للعرض فقط |
| تراكب النصوص في `/garden` و`/seed-selection` و`/future-letters` و`/unsent-letters` وحوار تدوير المفتاح | جُمل نصية مكتوبة مباشرة داخل الشاشات بدل الجدول |