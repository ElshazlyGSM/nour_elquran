import WidgetKit
import SwiftUI

@available(iOSApplicationExtension 16.1, *)
struct LockScreenPrayerEntryView: View {
  let entry: PrayerTimesProvider.Entry
  @Environment(\.widgetFamily) private var family
  private let lineWidth: CGFloat = 4.5

  private var hasLiveRemaining: Bool {
    guard let nextPrayerDate = entry.nextPrayerDate else { return false }
    return nextPrayerDate.timeIntervalSinceNow > 0
  }

  private var resolvedNextPrayerDate: Date? {
    if let nextPrayerDate = entry.nextPrayerDate {
      return nextPrayerDate
    }
    guard let nextIndex = nextPrayerIndex else { return nil }
    return prayerDate(for: nextIndex, relativeTo: Date(), asNextPrayer: true)
  }

  private var nextPrayerIndex: Int? {
    keyIndex(for: entry.nextPrayerName)
  }

  private var previousPrayerDate: Date? {
    guard let nextIndex = nextPrayerIndex else { return nil }
    let previousIndex = (nextIndex + 4) % 5
    return prayerDate(for: previousIndex, relativeTo: Date(), asNextPrayer: false)
  }

  private var progressToNextPrayer: CGFloat {
    guard
      let nextDate = resolvedNextPrayerDate,
      let previousDate = previousPrayerDate
    else { return 0 }
    let total = nextDate.timeIntervalSince(previousDate)
    guard total > 0 else { return 0 }
    let elapsed = Date().timeIntervalSince(previousDate)
    return min(1, max(0, CGFloat(elapsed / total)))
  }

  private func keyIndex(for prayerName: String) -> Int? {
    switch normalizedPrayerName(prayerName) {
    case "فجر": return 0
    case "ظهر": return 1
    case "عصر": return 2
    case "مغرب": return 3
    case "عشاء": return 4
    default: return nil
    }
  }

