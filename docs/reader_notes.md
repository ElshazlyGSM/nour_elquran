# ملاحظات المشروع

هذا الملف مرجع سريع لما تم في المشروع، خصوصًا الأجزاء الحساسة التي أخذت وقتًا طويلًا حتى استقرت.
الفكرة هنا: لو شيء باظ لاحقًا، نرجع بسرعة للملف ونعرف:
- ما الذي تم
- في أي ملف
- ولماذا تم بهذا الشكل
- وما المشاكل الصعبة التي ظهرت وكيف اتحلت

## 30. تنظيف الكود (خطة مرحلية)

### المنجز
- تعطيل إضافة "بسم الله الرحمن الرحيم" التلقائية في الأذكار وعرض النص كما هو.
  - الملف: `lib/features/home/adhkar_page.dart`
  - ملاحظة: منطق الإضافة موجود ولكن صار يرجّع `false` دائمًا وسيتم حذفه أثناء تفكيك صفحة الأذكار.
- إضافة خدمة صيغ الصلاة والسلام أونلاين مع كاش محلي وتحديث دوري.
  - ملفات جديدة:
    - `lib/services/salawat_formulas_service.dart`
    - `lib/services/salawat_formulas_config.dart`
    - `assets/salawat_formulas_template.json`
  - تعديل:
    - `lib/features/home/salawat_formulas_page.dart` لاستخدام التحميل الأونلاين مع fallback.

### المتبقي (سيتم تنفيذه خطوة بخطوة)
- تفكيك صفحة الأذكار إلى ملفات أصغر (عرض التبويب، بطاقة الذكر، تبويب ختم القرآن).
- فصل خدمات الإشعارات والتنبيهات في ملفات مستقلة وواضحة.
- تنظيم ملفات القارئ/المصحف وتقسيمها حسب الوظيفة.
- مراجعة التحذيرات وإزالة الكود غير المستخدم.

## 31. تقليل حجم التطبيق (مصحف المدينة خارجي)

### المشكلة
- حجم الـ APK كان مازال كبيرًا (~113MB) رغم نقل صفحات/خطوط مصحف المدينة للتحميل الخارجي.
- تحليل حجم الـ APK أظهر أن:
  - `flutter_assets` كانت ~74MB
  - الجزء الأكبر منها داخل:
    - `assets/flutter_assets/packages/quran_library/assets/fonts/quran_fonts_qfc4/`

### التشخيص
- مجلد `quran_fonts_qfc4` يحتوي خطوط QCF4 المضغوطة (604 ملف).
- هذه الملفات كانت تُضمَّن تلقائيًا داخل الـ APK حتى بعد النقل الخارجي.

### الحل الذي نجح
1) حذف إدراج أصول الخطوط الثقيلة من `vendor/quran_library/pubspec.yaml`:
   - إزالة `assets/`
   - إزالة `assets/fonts/` وقائمة الـ fonts بالكامل
2) حذف مجلد الخطوط فعليًا من:
   - `vendor/quran_library/assets/fonts/quran_fonts_qfc4`
3) إضافة خطوة حذف قسرية قبل دمج الأصول في Release:
   - ملف: `android/app/build.gradle.kts`
   - حذف المجلد داخل:
     - `build/intermediates/flutter/release/flutter_assets/...`
     - `build/intermediates/assets/release/mergeReleaseAssets/...`
4) إعادة بناء بعد `flutter clean`.

### النتيجة
- أحجام الـ split APK أصبحت:
  - arm64: ~47.5MB
  - armv7: ~47.1MB
  - x86_64: ~48.9MB
- تأكدنا أن:
  - `quran_fonts_qfc4` لم تعد داخل الـ APK.

## 32. تعطل إشعارات الأذان/التنبيه/الصلاة بسبب الأصوات في Release

### الأعراض
- لا تصل إشعارات الصلاة والسلام أو التنبيه قبل الصلاة أو الأذان.
- إشعار فتح القفل يصل لكن بدون صوت.
- logcat يعرض:
  - `PlatformException(invalid_sound, The resource shoro2 could not be found...)`
  - `PlatformException(invalid_sound, The resource a2trb could not be found...)`

### السبب
- `res/raw` لم تُضمّن داخل APK بسبب `isShrinkResources = true`
- أصوات الإشعارات (`saly`, `a2trb`, `shoro2`) تُمرَّر ديناميكيًا من Dart، فيتم حذفها أثناء resource shrinking.

### الحل
- في `android/app/build.gradle.kts`:
  - تعطيل `isShrinkResources` في release:
    - `isShrinkResources = false`
- يظل `isMinifyEnabled = true` فعالًا.

### ملاحظة
- ملفات الصوت المطلوبة موجودة محليًا هنا:
  - `android/app/src/main/res/raw/saly.ogg`
  - `android/app/src/main/res/raw/a2trb.ogg`
  - `android/app/src/main/res/raw/shoro2.ogg`

## 33. توقف الإشعارات بسبب حد الـ 500 Alarm

