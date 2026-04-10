import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionGuard {
  NotificationPermissionGuard._();

  static const _askedKey = 'notification_permission_asked';

  static Future<bool> shouldRequest() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_askedKey) ?? false);
  }

  static Future<void> markRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }
}
