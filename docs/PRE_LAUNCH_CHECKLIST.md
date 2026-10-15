# قائمة التحقق قبل الإطلاق — Pulse

## 1. الأصول (Assets)

- [ ] `assets/icons/app_icon.png` موجود (1024×1024)
- [ ] `assets/icons/app_icon_fg.png` موجود (1024×1024)
- [ ] `assets/icons/splash.png` موجود (800×800)
- [ ] `flutter test test/splash_sound_test.dart` ينجح (الأصوات المعلنة = الموجودة)
- [x] `assets/store/output/*.png` = 12 صورة (6 عربي + 6 إنجليزي، 1080×1920) من الشاشات الحقيقية: `flutter test tool/screenshots_test.dart --dart-define=STORE=true`
- [ ] `docs/SOUNDS_ATTRIBUTION.md` محدّث
- [ ] `flutter_launcher_icons` نُفِّذ بنجاح
- [ ] `flutter_native_splash:create` نُفِّذ بنجاح

## 3. IAP (In-App Purchase)

- [ ] إنشاء حساب Google Play Console
- [ ] (لاحقًا، بعد خادم التحقق) إنشاء `nabd_pro_monthly` و`nabd_pro_yearly`
- [ ] إنشاء منتج `nabd_lifetime` غير استهلاكي (59.99$) في One-time products
- [ ] إنشاء حساب App Store Connect
- [ ] تكرار المنتجات في App Store
- [ ] اختبار الشراء بـ Sandbox
- [ ] اختبار الاستعادة
- [ ] اختبار فشل الدفع

## 4. Flutter

- [ ] Flutter 3.47.6 مثبت (CI يستعمله تلقائيًا)
- [ ] Dart 3.6.0 مثبت
- [ ] `flutter pub get` نجح
- [ ] `flutter analyze` = 0 errors
- [ ] `flutter test` = كل الاختبارات تنجح
- [ ] `flutter build apk --debug` نجح
- [ ] `flutter build appbundle --release` نجح

## 5. الأمان

- [ ] AES-256-GCM يعمل (اختبار round-trip)
- [ ] اختبار tampering يفشل (MAC يعمل)
- [ ] اختبار PBKDF2 ينجح
- [ ] لا توجد Server Keys في الكود
- [ ] لا توجد Firebase
- [ ] لا توجد Google Analytics
- [ ] `flutter_secure_storage` يعمل
- [ ] Local Authentication يعمل

## 6. Android

- [ ] `AndroidManifest.xml` مكتمل
- [ ] `applicationId = "com.nabd.journal"`
- [ ] `namespace = "com.nabd.journal"`
- [ ] `minSdk = 23` (يتطلبه record_android)
- [ ] `targetSdk` يطابق قيمة Flutter SDK الحالية
- [ ] `proguard-rules.pro` موجود
- [ ] `signingConfig` مضبوط
- [ ] `keystore` منشأ ومحفوظ بأمان

## 7. iOS

- [ ] `Info.plist` مكتمل
- [ ] ضبط `PRODUCT_BUNDLE_IDENTIFIER` الفعلي في مشروع iOS قبل نشر iOS
- [ ] `InfoPlist.strings` للغات المختلفة
- [ ] `Runner.entitlements` موجود
- [ ] `Podfile` محدّث

## 8. متجر Google Play

- [ ] عنوان التطبيق: "Pulse — Private Journal"
- [ ] الوصف القصير (< 80 حرف)
- [ ] الوصف الكامل (< 4000 حرف)
- [ ] 6 صور (1080×1920)
- [ ] Feature Graphic (1024×500)
- [ ] أيقونة (512×512)
- [ ] Data Safety Form: لا جمع ولا مشاركة بيانات (لا إعلانات ولا تحليلات)
- [ ] Content Rating (3+)
- [ ] Privacy Policy URL
- [ ] Internal Testing → Closed → Open → Production

## 9. App Store

- [ ] عنوان التطبيق
- [ ] Subtitle
- [ ] Description
- [ ] Keywords
- [ ] Screenshots لكل حجم
- [ ] App Preview (video)
- [ ] Privacy Nutrition Label
- [ ] TestFlight → Review → Production

## 10. ما بعد الإطلاق

- [ ] Firebase Crashlytics (اختياري، مع احترام الخصوصية)
- [ ] مراقبة Firebase Performance
- [ ] ASO optimization
- [ ] محتوى TikTok/Instagram
- [ ] حملة Product Hunt
- [ ] مراقبة المراجعات يوميًا

---

## 🚨 علامات تحذير

| العلامة | الإجراء |
| :--- | :--- |
| "YOUR_ORG" في الكود | استبدلها |
| `flutter analyze` فيه errors | أصلحها قبل البناء |
| APK > 100 MB | راجع الحجم |
| Crashes في Internal Testing | أصلح قبل Closed |
| Refund Rate > 5% | راجع الاستراتيجية |
