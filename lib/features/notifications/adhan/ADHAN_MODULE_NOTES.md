## Adhan Notifications Module

This folder isolates the prayer-notification feature so we can work on it
without touching unrelated parts of the app.

### Files in this module

- `adhan_notification_settings_page.dart`
  - Settings UI for:
    - enable/disable adhan notifications
    - adhan profile choice
    - per-prayer enable/disable
    - per-prayer time offset
    - pre-prayer reminder minutes
    - Hijri offset
  - Returns a `PrayerSettingsResult` back to `PrayerTimesPage`.
  - Does not schedule notifications directly by itself.

- `prayer_notification_service.dart`
  - Scheduling engine for:
    - adhan at prayer time
    - reminder before prayer
  - Handles plugin initialization and permission requests.
  - Uses `PrayerCity` + `adhan_dart` to compute prayer times.
  - Uses notification ID range below `5000`.

### Important sound mapping

- Prayer-time adhan:
  - uses downloaded adhan profile sound when available
  - channel id pattern:
    - `prayer_times_channel_v4_<profile>_<downloaded/system>`

- Pre-prayer reminder:
  - fixed sound:
    - `@raw/a2trb`
  - fixed channel id:
    - `prayer_reminder_channel_v3`
  - uses:
    - `timeoutAfter: 60000`
    - `onlyAlertOnce: false`
  - this was done to reduce stacking/group-summary confusion

### Important dependencies outside this folder

- `lib/features/home/prayer_times_page.dart`
  - owns current prayer settings state
  - opens the settings page
  - persists settings in `QuranStore`
  - calls `PrayerNotificationService.instance.reschedulePrayerNotifications(...)`

- `lib/main.dart`
  - initializes prayer notifications on startup
  - re-runs reschedule on app resume

- `lib/services/quran_store.dart`
  - stores all prayer-related settings:
    - city
    - auto detect
    - adhan enabled
    - hijri offset
    - per-prayer offsets
    - per-prayer enable map
    - per-prayer reminder minutes
    - selected adhan profile

- `lib/services/adhan_audio_cache_service.dart`
  - handles downloaded adhan files
  - converts downloaded adhan audio to a URI Android can use for notifications

- Android raw resources:
  - `android/app/src/main/res/raw/a2trb.ogg`
    - pre-prayer reminder sound
  - `android/app/src/main/res/values/keep.xml`
    - keeps `@raw/a2trb` in release builds

### Pre-prayer reminder path

If we need to debug `التنبيه قبل الصلاة`, the main path is:

1. user changes reminder minutes in `adhan_notification_settings_page.dart`
2. values are returned to `PrayerTimesPage`
3. `PrayerTimesPage` saves them in `QuranStore`
4. `PrayerTimesPage._rescheduleNotifications()` calls:
   - `PrayerNotificationService.reschedulePrayerNotifications(...)`
5. service creates a reminder notification:
   - same prayer entry id seed + `500`
   - for example:
     - fajr 11 -> reminder 511
     - dhuhr 22 -> reminder 522
     - maghrib 44 -> reminder 544

### Known pitfalls

- Debug worked while release failed:
  - root cause was release resource shrinking removing raw notification sounds
  - final fix was:
    - `android/app/build.gradle.kts` -> `isShrinkResources = false`

- Saving settings can feel like notifications "stopped":
  - if only pending requests are canceled, already delivered notifications may still
    remain in the tray and confuse testing
  - current code also cancels the known delivered IDs for the rolling range

### Safe edits

- Safe:
  - labels and wording
  - adding/removing adhan profiles in UI
  - changing reminder minute choices in UI

- Needs careful real-device retest:
  - channel ids
  - raw sound names
  - schedule mode
  - notification IDs
  - downloaded-adhaan URI handling

### Quick retest checklist

1. Save adhan settings once after install/update.
2. Test prayer-time adhan.
3. Test pre-prayer reminder with a near upcoming time.
4. Test on at least Samsung and OPPO.
