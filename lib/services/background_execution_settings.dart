import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class BackgroundExecutionSettings {
  BackgroundExecutionSettings._();

  static const MethodChannel _channel = MethodChannel(
    'com.elshazly.noorquran/device_settings',
  );

  static Future<bool> openBackgroundSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openBackgroundSettings');
      if (result == true) {
        return true;
      }
    } on MissingPluginException {
      // Fall back to app settings below.
    } on PlatformException {
      // Fall back to app settings below.
    }

    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openNotificationSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openNotificationSettings');
      if (result == true) {
        return true;
      }
    } on MissingPluginException {
      // Fall back to app settings below.
    } on PlatformException {
      // Fall back to app settings below.
    }

    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openNotificationChannelSettings(String channelId) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openNotificationChannelSettings',
        {'channelId': channelId},
      );
      if (result == true) {
        return true;
      }
    } on MissingPluginException {
      // Fall back to app settings below.
    } on PlatformException {
      // Fall back to app settings below.
    }

    return openNotificationSettings();
  }

  static Future<String?> consumeLaunchTarget() async {
    try {
      return await _channel.invokeMethod<String>('consumeLaunchTarget');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<int?> getNotificationVolume() async {
    try {
      return await _channel.invokeMethod<int>('getNotificationVolume');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<int?> getNotificationMaxVolume() async {
    try {
      return await _channel.invokeMethod<int>('getNotificationMaxVolume');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> setNotificationVolume(int value) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setNotificationVolume',
        {'value': value},
      );
      return result == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> requestPinPrayerWidget() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPinPrayerWidget');
      return result == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> hasPrayerWidget() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPrayerWidget');
      return result == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
