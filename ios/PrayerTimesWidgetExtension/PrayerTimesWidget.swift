import WidgetKit
import SwiftUI

private let appGroupId = "group.com.elshazly.noorquran.app"

struct PrayerTimesEntry: TimelineEntry {
  let date: Date
  let city: String
  let hijriDate: String
  let nextPrayerName: String
  let nextPrayerTime: String
  let nextRemaining: String
  let nextPrayerDate: Date?
  let fajrTime: String
  let dhuhrTime: String
  let asrTime: String
  let maghribTime: String
  let ishaTime: String
}

struct PrayerTimesProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerTimesEntry {
    PrayerTimesEntry(
      date: Date(),
      city: "القاهرة",
      hijriDate: "١ رمضان ١٤٤٧",
      nextPrayerName: "الفجر",
      nextPrayerTime: "٤:١٥ ص",
      nextRemaining: "٠١:٢٠:١٠",
      nextPrayerDate: Date().addingTimeInterval(4810),
      fajrTime: "٤:١٥ ص",
      dhuhrTime: "١٢:٠٢ م",
      asrTime: "٣:٢٧ م",
      maghribTime: "٦:٠٦ م",
      ishaTime: "٧:٣٠ م"
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> Void) {
    let entry = loadEntry()
    let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func loadEntry() -> PrayerTimesEntry {
    let defaults = UserDefaults(suiteName: appGroupId)
    let nextPrayerDate: Date?
    if let nextEpochMs = defaults?.object(forKey: "widget_next_prayer_epoch_ms") as? NSNumber {
      nextPrayerDate = Date(timeIntervalSince1970: nextEpochMs.doubleValue / 1000.0)
    } else {
      nextPrayerDate = nil
    }
    return PrayerTimesEntry(
      date: Date(),
      city: defaults?.string(forKey: "widget_prayer_city") ?? "—",
      hijriDate: defaults?.string(forKey: "widget_hijri_date") ?? "",
      nextPrayerName: defaults?.string(forKey: "widget_next_prayer_name") ?? "الفجر",
      nextPrayerTime: defaults?.string(forKey: "widget_next_prayer_time") ?? "—",
      nextRemaining: defaults?.string(forKey: "widget_next_remaining") ?? "٠٠:٠٠:٠٠",
      nextPrayerDate: nextPrayerDate,
      fajrTime: defaults?.string(forKey: "widget_fajr_time") ?? "—",
      dhuhrTime: defaults?.string(forKey: "widget_dhuhr_time") ?? "—",
      asrTime: defaults?.string(forKey: "widget_asr_time") ?? "—",
      maghribTime: defaults?.string(forKey: "widget_maghrib_time") ?? "—",
      ishaTime: defaults?.string(forKey: "widget_isha_time") ?? "—"
    )
  }
}

struct PrayerTimesWidgetEntryView: View {
  let entry: PrayerTimesProvider.Entry
  @Environment(\.widgetFamily) private var family

  private var prayerRows: [(String, String)] {
    [
      ("الفجر", entry.fajrTime),
      ("الظهر", entry.dhuhrTime),
      ("العصر", entry.asrTime),
      ("المغرب", entry.maghribTime),
      ("العشاء", entry.ishaTime),
    ]
  }

  private var compactPrayerRows: [(name: String, time: String, isNext: Bool)] {
    prayerRows.map { row in
      (name: shortPrayerName(row.0), time: row.1, isNext: isNextPrayer(row.0))
    }
  }

  private var hasLiveRemaining: Bool {
    guard let nextPrayerDate = entry.nextPrayerDate else { return false }
    return nextPrayerDate.timeIntervalSinceNow > 0
  }