### الأعراض
- إشعارات الصلاة والسلام تتوقف أو لا تُجدول.
- إشعارات الأذان/التنبيه قبل الصلاة لا تُكمل الجدولة.
- logcat يظهر:
  - `Maximum limit of concurrent alarms 500 reached`

### السبب
- Salawat كانت تُجدوِل 480 إشعارًا.
- مع إشعارات الصلاة والتنبيه قبل الصلاة (عدة أيام للأمام) يتم تجاوز حد 500.

### الحل
- تقليل حد إشعارات الصلاة والسلام إلى 400:
  - `SalawatNotificationService._maxScheduledNotifications = 400`
- التعامل مع خطأ حد الـ 500:
  - عند ظهور الخطأ نوقف الجدولة بدل كسر الخدمة.
  - تم في:
    - `lib/features/notifications/salawat/salawat_notification_service.dart`
    - `lib/features/notifications/adhan/prayer_notification_service.dart`

## 1. أوضاع القارئ والمصاحف

### أوضاع المصحف
- المصاحف النصية:
  - `classic`
  - `golden`
  - `tajweed`
  - `night`
  - `nightTajweed`
- مصحف الصفحات:
  - `medinaPages`

### الاسم الظاهر للمستخدم
- تم تغيير الاسم الظاهر من `صفحات المدينة` إلى `مصحف المدينة`
- الملف:
  - `lib/features/reader/reader_page.dart`

### مصدر النص
- المصاحف النصية تعتمد على:
  - `lib/services/alfurqan_quran_source.dart`
- السبب:
  - هذا المصدر أنسب للنص، والتجويد، وتنسيق العرض من المسار القديم

### مصحف المدينة
- ما زال يعتمد على:
  - `quran_library`
- لم يتم استبداله
- تم فقط تحسين التفاعل حوله، مثل:
  - التنقل
  - التحديد أثناء الصوت
  - حفظ التكبير

## 2. تحديد الآية في المصاحف النصية

### كيف تم
- التحديد لا يعتمد على `backgroundColor` للنص
- التحديد يتم عبر:
  - `TextPainter.getBoxesForSelection`
  - ثم دمج الـ boxes المتجاورة
  - ثم رسم التظليل عبر `CustomPaint`

### الملفات الأساسية
- `lib/features/reader/reader_widgets.dart`
- `lib/features/reader/reader_navigation.dart`

### لماذا هذا مهم
- لأن التحديد العادي كان يلتقط أحيانًا جزءًا من الآية السابقة
- أو لا يصل لآخر الآية
- خصوصًا مع:
  - شارات ربع الحزب
  - ووجود `WidgetSpan`

## 3. تحديد الآية في مصحف المدينة أثناء الصوت

### كيف تم
- أثناء تشغيل الصوت في `مصحف المدينة`:
  - نحدد الصفحة المناسبة أولًا
  - ثم نستخدم:
    - `QuranCtrl.instance.jumpToPage(...)`
    - `QuranCtrl.instance.setExternalHighlights(...)`
- وعند الإيقاف:
  - `QuranCtrl.instance.clearExternalHighlights()`

### الملفات
- `lib/features/reader/reader_navigation.dart`
- `lib/features/reader/reader_audio.dart`

### لماذا تم بهذا الشكل
- لأن `مصحف المدينة` ليس نصًا حرًا مثل المصاحف النصية
- بل صفحات مرسومة من مكتبة خارجية

## 4. القراء ونظام الصوت

### النظام الحالي
- يوجد نظامان:
  - قراء قدامى `legacy`
  - قراء `MP3Quran`

### الملفات
- `lib/models/reader_reciter.dart`
- `lib/data/reader_reciters.dart`
- `lib/features/reader/reader_state_persistence.dart`

### القارئ الافتراضي
- القارئ الافتراضي لأول تشغيل صار:
  - `المنشاوي`
- المقصود هنا:
  - المنشاوي من النظام القديم `legacy`
- السبب:
  - لأنه يدعم المسار القديم المستقر، ومعه تنزيل كامل للتلاوة

### إزالة التكرار
- تم حذف نسخة `المنشاوي` من `MP3Quran`
- وتم الإبقاء على:
  - `المنشاوي` القديم فقط

### ترتيب الأسماء
- ترتيب الشيوخ أبجدي
- الأسماء مختصرة قدر الإمكان
- والوصف تحت الاسم:
  - الرواية فقط

## 5. MP3Quran

### لماذا دخلناه
- لإضافة شيوخ أكثر
- خصوصًا الشيوخ المصريين
- مع إمكانية بدء التشغيل من الآية نفسها

### كيف يعمل
- تشغيل السورة من رابط مباشر
- ثم `seek` إلى موضع الآية عبر `Ayat timing`

### الملفات
- `lib/services/mp3quran_recitation_service.dart`
- `lib/features/reader/reader_audio.dart`
- `lib/features/reader/reader_page.dart`

