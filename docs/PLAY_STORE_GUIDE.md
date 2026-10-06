# أوامر التحضير للمتجر

```bash
flutter clean
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter analyze
flutter test
flutter build appbundle --release --dart-define=NABD_PRODUCTION_CONFIGURED=true ...
```

انظر `docs/RELEASE_CONFIGURATION.md` لمعرّفات المنتجات و`docs/PRE_LAUNCH_CHECKLIST.md` لقائمة التحقق.

## سياسة الخصوصية ونموذج Data Safety

- **رابط السياسة:** Play يطلب رابطًا عامًا. النص الجاهز في `docs/PRIVACY_POLICY.md` (عربي وإنجليزي). أسهل استضافة: انسخه إلى Gist عام أو إلى صفحة GitHub Pages، ثم ضع الرابط في Play Console ← App content ← Privacy policy.
- **Data Safety (أجوبة النموذج):**
  - Does your app collect or share any of the required user data types? **No.**
  - Is all of the user data collected by your app encrypted in transit? لا ينطبق (لا جمع).
  - Do you provide a way for users to request that their data is deleted? **Yes**: «حذف كل البيانات» في الإعدادات وإلغاء التثبيت.
  - الإملاء يمرّ عبر خدمة التعرّف في النظام، لا عبر نبض؛ لا يُعدّ جمعًا من التطبيق، لكنه مذكور في السياسة.
- **مع تفعيل الاشتراكات عبر RevenueCat** (`REVENUECAT_ANDROID_KEY`، انظر `docs/REVENUECAT_SETUP.md`): عند شراء اشتراك يُرسَل رمز الشراء ومعرّف عشوائي إلى RevenueCat للتحقق. أجوبة Data Safety تصبح:
  - Does your app collect or share any of the required user data types? **Yes.**
  - **Financial info → Purchase history**: Collected, **not** shared (RevenueCat معالج بيانات نيابة عنك)، غير اختياري للمشترك، الغرض **App functionality**. مشفّر أثناء النقل: **Yes** (HTTPS).
  - **App info and performance / Device or other IDs**: لا (المعرّف عشوائي يولّده التطبيق، لا معرّف إعلاني ولا معرّف جهاز).
  - لا شيء مما يُكتب في اليوميات يغادر الهاتف.
- **Ads:** لا. **Target audience:** 13+ (أو 18+ إن فضّلت لتطبيق يوميات).