  private func normalizedPrayerName(_ value: String) -> String {
    value
      .replacingOccurrences(of: "صلاة", with: "")
      .replacingOccurrences(of: "ال", with: "")
      .replacingOccurrences(of: " ", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func isNextPrayer(_ prayerName: String) -> Bool {
    normalizedPrayerName(entry.nextPrayerName) == normalizedPrayerName(prayerName)
  }

  private func shortPrayerName(_ prayerName: String) -> String {
    switch normalizedPrayerName(prayerName) {
    case "فجر":
      return "الفجر"
    case "ظهر":
      return "الظهر"
    case "عصر":
      return "العصر"
    case "مغرب":
      return "المغرب"
    case "عشاء":
      return "العشاء"
    default:
      return prayerName
    }
  }

  var body: some View {
    Group {
      switch family {
      case .systemSmall:
        smallLayout
      case .systemLarge:
        largeLayout
      default:
        mediumLayout
      }
    }
    .padding(family == .systemSmall ? 10 : 11)
    .noorWidgetBackground {
      LinearGradient(
        colors: [
          Color(red: 0.06, green: 0.20, blue: 0.14),
          Color(red: 0.10, green: 0.29, blue: 0.21),
          Color(red: 0.16, green: 0.36, blue: 0.27),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  @ViewBuilder
  private var smallLayout: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        appBadge(size: 18)
        Spacer()
        Text("القادم")
          .font(.system(size: 11.5, weight: .semibold))
          .foregroundColor(.white.opacity(0.75))
      }

      Text(entry.nextPrayerName)
        .font(.system(size: 20, weight: .heavy))
        .foregroundColor(Color(red: 0.99, green: 0.86, blue: 0.53))
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Text(entry.nextPrayerTime)
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(.white)
        .lineLimit(1)

      VStack(alignment: .leading, spacing: 3) {
        Text("المتبقي")
          .font(.system(size: 10.5, weight: .semibold))
          .foregroundColor(.white.opacity(0.75))
        if hasLiveRemaining, let nextPrayerDate = entry.nextPrayerDate {
          Text(nextPrayerDate, style: .timer)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
        } else {
          Text(entry.nextRemaining)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
        }
      }
      .padding(.horizontal, 9)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color.white.opacity(0.10))
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
          )
      )
    }
  }

