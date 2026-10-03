# إعداد بناء Release

لا يحتوي التطبيق على إعلانات، فلا حاجة لأي معرّف AdMob. معرّفات المنتجات ليست أسرارًا لكنها تُمرَّر وقت البناء.

## Android محليًا

```bash
flutter build appbundle --release \
  --dart-define=NABD_PRO_MONTHLY_ID='nabd_pro_monthly' \
  --dart-define=NABD_PRO_YEARLY_ID='nabd_pro_yearly' \
  --dart-define=NABD_LIFETIME_ID='nabd_lifetime' \
  --dart-define=NABD_PRODUCTION_CONFIGURED=true
# اختياري، يُظهر الاشتراكات:
#  --dart-define=SUBSCRIPTION_VERIFICATION_BACKEND_URL=https://...
```

## GitHub Actions

يُفعَّل بناء Release الموقّع بمتغيّر المستودع `NABD_RELEASE_ENABLED=true`.

| النوع | الاسم | القيمة |
|---|---|---|
| Secret | `ANDROID_KEYSTORE_BASE64` | keystore بترميز Base64 |
| Secret | `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | بيانات التوقيع |
| Variable | `NABD_PRO_MONTHLY_ID`, `NABD_PRO_YEARLY_ID`, `NABD_LIFETIME_ID` | معرّفات Google Play |
| Variable | `SUBSCRIPTION_VERIFICATION_BACKEND_URL` | اختياري |

لا تضع service account JSON أو مفاتيح Google Play API في هذه المتغيرات أو في التطبيق.

## ملفات البناء

ترفع Pull Requests نتيجة البناء فقط دون رفع ملفات APK/AAB (كانت تملأ حصة التخزين). تُرفع الملفات عند الدفع إلى `main` أو التشغيل اليدوي، وتُحذف بعد 7 أيام (Release: 30 يومًا).
