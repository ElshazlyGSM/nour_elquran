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
}