  @ViewBuilder
  private var mediumLayout: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 7) {
        appBadge(size: 20)
        Text("نور القرآن")
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(.white.opacity(0.92))
          .lineLimit(1)
          .minimumScaleFactor(0.82)
        Spacer(minLength: 6)
        HStack(spacing: 4) {
          Image(systemName: "mappin.and.ellipse")
            .font(.system(size: 10, weight: .semibold))
          Text(entry.city)
            .font(.system(size: 12, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }
        .foregroundColor(.white.opacity(0.88))
      }

      Text(entry.hijriDate)
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.white.opacity(0.76))
        .lineLimit(1)
        .minimumScaleFactor(0.78)

      HStack(spacing: 10) {
        VStack(alignment: .leading, spacing: 4) {
          Text("الفرض القادم")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white.opacity(0.75))
          HStack(spacing: 6) {
            Text(entry.nextPrayerName)
              .font(.system(size: 18, weight: .heavy))
              .foregroundColor(Color(red: 0.99, green: 0.86, blue: 0.53))
              .lineLimit(1)
              .minimumScaleFactor(0.78)
            Text(entry.nextPrayerTime)
              .font(.system(size: 13, weight: .heavy))
              .foregroundColor(.white)
              .lineLimit(1)
          }
        }
        Spacer(minLength: 8)
        VStack(alignment: .trailing, spacing: 3) {
          Text("المتبقي")
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundColor(.white.opacity(0.72))
          if hasLiveRemaining, let nextPrayerDate = entry.nextPrayerDate {
            Text(nextPrayerDate, style: .timer)
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(.white)
          } else {
            Text(entry.nextRemaining)
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(.white)
          }
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 13, style: .continuous)
          .fill(Color.white.opacity(0.10))
          .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
              .stroke(Color.white.opacity(0.17), lineWidth: 0.8)
          )
      )

      compactPrayerStrip(cellHeight: 42)
    }
  }

  @ViewBuilder
  private var largeLayout: some View {
    VStack(alignment: .leading, spacing: 9) {
      HStack(spacing: 7) {
        appBadge(size: 20)
        Text("نور القرآن")
          .font(.system(size: 13.5, weight: .bold))
          .foregroundColor(.white.opacity(0.92))
        Spacer(minLength: 6)
        HStack(spacing: 5) {
          Image(systemName: "mappin.and.ellipse")
            .font(.system(size: 11, weight: .semibold))
          Text(entry.city)
            .font(.system(size: 12.5, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .foregroundColor(.white.opacity(0.88))
      }

      Text(entry.hijriDate)
        .font(.system(size: 11.5, weight: .medium))
        .foregroundColor(.white.opacity(0.75))
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      HStack(spacing: 10) {
        VStack(alignment: .leading, spacing: 3) {
          Text("الفرض القادم")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white.opacity(0.72))
          Text(entry.nextPrayerName)
            .font(.system(size: 22, weight: .heavy))
            .foregroundColor(Color(red: 0.99, green: 0.86, blue: 0.53))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
        }
        Spacer(minLength: 8)
        VStack(alignment: .trailing, spacing: 4) {
          Text(entry.nextPrayerTime)
            .font(.system(size: 15, weight: .heavy))
            .foregroundColor(.white)
          if hasLiveRemaining, let nextPrayerDate = entry.nextPrayerDate {
            Text(nextPrayerDate, style: .timer)
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(.white)
          } else {
            Text(entry.nextRemaining)
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(.white)
          }
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 9)
      .background(
        RoundedRectangle(cornerRadius: 13, style: .continuous)
          .fill(Color.white.opacity(0.10))
          .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
              .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
          )
      )

      VStack(spacing: 6) {
        ForEach(prayerRows, id: \.0) { row in
          prayerRow(name: row.0, time: row.1, isNext: isNextPrayer(row.0))
        }
      }
    }
  }

  @ViewBuilder
  private func compactPrayerStrip(cellHeight: CGFloat) -> some View {
    HStack {
      ForEach(compactPrayerRows, id: \.name) { row in
        VStack(spacing: 3) {
          Text(row.name)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundColor(row.isNext ? Color(red: 0.17, green: 0.10, blue: 0.02) : .white.opacity(0.85))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
          Text(row.time)
            .font(.system(size: 11.5, weight: .heavy))
            .foregroundColor(row.isNext ? Color(red: 0.17, green: 0.10, blue: 0.02) : .white)
            .lineLimit(1)
            .minimumScaleFactor(0.76)
        }
        .frame(maxWidth: .infinity, minHeight: cellHeight)
        .padding(.vertical, 4)
        .background(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(row.isNext ? Color(red: 0.99, green: 0.86, blue: 0.53) : Color.white.opacity(0.09))
            .overlay(
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(row.isNext ? Color.white.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 0.8)
            )
        )
        .shadow(color: row.isNext ? Color(red: 0.99, green: 0.86, blue: 0.53).opacity(0.28) : .clear, radius: 5, y: 2)
      }
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.white.opacity(0.08))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
        )
    )
  }

  @ViewBuilder
  private func prayerRow(name: String, time: String, isNext: Bool) -> some View {
    HStack {
      Text(name)
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(isNext ? Color(red: 0.99, green: 0.86, blue: 0.53) : .white.opacity(0.86))
      Spacer()
      Text(time)
        .font(.system(size: 13.5, weight: .heavy))
        .foregroundColor(.white)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.white.opacity(0.08))
        .overlay(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(isNext ? Color(red: 0.99, green: 0.86, blue: 0.53).opacity(0.35) : Color.white.opacity(0.10), lineWidth: 0.8)
        )
    )
  }

  @ViewBuilder
  private func appBadge(size: CGFloat) -> some View {
    ZStack {
      Circle()
        .fill(Color.white.opacity(0.18))
      Image(systemName: "book.closed.fill")
        .font(.system(size: size * 0.52, weight: .bold))
        .foregroundColor(Color(red: 0.99, green: 0.86, blue: 0.53))
    }
    .frame(width: size, height: size)
  }
}

private extension View {
  @ViewBuilder
  func noorWidgetBackground<Background: View>(
    @ViewBuilder _ background: () -> Background
  ) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) {
        background()
      }
    } else {
      self.background(background())
    }
  }
}

struct PrayerTimesWidget: Widget {
  let kind: String = "PrayerTimesWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
      PrayerTimesWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("مواقيت الصلاة")
    .description("اعرض المواقيت والصلاة القادمة مباشرة من الشاشة الرئيسية.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
