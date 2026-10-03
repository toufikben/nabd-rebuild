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