### ملاحظة مهمة
- ليس كل قارئ في `MP3Quran` دقته واحدة
- بعض القراء يبدأ مضبوطًا من الآية
- وبعضهم قد يسبق قليلًا
- لذلك الاعتماد عليه للبدء من الآية يحتاج اختبار كل قارئ عمليًا

## 6. كاش الصوت

### الشيوخ القدامى `legacy`
- الكاش كان موجودًا أصلًا
- الحفظ يتم:
  - آية بآية
- الملفات:
  - `lib/services/recitation_cache_service.dart`
  - `lib/features/reader/reader_audio.dart`

### شيوخ `MP3Quran`
- تمت إضافة كاش منفصل وآمن
- لا يلمس كاش الشيوخ القدامى

### كيف تم
- عند تشغيل سورة لقارئ `MP3Quran`:
  - السورة تعمل من النت أول مرة
  - وفي الخلفية تتحفظ السورة على الجهاز
  - وتتحفظ كذلك توقيتات الآيات
- المرة التالية:
  - لو السورة متحفظة، تعمل من الملف المحلي
  - ولو التوقيتات متحفظة، لا يعاد تحميلها من النت

### الملفات
- `lib/services/recitation_cache_service.dart`
- `lib/services/mp3quran_recitation_service.dart`
- `lib/features/reader/reader_audio.dart`

### حالة التحميل في قائمة القراء
- للشيوخ القدامى:
  - `تحميل جزئي - استكمال`
  - `محمل بالكامل على الجهاز`
- ولشيوخ `MP3Quran`:
  - الحالة صارت تعتمد على عدد السور المتحفّظة محليًا
  - جزئي إذا كان جزء من السور متحفظًا
  - كامل إذا كانت السور كلها متحفّظة

## 7. تغيير الشيخ أثناء التشغيل

### السلوك المطلوب
- إذا كان الصوت شغالًا، والمستخدم اختار شيخًا آخر:
  - ينتقل التشغيل إلى الشيخ الجديد
  - من نفس السورة والآية الحالية

### كيف تم
- عند اختيار الشيخ:
  - نقرأ السورة والآية الحالية
  - نحفظ القارئ الجديد
  - ثم نعيد `playFromVerse(...)`

### ملف أساسي
- `lib/features/reader/reader_dialogs.dart`

## 8. زر الصوت في الشريط السفلي

### المشكلة القديمة
- كان الزر:
  - يتحول إلى تحميل
  - ثم يرجع للحظة إلى مثلث التشغيل
  - ثم يعود لمربع الإيقاف
- هذا كان يعطي إحساسًا بوميض غير مريح

### الوضع الحالي
- أثناء التحضير:
  - يبقى الزر في حالة تحميل/تحضير
- لا يرجع للمثلث إلا إذا فشل التشغيل فعلًا

### النص الحالي
- `قيد التحضير`

### الملفات
- `lib/features/reader/reader_controls.dart`
- `lib/features/reader/reader_page.dart`

## 9. التفسير

### ما تم
- لون نص التفسير في الوضع الليلي أصبح واضحًا
- وكذلك قائمة اختيار نوع التفسير نفسها

### الملف
- `lib/features/reader/reader_dialogs.dart`

## 10. الوضع الليلي

### الثيم العام
- محفوظ في:
  - `lib/services/quran_store.dart`
- ومطبق من:
  - `lib/core/theme/app_theme.dart`
  - `lib/app/quran_app.dart`

### ربطه بالقارئ
- إذا كان الوضع الليلي العام مفعّلًا:
  - `classic` و`golden` يتحولان إلى `night`
  - `tajweed` يتحول إلى `nightTajweed`
  - وإذا كان المختار `medinaPages`:
    - نفتح على المصحف الليلي النصي بدلًا منه

### الملفات
- `lib/features/reader/reader_state_persistence.dart`

### الصفحات التي دخلها الوضع الليلي
- `lib/features/home/home_shell.dart`
- `lib/features/home/adhkar_page.dart`
- `lib/features/home/tasbih_page.dart`
- `lib/features/home/salawat_reminder_page.dart`
- `lib/features/home/prophet_section_page.dart`
- `lib/features/shared/prophet_biography_page.dart`
- `lib/features/home/prayer_times_page.dart`
- `lib/features/home/prayer_settings_page.dart`
- `lib/features/home/surah_list_page.dart`
- `lib/features/home/index_page.dart`
- شريط القارئ السفلي
- شيت `المزيد`

## 11. شيت المزيد في القارئ

### المشكلة القديمة
- كان أحيانًا يظهر أبيض أو فارغًا في الوضع الليلي

### ما تم
- توحيد الخلفيات والألوان داخل الشيت
- وضبط المجموعات والأزرار لتدعم الداكن

### الملفات
- `lib/features/reader/reader_dialogs.dart`

## 12. الإشعارات بعد نسخة المتجر

### السبب الأقرب الذي ظهر
- `ScheduledNotificationBootReceiver` كان مضبوطًا على:
  - `android:exported="false"`
