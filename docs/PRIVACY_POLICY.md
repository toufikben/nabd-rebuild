# سياسة الخصوصية — نبض

**آخر تحديث:** 2026-10-04

نبض يوميات خاصة. صُمّم كي لا يغادر ما تكتبه هاتفك.

## ما الذي يجمعه نبض؟

لا شيء. نبض لا يملك خوادم ولا حسابات، ولا يحتوي على أدوات تحليلات أو إعلانات أو تتبّع. لا يُرسل التطبيق أي محتوى تكتبه أو تسجّله إلى أي جهة.

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

- **الإملاء الصوتي:** يستعمل خدمة التعرّف على الكلام في هاتفك (مثل Google). قد ترسل هذه الخدمة الصوت إلى خوادم مزوّدها إن لم تكن حزمة اللغة مثبّتة للعمل دون اتصال. يُنبّهك نبض إلى ذلك قبل أول استعمال، ولا يحتفظ بالصوت. الميزة اختيارية.
- **الشراء:** يتمّ شراء Pro عبر Google Play، وتخضع عملية الدفع لسياسة Google. لا يرى نبض بيانات الدفع.

## الأطفال

نبض غير موجّه للأطفال دون 13 عامًا ولا يجمع بيانات من أحد.

## الحذف

«حذف كل البيانات» في الإعدادات يمسح كل شيء من الهاتف نهائيًا، وكذلك إلغاء تثبيت التطبيق. لا توجد نسخة لدينا لأننا لا نملك نسخة أصلًا.

## التواصل

للأسئلة: افتح Issue في مستودع المشروع أو راسل المطوّر عبر صفحة التطبيق في Google Play.

---

# Privacy Policy — Nabd

**Last updated:** 2026-10-04

Nabd is a private journal, built so that what you write never leaves your phone.

## What does Nabd collect?

Nothing. Nabd has no servers and no accounts, and contains no analytics, advertising or tracking SDKs. The app sends nothing you write or record to anyone.

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

- **Dictation** uses your phone's speech recognition service (such as Google). That service may send audio to its provider's servers unless the language is installed for offline use. Nabd tells you this before the first use and keeps no audio. The feature is optional.
- **Purchases** of Pro go through Google Play, under Google's policy. Nabd never sees payment details.

## Children

Nabd is not directed at children under 13 and collects no data from anyone.

## Deletion

"Delete all data" in Settings permanently erases everything from the phone, as does uninstalling the app. We hold no copy, because we never had one.

## Contact

Open an issue in the project repository, or contact the developer through the app's Google Play page.
