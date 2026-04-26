import Flutter
import UIKit
import UserNotifications
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  static var pendingLaunchTarget: String?

  static func normalizeShortcutTarget(_ type: String) -> String? {
    switch type.lowercased() {
    case "continue", "prayer", "adhkar", "tasbih":
      return type.lowercased()
    default:
      return nil
    }
  }

  private func configureHomeScreenQuickActions() {
    UIApplication.shared.shortcutItems = [
      UIApplicationShortcutItem(
        type: "continue",
        localizedTitle: "متابعة القراءة",
        localizedSubtitle: "الرجوع لآخر موضع قراءة",
        icon: UIApplicationShortcutIcon(systemImageName: "book.fill")
      ),
      UIApplicationShortcutItem(
        type: "prayer",
        localizedTitle: "مواقيت الصلاة",
        localizedSubtitle: "فتح مواقيت الصلاة",
        icon: UIApplicationShortcutIcon(systemImageName: "clock.fill")
      ),
      UIApplicationShortcutItem(
        type: "adhkar",
        localizedTitle: "الأذكار",
        localizedSubtitle: "فتح صفحة الأذكار",
        icon: UIApplicationShortcutIcon(systemImageName: "text.book.closed.fill")
      ),
      UIApplicationShortcutItem(
        type: "tasbih",
        localizedTitle: "السبحة",
        localizedSubtitle: "فتح السبحة",
        icon: UIApplicationShortcutIcon(systemImageName: "circle.grid.cross.fill")
      ),
    ]
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .default,
        options: []
      )
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      NSLog("Failed to configure AVAudioSession for background playback: \(error)")
    }

    if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
      Self.pendingLaunchTarget = Self.normalizeShortcutTarget(shortcutItem.type)
    }
    configureHomeScreenQuickActions()

    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
