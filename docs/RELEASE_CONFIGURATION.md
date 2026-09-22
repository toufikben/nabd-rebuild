# إعداد Release للإعلانات والمشتريات

لا تُحفظ معرفات AdMob أو مفاتيح التحقق الخاصة بالمتجر داخل المستودع. معرفات المنتجات ليست أسرارًا، لكنها تُمرر وقت البناء حتى يظل الكود نفسه صالحًا لبيئات Google Play المختلفة.

## Android Release محليًا

```bash
export ADMOB_ANDROID_APP_ID='ca-app-pub-...~...'
export ADMOB_ANDROID_REWARDED_ID='ca-app-pub-.../...'

flutter build appbundle --release \
  --dart-define=ADMOB_ANDROID_APP_ID="$ADMOB_ANDROID_APP_ID" \
  --dart-define=ADMOB_ANDROID_REWARDED_ID="$ADMOB_ANDROID_REWARDED_ID" \
  --dart-define=NABD_PRO_MONTHLY_ID='nabd_pro_monthly' \
  --dart-define=NABD_PRO_YEARLY_ID='nabd_pro_yearly' \
  --dart-define=NABD_LIFETIME_ID='nabd_lifetime' \
  --dart-define=NABD_PRODUCTION_CONFIGURED=true
```

سيوقف Gradle بناء Release إذا لم يكن `ADMOB_ANDROID_APP_ID` موجودًا. وسيوقف التطبيق تحميل Rewarded Ads في Release إذا لم توجد معرفات صحيحة.

## GitHub Actions

أضف القيم التالية إلى GitHub Actions:

| النوع | الاسم | القيمة |
|---|---|---|
| Secret | `ADMOB_ANDROID_APP_ID` | AdMob Android App ID الإنتاجي |
| Secret | `ADMOB_ANDROID_REWARDED_ID` | AdMob Android Rewarded Ad Unit ID الإنتاجي |
| Variable | `NABD_PRO_MONTHLY_ID` | معرف الاشتراك الشهري في Google Play |
| Variable | `NABD_PRO_YEARLY_ID` | معرف الاشتراك السنوي في Google Play |
| Variable | `NABD_LIFETIME_ID` | معرف الشراء الدائم في Google Play |

تُستخدم هذه القيم تلقائيًا في وظيفة Release داخل `.github/workflows/android-build.yml`. لا تضع service account JSON أو مفاتيح Google Play API في هذه المتغيرات أو في التطبيق؛ التحقق من purchase token يحتاج خدمة خادمية منفصلة.

## iOS Release

أضف `ADMOB_IOS_APP_ID` إلى Build Settings أو إلى ملف xcconfig الخاص ببيئة Release، لأن `ios/Runner/Info.plist` يستخدم:

```text
$(ADMOB_IOS_APP_ID)
```

ومعرف Rewarded iOS يمرر إلى Flutter عبر:

```text
--dart-define=ADMOB_IOS_REWARDED_ID=ca-app-pub-.../...
--dart-define=ADMOB_IOS_APP_ID=ca-app-pub-...~...
```

## ملاحظة مهمة عن الاشتراكات

إضافة منتجات Google Play وحدها لا تثبت entitlement. الكود يتعامل مع Lifetime بعد callback المتجر، لكنه لا يمنح Pro للاشتراكات الشهرية والسنوية ما لم تتم إضافة طبقة تحقق موثوقة مثل RevenueCat أو Backend يتحقق من purchase token. هذا مقصود لمنع منح اشتراك مزور أو منتهٍ.

قبل تفعيل الاشتراكات في Release يجب أن يتحقق verifier من:

- product ID وpackage ID.
- purchase state وacknowledgement.
- expiry time والتجديد.
- الإلغاء والاسترداد وgrace period.
- صلاحية trial أو introductory offer.

## فحوص ما قبل النشر

```bash
flutter analyze
flutter test
flutter build appbundle --release ...
```

بعد تثبيت AAB على جهاز اختبار، اختبر شراء Lifetime، استعادة الشراء، ظهور المنتجات، عدم ظهور Test Ads في Release، وتعامل التطبيق مع اشتراك منتهٍ أو مسترد.

**تنبيه:** نجاح بناء Release لا يعني أن entitlement أصبح موثوقًا. يجب اعتبار الاشتراكات الشهرية والسنوية غير مفعلة حتى توصيل verifier.