- وهذا غير مناسب لأنه يستقبل system broadcasts مثل:
  - `BOOT_COMPLETED`
  - `MY_PACKAGE_REPLACED`
- النتيجة:
  - بعد إعادة تشغيل الهاتف أو بعد تحديث التطبيق قد لا تعود الجدولة كما ينبغي

### ما تم
- تم تغيير `BootReceiver` إلى:
  - `android:exported="true"`
- الملف:
  - `android/app/src/main/AndroidManifest.xml`

### مشكلة ثانية ظهرت مع نسخة المتجر
- بعض الأجهزة بعد التثبيت من Google Play لا تمنح `exact alarms` كما كنا نتوقع
- وكان هذا قد يؤدي إلى فشل بعض الجدولات بالكامل

### كيف تم تقويتها
- في:
  - `lib/services/prayer_notification_service.dart`
  - `lib/services/salawat_notification_service.dart`
- أصبح التطبيق:
  - يفحص هل يمكنه جدولة `exact alarms`
  - وإن لم يقدر، لا يسقط الجدولة
  - بل ينزل تلقائيًا إلى `inexactAllowWhileIdle`
- هذا مهم خصوصًا لنسخ المتجر، لأن سلوك الصلاحية يختلف عن بعض تجاربنا المحلية

### ماذا عزلناه مؤقتًا لتقليل المخاطرة
- تم فصل تذكير يوم 12 الهجري (`الأيام البيض`) من الإقلاع العام مؤقتًا
- حتى لا يدخل كعامل إضافي أثناء تثبيت مشكلة الأذان والصلاة والسلام
- الملف:
  - `lib/main.dart`

## 12. إشعارات الصلاة

### الأذان والتنبيه قبل الصلاة
- الملف الأساسي:
  - `lib/services/prayer_notification_service.dart`

### قواعد مهمة
- لا نستخدم `cancelAll()` لهذا المسار
- الأذان نفسه يعتمد على:
  - `AndroidScheduleMode.alarmClock`
- التنبيه قبل الصلاة يعتمد على:
  - `AndroidScheduleMode.exactAllowWhileIdle`

### صوت التنبيه قبل الصلاة
- الصوت الثابت:
  - `a2trb`

## 13. الصلاة والسلام على سيدنا النبي

### الملف الأساسي
- `lib/services/salawat_notification_service.dart`

### قواعد الاستقرار
- لا نعتمد على `periodicallyShowWithDuration` كحل نهائي
- الاعتماد الأساسي على جدولة فعلية
- مع مراعاة عدم تجاوز حد:
  - `500 alarms`

### السلوك الحالي
- يتوقف قبل الفرض بـ 5 دقائق
- ويرجع بعد الفرض افتراضيًا بـ 15 دقيقة
- وإذا المستخدم غيّر مدة الرجوع:
  - نستخدم قيمته هو

### صفحة الإعدادات
- إذا تم إغلاق المفتاح الرئيسي:
  - يتم إطفاء:
    - `إيقاف التذكير وقت الصلاة`
    - `جدولة وقت التشغيل`
  - وتصبح مرات التكرار غير قابلة للضغط

### الملفات
- `lib/services/salawat_notification_service.dart`
- `lib/features/home/salawat_reminder_page.dart`

## 14. سامسونج والإشعارات

### لماذا كانت أصعب
- بعض أجهزة سامسونج كانت:
  - تستقبل إشعارًا بدون صوت
  - أو تؤخر التنبيه
  - أو توقفه مع الشاشة المقفولة

### ما ساعد
- استخدام `alarmClock` للأهم
- تغيير `channel id` عند تغيير الصوت
- إعادة الجدولة عند فتح التطبيق
- فصل مسارات:
  - الأذان
  - الصلاة والسلام
  - والتذكيرات المستقلة

### ملفات مهمة
- `lib/services/prayer_notification_service.dart`
- `lib/services/salawat_notification_service.dart`

## 15. عزل صفحات إعدادات الإشعارات

### الهدف
- إبقاء صفحات إعدادات الإشعارات في مكان مستقل وواضح
- حتى لا تختلط لاحقًا مع صفحات `home` العامة

### الأماكن الجديدة
- إعدادات الأذان:
  - `lib/features/notifications/adhan/adhan_notification_settings_page.dart`
- إعدادات الصلاة والسلام:
  - `lib/features/notifications/salawat/salawat_notification_settings_page.dart`

### ما تغير فقط
- نقل الملفات
- وتعديل أماكن الاستيراد من:
  - `prayer_times_page.dart`
  - `prophet_section_page.dart`

### ما لم يتغير
- منطق الحفظ
- منطق إعادة الجدولة
- الخدمات الخاصة بالإشعارات نفسها
- `lib/main.dart`

## 15. أصوات الأذان الخارجية

### لماذا خرجت من التطبيق
- لتقليل حجم التطبيق
- التوفير التقريبي:
  - حوالي `9 MB`