  private func normalizedPrayerName(_ value: String) -> String {
    value
      .replacingOccurrences(of: "صلاة", with: "")
      .replacingOccurrences(of: "ال", with: "")
      .replacingOccurrences(of: " ", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func prayerDate(for index: Int, relativeTo now: Date, asNextPrayer: Bool) -> Date? {
    let prayerTimes = [entry.fajrTime, entry.dhuhrTime, entry.asrTime, entry.maghribTime, entry.ishaTime]
    guard index >= 0, index < prayerTimes.count else { return nil }
    guard var date = parsePrayerTime(prayerTimes[index], referenceDate: now) else { return nil }

    if asNextPrayer {
      if date <= now {
        date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
      }
      return date
    }

    if date > now {
      date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
    }
    return date
  }

  private func parsePrayerTime(_ text: String, referenceDate: Date) -> Date? {
    let normalized = text
      .replacingOccurrences(of: "٠", with: "0")
      .replacingOccurrences(of: "١", with: "1")
      .replacingOccurrences(of: "٢", with: "2")
      .replacingOccurrences(of: "٣", with: "3")
      .replacingOccurrences(of: "٤", with: "4")
      .replacingOccurrences(of: "٥", with: "5")
      .replacingOccurrences(of: "٦", with: "6")
      .replacingOccurrences(of: "٧", with: "7")
      .replacingOccurrences(of: "٨", with: "8")
      .replacingOccurrences(of: "٩", with: "9")
      .replacingOccurrences(of: "ص", with: "AM")
      .replacingOccurrences(of: "م", with: "PM")
      .replacingOccurrences(of: " ", with: "")
    let parts = normalized.split(separator: ":")
    guard parts.count == 2 else { return nil }
    let hourPart = String(parts[0])
    let minuteAndPeriod = String(parts[1])
    guard
      let minute = Int(minuteAndPeriod.prefix(2)),
      let rawHour = Int(hourPart)
    else { return nil }
    let isPM = minuteAndPeriod.contains("PM")
    let hour24: Int
    if rawHour == 12 {
      hour24 = isPM ? 12 : 0
    } else {
      hour24 = isPM ? rawHour + 12 : rawHour
    }
    var components = Calendar.current.dateComponents([.year, .month, .day], from: referenceDate)
    components.hour = hour24
    components.minute = minute
    components.second = 0
    return Calendar.current.date(from: components)
  }

  private func toArabicDigits(_ text: String) -> String {
    text
      .replacingOccurrences(of: "0", with: "٠")
      .replacingOccurrences(of: "1", with: "١")
      .replacingOccurrences(of: "2", with: "٢")
      .replacingOccurrences(of: "3", with: "٣")
      .replacingOccurrences(of: "4", with: "٤")
      .replacingOccurrences(of: "5", with: "٥")
      .replacingOccurrences(of: "6", with: "٦")
      .replacingOccurrences(of: "7", with: "٧")
      .replacingOccurrences(of: "8", with: "٨")
      .replacingOccurrences(of: "9", with: "٩")
  }

  private var remainingNoSecondsText: String {
    guard let nextDate = resolvedNextPrayerDate else { return entry.nextRemaining }
    let remaining = max(0, Int(nextDate.timeIntervalSince(Date())))
    let hours = remaining / 3600
    let minutes = (remaining % 3600) / 60
    return toArabicDigits(String(format: "%02d:%02d", hours, minutes))
  }

  @ViewBuilder
  private func progressRing(size: CGFloat) -> some View {
    ZStack {
      Circle()
        .stroke(Color.white.opacity(0.22), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: progressToNextPrayer)
        .stroke(
          Color.white.opacity(0.92),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
    }
    .frame(width: size, height: size)
  }

  @ViewBuilder
  private func remainingText(fontSize: CGFloat, weight: Font.Weight) -> some View {
    if hasLiveRemaining {
      Text(remainingNoSecondsText)
        .font(.system(size: fontSize, weight: weight, design: .rounded))
        .environment(\.locale, Locale(identifier: "ar"))
    } else {
      Text(remainingNoSecondsText)
        .font(.system(size: fontSize, weight: weight))
    }
  }

  @ViewBuilder
  private var inlineLayout: some View {
    Text("القادم: \(entry.nextPrayerName) \(entry.nextPrayerTime)")
      .lineLimit(1)
  }

  @ViewBuilder
  private var circularLayout: some View {
    ZStack {
      progressRing(size: 58)
      VStack(spacing: 1) {
        Text(entry.nextPrayerName)
          .font(.system(size: 13.5, weight: .bold))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        remainingText(fontSize: 17.5, weight: .heavy)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
      }
    }
    .multilineTextAlignment(.center)
  }

  @ViewBuilder
  private var rectangularLayout: some View {
    let unifiedLargeSize: CGFloat = 18
    VStack(alignment: .trailing, spacing: 4) {
      Text(entry.hijriDate)
        .font(.system(size: unifiedLargeSize, weight: .heavy))
        .foregroundColor(.white)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
      HStack(spacing: 10) {
        Text(entry.nextPrayerTime)
          .font(.system(size: unifiedLargeSize, weight: .bold))
          .foregroundColor(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        Text(entry.nextPrayerName)
          .font(.system(size: unifiedLargeSize, weight: .heavy))
          .foregroundColor(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
      HStack(spacing: 10) {
        remainingText(fontSize: unifiedLargeSize, weight: .heavy)
          .foregroundColor(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .multilineTextAlignment(.trailing)
        Text("المتبقي")
          .font(.system(size: unifiedLargeSize, weight: .heavy))
          .foregroundColor(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    .multilineTextAlignment(.trailing)
  }

  var body: some View {
    Group {
      switch family {
      case .accessoryInline:
        inlineLayout
      case .accessoryCircular:
        circularLayout
      default:
        rectangularLayout
      }
    }
    .lockScreenWidgetBackground
  }
}

@available(iOSApplicationExtension 16.1, *)
struct LockScreenPrayerWidget: Widget {
  let kind: String = "LockScreenPrayerWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
      LockScreenPrayerEntryView(entry: entry)
    }
    .configurationDisplayName("الصلاة - شاشة القفل")
    .description("ويدجت شفافة لشاشة القفل تعرض الفرض القادم والوقت المتبقي.")
    .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
  }
}

private extension View {
  @ViewBuilder
  var lockScreenWidgetBackground: some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) {
        Color.clear
      }
    } else {
      self
    }
  }
}
