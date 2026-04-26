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

  private var hasLiveRemaining: Bool {
    guard let nextPrayerDate = entry.nextPrayerDate else { return false }
    return nextPrayerDate.timeIntervalSinceNow > 0
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("نور القرآن")
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(.white.opacity(0.88))
        Spacer()
        HStack(spacing: 5) {
          Image(systemName: "mappin.and.ellipse")
            .font(.system(size: 10, weight: .semibold))
          Text(entry.city)
            .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white.opacity(0.92))
      }

      Text(entry.hijriDate)
        .font(.system(size: 10.5, weight: .medium))
        .foregroundColor(.white.opacity(0.75))

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("الفرض القادم")
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundColor(.white.opacity(0.75))
          Spacer()
          Text(entry.nextPrayerTime)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
        }

        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(entry.nextPrayerName)
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Color(red: 0.99, green: 0.86, blue: 0.53))
          Spacer()
          if hasLiveRemaining, let nextPrayerDate = entry.nextPrayerDate {
            Text(nextPrayerDate, style: .timer)
              .font(.system(size: 12.5, weight: .bold))
              .foregroundColor(.white)
          } else {
            Text(entry.nextRemaining)
              .font(.system(size: 12.5, weight: .bold))
              .foregroundColor(.white)
          }
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(Color.white.opacity(0.10))
          .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
          )
      )

      if family == .systemLarge {
        VStack(spacing: 6) {
          ForEach(prayerRows, id: \.0) { row in
            prayerRow(row.0, row.1)
          }
        }
      } else {
        LazyVGrid(
          columns: [
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6),
          ],
          spacing: 6
        ) {
          ForEach(prayerRows, id: \.0) { row in
            prayerCell(row.0, row.1)
          }
          Color.clear
            .frame(height: 1)
        }
      }
    }
    .padding(11)
    .noorWidgetBackground {
      LinearGradient(
        colors: [Color(red: 0.08, green: 0.23, blue: 0.16), Color(red: 0.11, green: 0.30, blue: 0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  @ViewBuilder
  private func prayerCell(_ name: String, _ time: String) -> some View {
    VStack(alignment: .center, spacing: 3) {
      Text(name)
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(.white.opacity(0.75))
      Text(time)
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity, minHeight: 40)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.white.opacity(0.08))
    )
  }

  @ViewBuilder
  private func prayerRow(_ name: String, _ time: String) -> some View {
    HStack {
      Text(name)
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.white.opacity(0.85))
      Spacer()
      Text(time)
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.white)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.white.opacity(0.08))
    )
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
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}
