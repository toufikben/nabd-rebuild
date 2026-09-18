# بناء Android تلقائي — Nabd

يوجد workflow في `.github/workflows/android-build.yml`. يعمل عند push إلى `main`، وعند Pull Request إلى `main`، ويمكن تشغيله يدويًا من تبويب Actions.

## ما يعمل دون أسرار

ينشئ workflow بيئة Flutter 3.27 وJava 17، ويستكمل ملفات Android القياسية إذا لم توجد، ثم يشغل `flutter pub get` و`flutter gen-l10n` و`flutter analyze` و`flutter test`. بعد نجاح التحقق، يبني:

- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Debug AAB: `build/app/outputs/bundle/debug/app-debug.aab`

يتم رفع الملفين كـ GitHub Actions Artifacts باسمَي `nabd-debug-apk` و`nabd-debug-aab`. لا يحتاج هذا المسار إلى مفاتيح توقيع أو أسرار AdMob.

## Release لاحقًا

لا ينبغي توقيع Release بمفاتيح داخل المستودع. عند الجاهزية، أضف Secrets التالية إلى GitHub:

| Secret | الغرض |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | keystore مشفر Base64 |
| `KEYSTORE_PASSWORD` | كلمة مرور keystore |
| `KEY_ALIAS` | اسم المفتاح |
| `KEY_PASSWORD` | كلمة مرور المفتاح |
| `ADMOB_ANDROID_REWARDED_ID` | Rewarded Ad Unit للإنتاج |

يجب أيضًا توفير App ID الإنتاجي في Android Manifest عبر خطوة Native/CI منفصلة، لأن `--dart-define` يمرر قيم Dart ولا يعيد كتابة XML تلقائيًا. لا تُرفع ملفات keystore أو `key.properties` إلى Git.

## ملاحظات

بما أن ملفات المنصة الأصلية في هذا المستودع مستخرجة جزئيًا، يحتوي workflow على bootstrap آمن عبر `flutter create --platforms=android --org com.nabd .` عند غياب ملفات إعداد Android. يجب مراجعة الناتج في أول تشغيل فعلي قبل اعتماد Release.
