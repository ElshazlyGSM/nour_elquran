# iOS Prayer WidgetKit Setup

The Flutter side and iOS bridge are prepared.  
To make the widget appear in the iPhone widget gallery, complete these Xcode steps once:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Add new target: `File` > `New` > `Target...` > `Widget Extension`.
3. Name it: `PrayerTimesWidgetExtension`.
4. When asked, activate scheme: `Activate`.
5. Copy the prepared files from:
   - `ios/PrayerTimesWidgetExtension/PrayerTimesWidgetBundle.swift`
   - `ios/PrayerTimesWidgetExtension/PrayerTimesWidget.swift`
   - `ios/PrayerTimesWidgetExtension/Info.plist`
   - `ios/PrayerTimesWidgetExtension/PrayerTimesWidgetExtension.entitlements`
6. Runner target > `Signing & Capabilities`:
   - add `App Groups`
   - include `group.com.elshazly.noorquran.app`
7. Widget extension target > `Signing & Capabilities`:
   - add `App Groups`
   - include `group.com.elshazly.noorquran.app`
8. Build and run on iPhone.
9. On home screen:
   - long press > `+` > search `نور القرآن`
   - add the prayer widget.

## Notes

- Widget data is written by Flutter through method channel:
  - `com.elshazly.noorquran/widget`
- iOS bridge persists values to App Group `UserDefaults`.
- Widget timelines are reloaded using `WidgetCenter.shared.reloadAllTimelines()`.