### الملفات الأساسية
- `lib/services/adhan_audio_cache_service.dart`
- `lib/features/home/prayer_settings_page.dart`
- `lib/services/prayer_notification_service.dart`
- `android/app/src/main/kotlin/com/elshazly/noorquran/app/MainActivity.kt`

## 16. Salawat notifications after Play release

### What we verified on-device
- On Samsung and OPPO, the app was still scheduling many future salawat alarms.
- `adb dumpsys notification` also showed active delivered salawat notifications with ids like `90017`, `90018`, `90019`, etc.
- So the main issue was not "no scheduling", but stacked delivered notifications making the reminder look like it stopped.

### Stabilization we applied
- In `lib/services/salawat_notification_service.dart` we set:
  - `timeoutAfter: 60000`
  - `onlyAlertOnce: false`
- This keeps each salawat notification visible for about one minute, then lets it disappear before the next one.

### Why this matters
- Without auto timeout, Samsung could keep many salawat notifications in the shade.
- After enough stacking, the reminder looked broken even while alarms were still firing.

## 17. Home screen overflow with large system font

### Where
- `lib/features/home/home_shell.dart`

### What we changed
- Clamped text scaling locally on the home screen to a safer range.
- Reduced feature card aspect ratio when the device font scale is large.
- Reduced card padding slightly and allowed feature titles to wrap to 2 lines and subtitles to 3 lines when needed.

### Why
- Some Samsung devices with large system font caused overflow in the first home cards.
- This fix is intentionally local to the home screen so the rest of the app keeps the user font size behavior.

## 18. Samsung app close on launch without FATAL EXCEPTION

### What we observed
- On Samsung, logcat did not show a Dart crash or Java fatal exception.
- The suspicious step right after launch was Play Core update checking via:
  - `AppUpdateService`
  - `InAppUpdate.checkForUpdate()`

### What we changed
- We disabled the automatic update check from `HomeShell.initState()`.
- File:
  - `lib/features/home/home_shell.dart`

### Why
- The app should never risk closing or backgrounding on first launch because of Play update plumbing.
- Update preview code can stay in the project, but auto-check should remain disabled until it is revisited safely.

### كيف تعمل
- قبل التحميل:
  - زر تنزيل
- أثناء التحميل:
  - دائرة تقدم + نسبة
- بعد التحميل:
  - علامة تم التنزيل

### نقطة مهمة جدًا
- المعاينة تعمل مباشرة من الملف المحلي
- لكن إشعار أندرويد لا يعتمد دائمًا على `file://` من مجلد التطبيق
- لذلك بعد التحميل:
  - يتم تسجيل الملف أيضًا عبر `MediaStore`
  - ثم تستخدمه قناة الإشعار كـ URI نظامي صالح

## 16. تذكيرات إضافية

### التذكير اليومي بفتح المصحف
- خدمة مستقلة
- الملف:
  - `lib/services/daily_quran_reminder_service.dart`

### تذكير الأيام البيض
- خدمة مستقلة
- يصل يوم 12 هجري مساءً
- الملف:
  - `lib/services/white_days_reminder_service.dart`

## 17. المشاكل الصعبة وكيف اتحلت

### أ. تحديد الآية في المصاحف النصية
- المشكلة:
  - التحديد كان يلتقط جزءًا من الآية السابقة
  - أو لا يصل إلى آخر الآية
- السبب:
  - وجود `WidgetSpan` وشارات داخل السطر
  - وعدم اعتماد التحديد على الصناديق الفعلية للنص
- الحل:
  - التحويل إلى `TextPainter.getBoxesForSelection`
  - ثم دمج الصناديق ورسمها يدويًا

### ب. تحديد الآية في مصحف المدينة أثناء الصوت
- المشكلة:
  - التحديد داخل الصفحات أصعب من النصوص العادية
- الحل:
  - صفحة أولًا
  - ثم `external highlights`
  - ثم إزالة التحديد عند الإيقاف

### ج. أصوات الأذان بعد نقلها خارج التطبيق
- المشكلة:
  - المعاينة تعمل
  - لكن الإشعار نفسه قد لا يستخدم الملف المحمّل
- السبب:
  - قناة أندرويد لا تعتمد دائمًا على `file://`
- الحل:
  - تسجيل الصوت في `MediaStore`
  - ثم استخدام URI نظامي في الإشعار

### د. سامسونج
- المشكلة:
  - إشعار بلا صوت
  - أو تأخير
  - أو توقف مع قفل الشاشة
- الحل:
  - `alarmClock`
  - تغيير `channel id`
  - إعادة جدولة عند فتح التطبيق
  - وعدم خلط مسارات الإشعارات مع بعضها

### هـ. MP3Quran
- المشكلة:
  - تشغيل السورة من الآية يحتاج timing
  - وبعض القراء لا تكون توقيتاتهم بنفس الدقة
- الحل:
  - جلب `Ayat timing`
  - حفظها محليًا
  - `seek` إلى بداية الآية
  - ثم متابعة الآية الحالية أثناء التشغيل من `positionStream`

