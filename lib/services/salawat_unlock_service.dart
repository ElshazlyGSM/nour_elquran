import 'package:flutter/services.dart';

class SalawatUnlockService {
  SalawatUnlockService._();

  static const _channel =
      MethodChannel('com.elshazly.noorquran/salawat_unlock');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('start');
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }

  static Future<void> notifyOnce() async {
    try {
      await _channel.invokeMethod('notifyOnce');
    } catch (_) {}
  }
}
