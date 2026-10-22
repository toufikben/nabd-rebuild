# سياسة الخصوصية — نبض

**آخر تحديث:** 2026-10-06

نبض يوميات خاصة. صُمّم كي لا يغادر ما تكتبه هاتفك.

## ما الذي يجمعه نبض؟

لا شيء مما تكتبه أو تسجّله. نبض لا يملك حسابات، ولا يحتوي على أدوات تحليلات أو إعلانات أو تتبّع. الاستثناء الوحيد هو التحقق من الاشتراك إن اشتركت (انظر «خدمات خارجية»).

## أين تُحفظ بياناتك؟

- كل اليوميات والرسائل والمزاج والحديقة والإعدادات تُحفظ في هاتفك فقط، مشفّرة بـ AES-256.
- الصور والتسجيلات الصوتية التي تضيفها تُشفَّر بـ AES-256-GCM قبل حفظها.
- مفتاح التشفير محفوظ في مخزن المفاتيح الآمن في النظام (Android Keystore).
- النسخ الاحتياطي السحابي التلقائي في أندرويد معطّل عمدًا لبيانات نبض. النسخة الاحتياطية الوحيدة هي ملف `.nabd` تصدّره أنت بنفسك وتحميه بكلمة سرّ تختارها، وتقرّر أنت أين تضعه.

## الأذونات ولماذا

| الإذن | السبب |
|---|---|
| الميكروفون | تسجيل ملاحظة صوتية أو الإملاء، فقط حين تضغط الزر |
| الإشعارات | التذكير اليومي والمراجعة الأسبوعية وفتح رسائل المستقبل؛ كلها مجدولة محليًا |
| البصمة | قفل التطبيق إن فعّلته |
| التشغيل عند الإقلاع | إعادة جدولة تذكيراتك بعد إعادة تشغيل الهاتف |
| الصور | تختار الصور عبر منتقي النظام؛ لا يرى نبض إلا ما تختاره |

## خدمات خارجية

- **الإملاء الصوتي:** يعمل افتراضيًا داخل الهاتف فقط عبر التعرّف على الكلام دون اتصال، فلا يغادر الصوت هاتفك. إن لم تكن حزمة اللغة مثبّتة، يسألك نبض قبل استعمال خدمة الكلام عبر الإنترنت في هاتفك (مثل Google)، التي قد ترسل الصوت إلى خوادم مزوّدها. يمكنك سحب هذه الموافقة من الإعدادات، ولا يحتفظ نبض بالصوت. الميزة اختيارية.
- **الشراء:** يتمّ شراء Pro عبر Google Play، وتخضع عملية الدفع لسياسة Google. لا يرى نبض بيانات الدفع.
- **التحقق من الاشتراك:** إن اشتركت شهريًا أو سنويًا، يُرسل نبض رمز الشراء الذي يعطيه Google ومعرّفًا عشوائيًا يُنشأ على هاتفك إلى خدمة RevenueCat، لتتأكد من Google أن الاشتراك فعّال وحتى متى. لا يُرسل اسمك ولا بريدك ولا أي شيء من يومياتك. شراء «مدى الحياة» لا يمرّ بهذه الخدمة.

## الأطفال

نبض غير موجّه للأطفال دون 13 عامًا ولا يجمع بيانات من أحد.

## الحذف

«حذف كل البيانات» في الإعدادات يمسح كل شيء من الهاتف نهائيًا، وكذلك إلغاء تثبيت التطبيق. لا توجد نسخة لدينا لأننا لا نملك نسخة أصلًا.

## التواصل

للأسئلة: افتح Issue في مستودع المشروع أو راسل المطوّر عبر صفحة التطبيق في Google Play.

---

# Privacy Policy — Nabd

**Last updated:** 2026-10-06

Nabd is a private journal, built so that what you write never leaves your phone.

## What does Nabd collect?

Nothing you write or record. Nabd has no accounts, and contains no analytics, advertising or tracking SDKs. The one exception is checking a subscription, if you subscribe (see "Third-party services").

## Where is your data kept?

- Entries, letters, moods, the garden and settings are stored only on your phone, encrypted with AES-256.
- Photos and voice notes you add are encrypted with AES-256-GCM before they are saved.
- The encryption key lives in the system's secure key store (Android Keystore).
- Android's automatic cloud backup is turned off for Nabd's data on purpose. The only backup is a `.nabd` file that you export yourself, protected by a password you choose, and store wherever you decide.

## Permissions and why

| Permission | Why |
|---|---|
| Microphone | Recording a voice note or dictating, only when you tap the button |
| Notifications | Daily reminder, weekly review and future-letter unlocks, all scheduled on the phone |
| Biometrics | App lock, if you turn it on |
| Run at startup | Re-schedule your reminders after the phone restarts |
| Photos | You pick photos with the system picker; Nabd only sees what you pick |

## Third-party services

- **Dictation** runs on the phone by default, using offline speech recognition, so audio never leaves your phone. If the language's offline pack is not installed, Nabd asks before using your phone's online speech service (such as Google), which may send audio to its provider's servers. You can withdraw that consent in Settings. Nabd keeps no audio. The feature is optional.
- **Purchases** of Pro go through Google Play, under Google's policy. Nabd never sees payment details.
- **Subscription checks:** if you take a monthly or yearly plan, Nabd sends the purchase token Google issues, together with a random id created on your phone, to RevenueCat, which confirms with Google that the subscription is active and until when. Your name, email and anything from your journal are never sent. A lifetime purchase does not use this service.

## Children

Nabd is not directed at children under 13 and collects no data from anyone.

## Deletion

"Delete all data" in Settings permanently erases everything from the phone, as does uninstalling the app. We hold no copy, because we never had one.

## Contact

Open an issue in the project repository, or contact the developer through the app's Google Play page.
