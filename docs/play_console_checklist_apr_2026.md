# Google Play Checklist (April 15, 2026) - Noor AlQuran

تاريخ المراجعة: 2026-04-17

## 1) Contacts Permissions Policy
- الحالة: لا توجد مشكلة.
- السبب: التطبيق لا يطلب صلاحيات جهات الاتصال (`READ_CONTACTS` / `WRITE_CONTACTS` / `GET_ACCOUNTS`).
- الإجراء: لا شيء.

## 2) Account Transfer Policy
- الحالة: لا تخص الكود.
- الإجراء:
  1. إذا أردت نقل ملكية حساب المطور، استخدم فقط `Transfer ownership` من داخل Play Console.
  2. لا تعتمد على أي نقل خارجي غير رسمي.

## 3) Location Permissions Policy (مهم)
- الحالة: تحتاج ضبط إفصاح Play Console.
- الموجود في التطبيق: `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION`.
- الاستخدام داخل التطبيق: القبلة + مواقيت الصلاة.
- الإجراء المطلوب:
  1. في **App Content > Sensitive permissions > Location**:
     - صرّح أن الموقع يستخدم لميزة القبلة والمواقيت.
     - وضّح أن الاستخدام يتم عند الحاجة (وليس جمعًا غير ضروري).
  2. في شاشة الإذن داخل التطبيق:
     - اجعل الرسالة واضحة: "نستخدم الموقع لحساب اتجاه القبلة ومواقيت الصلاة بدقة."
  3. لا تطلب الموقع قبل حاجة المستخدم الفعلية (صفحة القبلة/ضبط المواقيت).

## 4) Foreground Service / Geofencing
- Geofencing:
  - الحالة: لا يوجد Geofencing في التطبيق.
  - الإجراء: لا شيء.

- Foreground Service:
  - الحالة: موجود في المانيفست النهائي بسبب `audio_service` (تشغيل صوت).
  - الإجراء المطلوب في Play Console:
    1. افتح **App Content > Foreground service permissions declaration**.
    2. صرّح نوع الاستخدام: `media playback`.
    3. اكتب وصف واضح:
       - "Foreground service is used to provide user-requested Quran/Adhan audio playback with media controls."
    4. أرفق فيديو قصير يوضح:
       - المستخدم يبدأ تشغيل الصوت بنفسه.
       - إشعار التحكم في الوسائط أثناء التشغيل.
       - توقف الخدمة عند إيقاف الصوت.

## 5) Photo/Video Permissions Clarification
- الحالة: لا توجد صلاحيات صور/فيديو واسعة في المانيفست الرئيسي.
- الإجراء: لا شيء، فقط تأكد أن `Data safety` مطابق (لا تدّعي جمع صور/فيديو إذا غير موجود).

## 6) Age-Restricted / Dating Clarification
- الحالة: غير منطبق.
- الإجراء: لا شيء.

## 7) Health Connect / Health Data Reminder
- الحالة: غير منطبق.
- الإجراء: لا شيء.

## 8) Prediction Markets Pilot
- الحالة: غير منطبق.
- الإجراء: لا شيء.

## 9) News & Magazine Self-Declaration
- الحالة: غالبًا غير منطبق على تطبيق القرآن.
- الإجراء: تأكد فقط أن تصنيف التطبيق ليس News/Magazine.

---

## Template جاهز (يمكن نسخه في Play Console)

### A) Location Permission Declaration
"This app requests location permission only to calculate prayer times accurately and determine Qibla direction. Location is used on-device for user-facing religious features."

### B) Foreground Service (Media Playback) Declaration
"The app uses foreground service for media playback only when the user starts Quran/Adhan audio. The service provides playback controls and stops when playback ends or is stopped by the user."

---

## Pre-Release Sanity Check (قبل الرفع)
1. جرّب شاشة القبلة بدون إذن موقع: تظهر رسالة طلب الإذن بشكل واضح.
2. بعد منح الإذن: القبلة والمواقيت تعمل بشكل صحيح.
3. شغّل تلاوة/أذان يدويًا: يظهر إشعار وسائط أثناء التشغيل.
4. أوقف الصوت: يتوقف إشعار الوسائط/الخدمة.
5. راجع Data Safety بحيث يطابق سلوك التطبيق الحقيقي حرفيًا.