## 18. الملفات الأهم عند أي عطل

### القارئ
- `lib/features/reader/reader_page.dart`
- `lib/features/reader/reader_widgets.dart`
- `lib/features/reader/reader_navigation.dart`
- `lib/features/reader/reader_audio.dart`
- `lib/features/reader/reader_state_persistence.dart`
- `lib/features/reader/reader_dialogs.dart`
- `lib/features/reader/reader_controls.dart`

### الإشعارات
- `lib/services/prayer_notification_service.dart`
- `lib/services/salawat_notification_service.dart`
- `lib/services/adhan_audio_cache_service.dart`
- `lib/services/daily_quran_reminder_service.dart`
- `lib/services/white_days_reminder_service.dart`
- `lib/main.dart`

### الثيم
- `lib/services/quran_store.dart`
- `lib/core/theme/app_theme.dart`
- `lib/app/quran_app.dart`

## 19. قاعدة شغل مهمة

أي تعديل كبير في:
- القنوات الصوتية
- أصوات الإشعارات
- الكاش
- الجدولة
- أو التحويل بين المصاحف

لا يتم خلطه مع أكثر من مسار حساس في نفس الجولة.

الطريقة الأفضل دائمًا:
- جولة صغيرة
- ثم اختبار مباشر
- ثم تثبيت النتيجة في هذا الملف

## 20. ملاحظات سريعة مهمة بعد الإطلاق

### شيوخ MP3Quran الذين تمت إضافتهم ثم إزالتهم
- تمت إضافة هؤلاء كتجربة:
  - محمد رفعت
  - محمود البنا
  - مصطفى إسماعيل
  - مصطفى اللاهوني
- ثم تمت إزالتهم من:
  - `lib/data/reader_reciters.dart`
- السبب:
  - ظهر معهم `تعذر تشغيل الملف`
  - فلم نثبتهم داخل النسخة المستقرة
- الخلاصة:
  - لا نرجعهم مرة ثانية إلا بعد اختبار روابطهم وتشغيلهم الفعلي داخل القارئ

### PrayerTimesPage setState after dispose
- ظهر خطأ:
  - `setState() called after dispose()`
- السبب:
  - `addPostFrameCallback` و`_detectCityFromLocation()` كانا قد يكملان بعد خروج الصفحة
- الحل:
  - إضافة `if (!mounted) return;`
  - قبل وبعد المسار المؤجل
  - وفي بداية `_detectCityFromLocation()`
- الملف:
  - `lib/features/home/prayer_times_page.dart`

### الصلاة والسلام على OPPO
- أثناء الفحص على الجهاز:
  - الإعدادات كانت سليمة ومفعلة
  - والإشعارات نفسها كانت مجدولة
- لكن ظهر انحراف في أوقات البداية أحيانًا
- ما تم:
  - جعل بداية الحساب في خدمة الصلاة والسلام تعتمد على:
    - `tz.TZDateTime.now(tz.local)`
  - بدل `DateTime.now()` العادي
- الملف:
  - `lib/services/salawat_notification_service.dart`

### إعادة ضبط مسار الصلاة والسلام
- بعد تكرار الأعطال، تم عمل إعادة بناء نظيفة للمسار بدل الترقيع فوق الكود القديم
- ما تم تبسيطه:
  - الإبقاء فقط على:
    - تفعيل التذكير
    - مدة التكرار
    - الاهتزاز
  - تعطيل منطق:
    - إيقاف التذكير وقت الصلاة
    - جدولة وقت التشغيل
  - الخدمة أصبحت تسجل دفعة بسيطة ثابتة من التنبيهات القادمة فقط
  - الصفحة أعيد بناؤها كواجهة نظيفة مستقلة
- الملفات:
  - `lib/services/salawat_notification_service.dart`
  - `lib/features/notifications/salawat/salawat_notification_settings_page.dart`
- السبب:
  - كان واضحًا أن كثرة التعديلات السابقة صعبت تتبع العطل، فالحل الآمن كان العودة لمسار صغير وواضح

19. Notification stacking after release build
- Symptom: In the release APK, adhan kept working, but salawat and pre-prayer felt like they stopped on Samsung/OPPO even while alarms were still scheduled.
- Device check via adb showed ScheduledNotificationReceiver alarms were present, and Samsung notification history showed repeated salawat deliveries.
- Root cause was closer to delivered-notification stacking than pure scheduling failure: reschedule paths were canceling pending alarms, but not previously delivered notifications already sitting in the tray/group summary.
- Fix:
  - PrayerNotificationService._cancelPrayerNotificationsOnly now also cancels the known prayer/pre-prayer notification IDs for the rolling 3-day window, not only pending requests.
  - SalawatNotificationService.cancelAll now also cancels every salawat ID in its rolling range, not only pending requests.
  - Pre-prayer notifications now use timeoutAfter: 60000 and onlyAlertOnce: false to reduce silent grouping/stacking.
