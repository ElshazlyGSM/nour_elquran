import WidgetKit
import SwiftUI

@main
struct PrayerTimesWidgetBundle: WidgetBundle {
  var body: some Widget {
    PrayerTimesWidget()
    if #available(iOSApplicationExtension 16.1, *) {
      LockScreenPrayerWidget()
    }
  }
}
