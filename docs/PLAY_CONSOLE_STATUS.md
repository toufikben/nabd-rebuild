# حالة Play Console — Pulse (تحقق 3 نوفمبر 2026)

الحساب: Toufik Bendjeddah — `7591217685335989001`
التطبيق: `com.nabd.journal` — معرف Play: `4972328674584060809`
الحالة العامة: Internal testing، آخر تحديث للصفحة 1 نوفمبر 2026، «Changes not yet sent for review».

## ✅ متحقق منه (قراءة فقط)

### 1) App content — مكتمل
`App content → Actioned` = **10 إقرارات** كلها محفوظة (Ready to send for review)، آخر تحديث 15 أكتوبر 2026:
- Data safety
- Target audience and content
- Sign in details
- Health apps
- Financial features
- Government apps
- Advertising ID
- Privacy policy
- Content ratings (7 أكتوبر)
- Ads (7 أكتوبر)

لا توجد بنود «Need attention».

### 2) سياسة الخصوصية — منشورة وتعمل
- الرابط المسجّل في Play: `https://toufikben.github.io/privacy-policies/pulse/`
- صفحة حذف البيانات: `https://toufikben.github.io/privacy-policies/pulse/delete-data.html`
- المصدر: مستودع `toufikben/privacy-policies` العام (GitHub Pages مبني بنجاح).
- تحقق HTTP 200 ومحتوى الصفحة يطابق سياسة Pulse.

### 3) المنتجات والأسعار — مضبوطة مسبقاً (لا تُلمس)
| المنتج | ID | النوع | الحالة | السعر |
|---|---|---|---|---|
| Pulse Pro Monthly | `nabd_pro_monthly` | اشتراك، base plan `monthly` | Active، 175 دولة | ‎4.99 USD / 675 DZD |
| Pulse Pro Yearly | `nabd_pro_yearly` | اشتراك، base plan `yearly` | Active، 175 دولة | ‎34.99 USD / 4,700 DZD |
| Pulse Lifetime | `nabd_lifetime` | اشتراك قديم | 0 base plans (غير مستخدم) | — |

- **تصحيح (27 نوفمبر):** متغيّر المستودع `NABD_LIFETIME_ID` كان `nabd.lifetime` (بنقطة) بينما الكود يبيع `nabd_lifetime` (بشرطة سفلية). صُحّح المتغيّر إلى `nabd_lifetime`.
- **لكن التصحيح وحده لا يكفي:** `nabd_lifetime` منتج اشتراك قديم بـ **0 base plans**، فهو غير قابل للشراء أصلًا. لتفعيل بطاقة «مدى الحياة» يجب إنشاء **One-time product** بمعرّف `nabd_lifetime` وتفعيله. حتى ذلك الحين تبقى البطاقة مخفية — وهذا سلوك صحيح لا خطأ.
- قرار المالك (3 نوفمبر): **ترك الأسعار كما هي**، وعدم إدخال 79.99$.
- إصلاح في الكود (3 نوفمبر): شاشة الخطط تعرض الآن فقط ما أعاده المتجر فعلاً. بطاقة «مدى الحياة» لم تعد تظهر بسعر فارغ ونقرة تفشل؛ ستظهر تلقائياً عند إنشاء المنتج وتفعيله. اختبار جديد يغطي الحالتين.
- **تصحيح (27 نوفمبر):** الاشتراكات **مفعّلة** — `REVENUECAT_ANDROID_KEY` مضبوط في متغيّرات المستودع، فـ `subscriptionsEnabled == true`. التقارير السابقة التي قالت إنها مخفية كانت خاطئة.

### 4) صفحة المتجر
- العنوان الإنجليزي: **Pulse: Private Journal** (22/30).
- الوصف القصير الإنجليزي: «Your private journal. 100% local, offline, seed garden & mood weather» (69/80).
- الوصف الكامل الإنجليزي: يبدأ «🌱 Pulse — your private journal» (1389/4000).
- العربية: العنوان الحالي **«Pulse: مذكراتك الخاصة»** (20/30) — يحتاج تصحيحاً إلى **«نبض: مذكراتك الخاصة»**. الوصف العربي يستخدم «نبض» بالفعل.
- اللغات المضافة: en-US (افتراضي)، ar، zh-HK، zh-CN، zh-TW، fr-FR (وغيرها حسب قائمة اللغات).
- الصور: 8 لقطات هاتف + Feature Graphic. (تحديث الصور/الوصف مؤجّل بقرار المالك.)

### 5) الإصدارات
- Internal testing: الإصدار **263 (1.0.2)** منشور ومتاح لمختبري Internal testing، «Not reviewed»، أُطلق 1 نوفمبر.
- مستخدمو Internal testing المحددون: **«Phone Fortress license testers» (1)** و **«www.toufik155@gmail.com» (4)**. القائمتان مختارتان ومحفوظتان.
- Production: غير مفعّل. اختبار مغلق: 1/5 (الدول فقط، لم يُخترْ المستخدمون). اختبار مفتوح: 1/4.
- CI run **41603334340** ناجح. المستودع عاد **خاصًا** فور انتهائه.
- AAB الجديد 265 متاح، لم يُرفع بعد (رفعه يحتاج اختيار ملف يدويًا؛ الرفع الآلي >5 MB غير متاح في المتصفح).
- قائمة المتجر: تم تصحيح **العنوان بالعربية** إلى **«نبض: مذكراتك الخاصة»** وحفظه كمسودة «Your changes have been saved» (قابل للإرسال عند المراجعة).

## ❌ متبقٍ

1. ~~تصحيح عنوان المتجر العربي~~ ✅ تم («نبض: مذكراتك الخاصة»، محفوظة كمسودة).
2. إنشاء one-time product `nabd.lifetime` وتفعيله — مؤجّل بقرار المالك (السعر)، والواجهة لم تعد تعرضه.
3. رفع AAB versionCode **265** إلى Internal testing يدويًا (اختيار الملف في «Create new release»)، ثم الإرسال للمراجعة.
4. ~~ضبط مستخدمي Internal testing~~ ✅ موجودان ومحددان.
5. اختبار شراء/استعادة حقيقي بعد 3 — مسار التحقق: RevenueCat REST بمفتاح `goog_` العام (كما في `docs/REVENUECAT_SETUP.md`)، ويجب كفاية ذلك لمنح Pro.
6. تحديث الوصف/الصور (مؤجّل بطلب المالك).
7. iOS (مؤجّل: لا مشروع Xcode في المستودع).
8. فحوصات الجهاز النهائية: الودجة، تسجيل صوتي حي، استرجاع «استبدال»، a11y، أداء release.
