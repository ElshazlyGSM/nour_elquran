import Flutter
import UIKit
import WidgetKit

class SceneDelegate: FlutterSceneDelegate {
  private var deviceSettingsChannel: FlutterMethodChannel?
  private var widgetChannel: FlutterMethodChannel?
  private let widgetAppGroupId = "group.com.elshazly.noorquran.app"

  private func installDeviceSettingsChannelIfNeeded() {
    guard deviceSettingsChannel == nil else { return }
    guard let flutterVC = window?.rootViewController as? FlutterViewController else { return }

    let channel = FlutterMethodChannel(
      name: "com.elshazly.noorquran/device_settings",
      binaryMessenger: flutterVC.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "consumeLaunchTarget":
        let target = AppDelegate.pendingLaunchTarget
        AppDelegate.pendingLaunchTarget = nil
        result(target)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    deviceSettingsChannel = channel
  }

  private func installWidgetChannelIfNeeded() {
    guard widgetChannel == nil else { return }
    guard let flutterVC = window?.rootViewController as? FlutterViewController else { return }

    let channel = FlutterMethodChannel(
      name: "com.elshazly.noorquran/widget",
      binaryMessenger: flutterVC.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(false)
        return
      }
      switch call.method {
      case "refreshPrayerWidget":
        let args = call.arguments as? [String: Any]
        result(self.persistWidgetPayloadAndReload(arguments: args))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    widgetChannel = channel
  }

  private func persistWidgetPayloadAndReload(arguments: [String: Any]?) -> Bool {
    guard let defaults = UserDefaults(suiteName: widgetAppGroupId) else {
      return false
    }
    guard let args = arguments else {
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      return true
    }
    let map: [String: String] = [
      "widget_prayer_city": args["city"] as? String ?? "—",
      "widget_hijri_date": args["hijriDate"] as? String ?? "",
      "widget_next_prayer_key": args["nextPrayerKey"] as? String ?? "fajr",
      "widget_next_prayer_name": args["nextPrayerName"] as? String ?? "الفجر",
      "widget_next_prayer_time": args["nextPrayerTime"] as? String ?? "—",
      "widget_next_remaining": args["nextRemaining"] as? String ?? "٠٠:٠٠:٠٠",
      "widget_fajr_time": args["fajrTime"] as? String ?? "—",
      "widget_sunrise_time": args["sunriseTime"] as? String ?? "—",
      "widget_dhuhr_time": args["dhuhrTime"] as? String ?? "—",
      "widget_asr_time": args["asrTime"] as? String ?? "—",
      "widget_maghrib_time": args["maghribTime"] as? String ?? "—",
      "widget_isha_time": args["ishaTime"] as? String ?? "—",
      "widget_updated_at": args["updatedAt"] as? String ?? ""
    ]
    for (key, value) in map {
      defaults.set(value, forKey: key)
    }
    if let nextEpochMs = args["nextPrayerEpochMs"] as? Int64 {
      defaults.set(nextEpochMs, forKey: "widget_next_prayer_epoch_ms")
    } else if let nextEpochMs = args["nextPrayerEpochMs"] as? Int {
      defaults.set(nextEpochMs, forKey: "widget_next_prayer_epoch_ms")
    } else if let nextEpochMs = args["nextPrayerEpochMs"] as? Double {
      defaults.set(Int64(nextEpochMs), forKey: "widget_next_prayer_epoch_ms")
    }
    defaults.synchronize()
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
    return true
  }

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    if let shortcutItem = connectionOptions.shortcutItem {
      AppDelegate.pendingLaunchTarget = AppDelegate.normalizeShortcutTarget(shortcutItem.type)
    }
    installDeviceSettingsChannelIfNeeded()
    installWidgetChannelIfNeeded()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    installDeviceSettingsChannelIfNeeded()
    installWidgetChannelIfNeeded()
  }

  override func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    AppDelegate.pendingLaunchTarget = AppDelegate.normalizeShortcutTarget(shortcutItem.type)
    completionHandler(true)
  }
}
