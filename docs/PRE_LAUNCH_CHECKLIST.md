# قائمة التحقق قبل الإطلاق — Pulse

## 1. الأصول (Assets)

- [ ] `assets/icons/app_icon.png` موجود (1024×1024)
- [ ] `assets/icons/app_icon_fg.png` موجود (1024×1024)
- [ ] `assets/icons/splash.png` موجود (800×800)
- [ ] `assets/sounds/*.mp3` = 18 ملفات (>5KB لكل)
- [ ] `assets/store/output/*.png` = 6 صور (1080×1920)
- [ ] `docs/SOUNDS_ATTRIBUTION.md` محدّث
- [ ] `flutter_launcher_icons` نُفِّذ بنجاح
- [ ] `flutter_native_splash:create` نُفِّذ بنجاح

## 2. AdMob

### Test IDs (للتطوير)
- [x] Android Test App ID: `ca-app-pub-3940256099942544~3347511713`
- [x] iOS Test App ID: `ca-app-pub-3940256099942544~1458002511`
- [x] Rewarded Test IDs في `AdMobConfig`

### Production IDs (قبل النشر)
- [ ] إنشاء حساب AdMob
- [ ] إنشاء تطبيق Android في AdMob
- [ ] إنشاء تطبيق iOS في AdMob
- [ ] نسخ **Android App ID** الإنتاجي
- [ ] نسخ **iOS App ID** الإنتاجي
- [ ] إنشاء **Rewarded Ad Unit** لـ Android
- [ ] إنشاء **Rewarded Ad Unit** لـ iOS
- [ ] استبدال App ID في `android/app/src/main/AndroidManifest.xml`
- [ ] استبدال App ID في `ios/Runner/Info.plist`
- [ ] بناء APK بـ `--dart-define=ADMOB_ANDROID_REWARDED_ID=...`
- [ ] بناء IPA بـ `--dart-define=ADMOB_IOS_REWARDED_ID=...`
- [ ] اختبار الإعلان على جهاز حقيقي

## 3. IAP (In-App Purchase)

- [ ] إنشاء حساب Google Play Console
- [ ] إنشاء منتج `nabd_pro_monthly` (4.99$)
- [ ] إنشاء منتج `nabd_pro_yearly` (29.99$)
- [ ] إنشاء منتج `nabd_lifetime` (79.99$)
- [ ] إنشاء حساب App Store Connect
- [ ] تكرار المنتجات في App Store
- [ ] اختبار الشراء بـ Sandbox
- [ ] اختبار الاستعادة
- [ ] اختبار فشل الدفع

## 4. Flutter

- [ ] Flutter 3.27.0 مثبت
- [ ] Dart 3.6.0 مثبت
- [ ] `flutter pub get` نجح
- [ ] `flutter gen-l10n` نجح
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
- [ ] AdMob App ID موجود
- [ ] `applicationId = "com.nabd.journal"`
- [ ] `namespace = "com.nabd.journal"`
- [ ] `minSdk = 23` (يتطلبه record_android)
- [ ] `targetSdk` يطابق قيمة Flutter SDK الحالية
- [ ] `proguard-rules.pro` موجود
- [ ] `signingConfig` مضبوط
- [ ] `keystore` منشأ ومحفوظ بأمان

## 7. iOS

- [ ] `Info.plist` مكتمل
- [ ] AdMob App ID موجود
- [ ] ضبط `PRODUCT_BUNDLE_IDENTIFIER` الفعلي في مشروع iOS قبل نشر iOS
- [ ] `SKAdNetworkItems` موجودة
- [ ] `NSUserTrackingUsageDescription` موجود
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
- [ ] Data Safety Form (None)
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
| AdMob ID يحتوي "XXXX" | استبدله بالإنتاجي |
| `flutter analyze` فيه errors | أصلحها قبل البناء |
| APK > 100 MB | راجع الحجم |
| Crashes في Internal Testing | أصلح قبل Closed |
| Refund Rate > 5% | راجع الاستراتيجية |