- Result expected: cleaner tray state after each save/reschedule, less silent grouping, and less user perception that reminders stopped after a batch of older notifications accumulated.

20. Release-only notification failure caused by resource shrinking
- Symptom: Notifications using raw sounds (`saly`, `a2trb`) worked in debug, but in release they stopped on both phones while adhan could appear inconsistent.
- Root cause from adb logcat: `PlatformException(invalid_sound, The resource saly/a2trb could not be found...)` during `zonedSchedule` in release.
- Why only release: `isShrinkResources = true` removed the raw resources because they are referenced dynamically from Dart (`RawResourceAndroidNotificationSound`) and not seen as used by Android resource analysis.
- Fix: added `android/app/src/main/res/values/keep.xml` with `tools:keep="@raw/saly,@raw/a2trb"` so R8/resource shrinking keeps these sounds in release builds.
- This is the key explanation for 'debug works, release fails' in salawat and pre-prayer reminders.
21. Final release fix for notification sounds
- After inspecting the built `app-arm64-v8a-release.apk` directly, `res/raw/saly` and `res/raw/a2trb` were still absent from the APK.
- So the issue was confirmed to be in release packaging, not device delivery.
- `tools:keep` alone was not sufficient in this build setup.
- Final stabilization step before store release: set `android.buildTypes.release.isShrinkResources = false` in `android/app/build.gradle.kts`.
- Rationale: notification sounds are tiny, and reliable reminders are more important than the small size saved by resource shrinking.
- Keep `isMinifyEnabled = true`; disable only resource shrinking.
22. Salawat module isolation
- Moved the salawat scheduling service out of `lib/services` into:
  - `lib/features/notifications/salawat/salawat_notification_service.dart`
- Goal:
  - keep the whole feature isolated
  - avoid accidental edits from unrelated notification work
- Added a dedicated local note file:
  - `lib/features/notifications/salawat/SALAWAT_MODULE_NOTES.md`
- The local note file documents:
  - settings page responsibilities
  - scheduling service responsibilities
  - related `QuranStore` keys
  - required Android raw sound files
  - release-build pitfalls
  - safe edits vs risky edits
23. Adhan module isolation
- Moved the prayer scheduling service out of `lib/services` into:
  - `lib/features/notifications/adhan/prayer_notification_service.dart`
- Goal:
  - isolate adhan and pre-prayer reminder logic from the rest of the app
  - make future changes safer and easier to audit
- Added a dedicated local note file:
  - `lib/features/notifications/adhan/ADHAN_MODULE_NOTES.md`
- The local note file documents:
  - settings page responsibilities
  - scheduling service responsibilities
  - the exact pre-prayer reminder path
  - sound/channel mapping
  - related `QuranStore` keys
  - safe edits vs risky edits

24. Safe text-source replacement preparation
- Goal:
  - prepare the app to replace `alfurqan` later without touching the whole reader in one risky pass
  - keep runtime behavior unchanged for now
- What was added:
  - `lib/services/quran_text_source.dart`
    - shared interface for the text-mushaf source
  - `lib/services/quran_flutter_quran_source.dart`
    - alternative source implementation using `quran_flutter`
    - not active yet
  - `lib/services/current_quran_text_source.dart`
    - the single selector file that currently still points to `AlfurqanQuranSource()`
- What was rewired:
  - low-risk consumers now import the selector instead of instantiating `AlfurqanQuranSource` directly:
    - `lib/models/reading_reference.dart`
    - `lib/models/last_read_position.dart`
    - `lib/services/tafsir_service.dart`
    - `lib/features/home/home_shell.dart`
    - `lib/features/home/surah_list_page.dart`
    - reader files through `reader_page.dart` and its parts
- Why this matters:
  - when we later switch from `alfurqan` to `quran_flutter`, the change should be centered in one selector file instead of many scattered files
  - this keeps the first migration step reversible and easier to test
- Current state:
  - app still uses `alfurqan`
  - no user-facing behavior was intentionally changed in this step

25. Thin Uthmani font prepared in main project
- Added dependency:
  - `quran_flutter: ^1.0.3`
- Added the thin font asset to the main app:
  - `assets/fonts/UthmanicHafs_V20.ttf`
- Registered font family in `pubspec.yaml`:
  - `UthmanicHafs`
- Important:
  - the font is only prepared right now
  - it has not been switched on in the reader UI yet
  - this keeps the app stable while we finish the source migration first

26. Text source switched to quran_flutter with tajweed safety split
- `lib/services/current_quran_text_source.dart` now points to:
  - `QuranFlutterQuranSource()`
- Initialization was added early in bootstrap:
  - `ensureCurrentQuranTextSourceInitialized()` runs before app startup finishes in `lib/main.dart`
- Safety choice:
  - normal text mushaf pages now read from `quran_flutter`
  - tajweed rendering in `reader_widgets.dart` still uses:
    - `AlfurqanQuranSource.getVerseMarkup(...)`
