# تفعيل الاشتراكات عبر RevenueCat

يشتري نبض عبر Google Play مباشرة (مكتبة `in_app_purchase`). RevenueCat يعمل هنا **خادمَ تحقّق فقط**: يرسل التطبيق رمز الشراء إلى RevenueCat عبر REST API، فيسأل RevenueCat خوادم Google ويردّ بحالة الاشتراك وتاريخ انتهائه.

لا توجد مكتبة RevenueCat داخل التطبيق، لذلك يبقى في التطبيق عميل فوترة واحد ولا تتعارض الإصدارات.

- **«مدى الحياة»** يعمل دون RevenueCat.
- **الشهري والسنوي** لا يظهران في شاشة Pro إلا بعد ضبط المفتاح (الخطوة 4).

## 1. Google Play Console: المنتجات

التطبيق ← **Monetize** ← **Products**:

| النوع | المعرّف (Product ID) | ملاحظة |
|---|---|---|
| In-app product | `nabd_lifetime` | شراء لمرة واحدة |
| Subscription | `nabd_pro_monthly` | خطة أساسية (Base plan) تتجدّد كل شهر، مثلًا `monthly` |
| Subscription | `nabd_pro_yearly` | خطة أساسية تتجدّد كل سنة، مثلًا `yearly` |

- فعّل كل منتج بزر **Activate**.
- يُفضَّل تشغيل **الأسعار المحلية** حتى يُعدَّل السعر تلقائيًا حسب كل بلد.

## 2. RevenueCat: المشروع والتطبيق

1. **Projects** ← مشروعك ← **Apps & providers** ← **Add app** ← **Google Play Store**.
2. **Package name:** `com.nabd.journal`
3. **Service account credentials JSON:** بدونه لا يستطيع RevenueCat التحقق من أي شراء. اتبع دليلهم «Creating Play Service Credentials»، وملخّصه:
   1. في Google Cloud: أنشئ Service Account، ثم أنشئ له مفتاح JSON.
   2. في Play Console ← **Users and permissions**: ادعُ بريد الحساب، وامنحه صلاحيات **View financial data** و**Manage orders and subscriptions**.
   3. ارفع ملف JSON إلى RevenueCat.
   - قد يحتاج تفعيله حتى 36 ساعة من جهة Google.

## 3. RevenueCat: الاستحقاق والمنتجات

1. **Product catalog** ← **Entitlements** ← **New**، بالمعرّف `pro` تمامًا.
2. **Products** ← **Import** من Google Play. تظهر الاشتراكات بصيغة `nabd_pro_monthly:monthly`، وهذا طبيعي.
3. اربط **كل** المنتجات بالاستحقاق `pro`: الشهري والسنوي و`nabd_lifetime`.

لا حاجة إلى إعداد Offerings: التطبيق يعرض الأسعار من Google Play مباشرة.

## 4. المفتاح في GitHub

1. RevenueCat ← **Project settings** ← **API keys**: انسخ **مفتاح Google العام** الذي يبدأ بـ `goog_`.
   - المفتاح العام مصمّم ليوضع داخل التطبيق.
   - **لا تستعمل أبدًا** مفتاحًا سريًا يبدأ بـ `sk_`. التطبيق يرفضه احتياطًا.
2. GitHub ← المستودع ← **Settings** ← **Secrets and variables** ← **Actions** ← تبويب **Variables** ← **New repository variable**:
   - الاسم: `REVENUECAT_ANDROID_KEY`
   - القيمة: `goog_...`
3. إن اخترت معرّف استحقاق غير `pro`، أضف متغيّرًا باسم `REVENUECAT_ENTITLEMENT`. الأفضل أن تبقيه `pro`.

يقرأ بناء release المتغيّر تلقائيًا، فتظهر الخطتان الشهرية والسنوية في شاشة Pro.

## 5. التجربة

الشراء لا يعمل إلا لتطبيق **مثبّت من Google Play**:

1. ارفع ملف AAB من صفحة Releases إلى مسار **Internal testing** في Play Console.
2. أضف بريدك في **License testing** حتى لا تُخصم منك أي مبالغ حقيقية.
3. ثبّت التطبيق من رابط الاختبار، ثم اشترك شهريًا. يجب أن:
   - يُفتح Pro فورًا؛
   - تظهر المعاملة في RevenueCat ← **Customers**.
4. ألغِ الاشتراك من Google Play: يبقى Pro حتى تاريخ الانتهاء، ثم يُغلق.
   - في وضع الاختبار يتجدّد الاشتراك الشهري كل 5 دقائق.

## كيف يعمل داخل الكود

- `lib/services/monetization_service.dart`:
  - `RevenueCatConfig` يقرأ المفتاح والاستحقاق.
  - `_postRevenueCatReceipt` يرسل الطلب إلى `POST /v1/receipts`.
  - `revenueCatVerdict` يفسّر الرد. يحسب فترة السماح (grace period)، والاستحقاق المفقود يُعدّ خطأ إعداد لا يسحب Pro.
- معرّف المستخدم عشوائي (`nabd_` + 32 حرفًا)، يُحفظ في مخزن المفاتيح، ولا يرتبط بأي هوية.
- تاريخ الانتهاء الذي يردّه RevenueCat يُخزَّن، فيُغلق Pro وحده عند انقضائه حتى دون اتصال.
- `test/revenuecat_verdict_test.dart` يختبر الحالات: فعّال، منتهٍ، فترة سماح، مدى الحياة، إعداد ناقص.
