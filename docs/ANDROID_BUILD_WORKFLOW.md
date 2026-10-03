# بناء Android في CI

الملف: `.github/workflows/android-build.yml`. يعمل عند الدفع إلى `main`، وعند Pull Request إلى `main`، ويدويًا.

1. **Analyze and test:** `flutter pub get` ثم `flutter analyze` (أي ملاحظة تُفشل البناء) ثم `flutter test`.
2. **Build debug APK and AAB:** بعد نجاح الخطوة الأولى. على Pull Requests لا تُرفع الملفات (حصة التخزين)؛ على `main` واليدوي تُرفع باسم `nabd-debug-apk` و`nabd-debug-aab` لمدة 7 أيام.
3. **Release موقّع:** اختياري عبر `NABD_RELEASE_ENABLED=true`؛ انظر `docs/RELEASE_CONFIGURATION.md`.

لا تُرفع ملفات keystore أو `key.properties` إلى Git.