- Why:
  - `quran_flutter` gives cleaner connected text and removed the dotted-circle issue in experiments
  - but it does not provide tajweed HTML/markup like `alfurqan`
  - keeping tajweed on `alfurqan` avoids breaking colored tajweed mode during migration
- This means the migration is now split in two stable layers:
  - plain text source: `quran_flutter`
  - tajweed markup source: `alfurqan`

27. Salawat rolling queue could expire after a day
- Symptom:
  - the app could deliver salawat reminders normally, then appear to stop the next day until the user opened the app again
- Root cause:
  - salawat scheduling uses a finite rolling queue, not infinite recurrence
  - the queue length had been `288`
  - this means:
    - `1 minute` => only `4.8 hours`
    - `5 minutes` => only `24 hours`
    - `30 minutes` => `6 days`
- Fix:
  - increased the salawat rolling queue to `480`
  - this keeps us under the older `500 alarms` safety caution while extending the runtime window substantially
- File:
  - `lib/features/notifications/salawat/salawat_notification_service.dart`

28. Salawat on unlock (one-time when screen unlocks)
- Added a dedicated foreground service so OEM background limits do not block unlock reminders.
- New toggle in settings:
  - `lib/features/notifications/salawat/salawat_notification_settings_page.dart`
  - Label: تشغيل ذكر عند فتح قفل الهاتف
- New preference keys in store:
  - `salawat_unlock_enabled`
  - `salawat_unlock_last`
  - `salawat_vibration_enabled` reused for vibration
  - File: `lib/services/quran_store.dart`
- Android foreground service:
  - `android/app/src/main/kotlin/com/elshazly/noorquran/app/SalawatUnlockService.kt`
  - Registers dynamic receiver for `USER_PRESENT` / `SCREEN_ON`
  - Throttles to once per 45 seconds
  - Plays `@raw/saly` sound on a dedicated channel
  - Shows ongoing notification while enabled
- Manifest registration + permission:
  - `android/app/src/main/AndroidManifest.xml`
  - `android.permission.FOREGROUND_SERVICE`
  - `<service ... SalawatUnlockService>`

Why isolated:
- This feature does not reschedule, cancel, or modify the main salawat rolling queue.
- It fires a single lightweight notification on unlock only if enabled.

29. آخر تعديلات مهمة (سريعة الرجوع لها)
- الشروق بصوت مستقل:
  - ملف الصوت: `android/app/src/main/res/raw/shoro2.ogg`
  - تم ضبط الشروق (وقت الأذان + التنبيه قبل الموعد) ليستخدم `shoro2` فقط
  - الملف: `lib/features/notifications/adhan/prayer_notification_service.dart`
  - تحديث keep: `android/app/src/main/res/values/keep.xml`
- معاينة صوت الشروق من الإعدادات:
  - زر معاينة داخل قائمة أصوات الأذان
  - يعتمد على asset داخلي `assets/audio/shoro2.ogg`
  - الملف: `lib/features/notifications/adhan/adhan_notification_settings_page.dart`
- صفحة التسبيح:
  - حصلت عدة محاولات لضبط الـ overflow مع حبات السبحة
  - تم تثبيت التوزيع بحيث لا يوجد سكرول وتتحجّم العناصر حسب الشاشة
  - الملف: `lib/features/home/tasbih_page.dart`

## April 2026 Troubleshooting Recap
- New Windows machine build failure
  - Symptom: Gradle failed before app startup and Java pointed to JDK 25.
  - Root cause: this project setup here expects JDK 17.
  - Fix: install JDK 17, point `JAVA_HOME` to it, then rebuild.

- Online Medina Mushaf first-open spinner after download
  - Symptom: download completed, files existed on device, but the page stayed on the loading spinner until the surah changed.
  - Root cause: `quran_library` could keep a stale failed font-page load future from the first attempt.
  - Final fix: in `vendor/quran_library/lib/src/quran/core/services/quran_fonts_service.dart`, clear `_pageLoadFutures[page]` inside `finally` so the page can retry cleanly.
  - Result: after a full rebuild/install, downloaded Medina pages open normally.

- Why restart alone was not enough
  - Symptom: app behavior still looked old after restart.
  - Cause: some fixes were inside `vendor/quran_library` and package wiring, so hot restart or partial rerun did not always reflect the latest packaged build.
  - Fix: for vendor/package internals use a full rebuild:
    - `flutter clean`
    - `flutter pub get`
    - `flutter build apk --debug`
    - reinstall the APK

- Remote update prompt with online JSON
  - Goal: show what's new before updating with custom actions.
  - Actions supported now:
    - Update now
    - Remind me later
    - Ignore version
  - Files:
    - `lib/services/app_update_service.dart`
    - `docs/app_update_manifest.example.json`
    - `lib/main.dart`
  - Note: put the raw GitHub JSON link in `AppUpdateService.manifestUrl`.

- Tasbih page larger tap zone
  - Goal: make the lower tasbih section easier to tap.
  - Fix: wrap the lower button + bead interaction area in a transparent tap target so pressing anywhere there increments the counter.
