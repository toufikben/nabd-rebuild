# بناء Android في CI

الملف: `.github/workflows/android-build.yml`. يعمل عند الدفع إلى `main`، وعند Pull Request إلى `main`، ويدويًا.

1. **Analyze and test:** `flutter pub get` ثم `flutter analyze` (أي ملاحظة تُفشل البناء) ثم `flutter test`.
2. **Build debug APK and AAB:** بعد نجاح الخطوة الأولى، APK لكل معالج (`--split-per-abi`). على Pull Requests لا يُرفع شيء. على `main` واليدوي يُرفع `nabd-debug-arm64-apk` لمدة 3 أيام.
3. **Release موقّع:** اختياري عبر `NABD_RELEASE_ENABLED=true`؛ انظر `docs/RELEASE_CONFIGURATION.md`.

### تنزيل نسخة للهاتف

شغّل الـ workflow يدويًا (Actions ← Android Build ← Run workflow واختر الفرع). عند انتهائه تظهر في صفحة **Releases** نسخة تجريبية `build-<رقم>` فيها:

- `nabd-debug-arm64.apk`: للاختبار (تسمح بلقطات adb).
- `nabd-release.apk`: إن كان الإصدار الموقّع مفعّلًا.

تُفتح الصفحة من الهاتف ويُثبَّت الملف مباشرة. ملفات Releases لا تستهلك حصة تخزين Actions، لذلك تعمل حتى حين تمتلئ الحصة؛ فشل رفع Artifacts لا يُفشل البناء. احذف الإصدارات التجريبية القديمة من حين لآخر.

لا تُرفع ملفات keystore أو `key.properties` إلى Git.
