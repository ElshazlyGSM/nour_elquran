## Salawat Notifications Module

This folder intentionally isolates the full `الصلاة والسلام` notification flow.
If this feature needs changes later, start here first and avoid touching unrelated
notification code unless strictly necessary.

### Files in this module

- `salawat_notification_settings_page.dart`
  - The user-facing settings page.
  - Controls:
    - enable/disable reminder
    - interval
    - pause at prayer
    - resume-after-prayer minutes
    - active window (from/to)
    - vibration
  - Saves preferences to `QuranStore`.
  - Calls `SalawatNotificationService.instance.reschedule(...)` after save.

- `salawat_notification_service.dart`
  - The scheduling engine for salawat reminders.
- Uses `flutter_local_notifications`.
- Creates rolling scheduled notifications in the ID range:
    - `90000..90479`
  - Uses raw sound:
    - `@raw/saly`
  - Uses channel id pattern:
    - `salawat_reminders_channel_clean_v3_vib`
    - `salawat_reminders_channel_clean_v3_silent`
  - Important behaviors:
    - clears pending requests and also clears all IDs in its fixed range
    - supports exact alarms when available, falls back to inexact
    - supports prayer pause and daily active window filters
- uses `timeoutAfter: 60000` to reduce visible stacking
    - keeps the rolling queue under the old `500 alarms` safety ceiling

### Important dependencies outside this folder

- `lib/main.dart`
  - Calls `_rescheduleSalawat(store)` on startup and app resume.

- `lib/services/quran_store.dart`
  - Stores all salawat preferences:
    - `savedSalawatReminderEnabled`
    - `savedSalawatReminderIntervalMinutes`
    - `savedSalawatPauseAtPrayer`
    - `savedSalawatPrayerPauseMinutes`
    - `savedSalawatWindowEnabled`
    - `savedSalawatWindowStartMinutes`
    - `savedSalawatWindowEndMinutes`
    - `savedSalawatVibrationEnabled`

- `android/app/src/main/res/raw/saly.ogg`
  - Required notification sound for salawat.

- `android/app/src/main/res/values/keep.xml`
  - Keeps `@raw/saly` and `@raw/a2trb` in release builds.
  - This was added after release builds failed with:
    - `PlatformException(invalid_sound, The resource saly could not be found...)`

### Known problem history

- Reminders worked for hours/days, then stopped until the app was opened again:
  - Root cause was the finite rolling queue length.
  - With `288` notifications:
    - `1 minute` lasted only `4.8 hours`
    - `5 minutes` lasted only `24 hours`
  - Fix:
    - raised the rolling queue to `480` notifications while staying under the historical `500 alarms` caution limit

- Debug worked while release failed:
  - Root cause was resource shrinking removing raw notification sounds.
  - Fix:
    - `android/app/build.gradle.kts` -> `isShrinkResources = false`
    - keep file added at `res/values/keep.xml`

- Notifications looked like they stopped after several deliveries:
  - Root cause was closer to stacked delivered notifications than missing alarms.
  - Fix:
    - `cancelAll()` also clears the full salawat ID range
    - `timeoutAfter: 60000`

### Safe editing guidance

- Safe changes:
  - text/title/body
  - interval choices on the settings page
  - vibration toggle UI
  - summary text

- Changes that require careful retest on real devices:
  - channel id
  - sound resource name
  - schedule mode (`exactAllowWhileIdle`, `inexactAllowWhileIdle`)
  - notification ID range
  - prayer pause calculation
  - startup/resume rescheduling in `main.dart`

### Quick retest checklist

1. Save salawat settings once after install/update.
2. Test with `1 minute` interval.
3. Test on at least:
   - Samsung
   - OPPO
4. Verify both:
   - actual delivery
   - sound resource availability in release
