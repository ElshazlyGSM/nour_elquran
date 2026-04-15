import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'app_update_service.dart';

class LocationPermissionPrompt {
  LocationPermissionPrompt._();

  static Future<LocationPermission> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final shouldContinue = await _showPrePermissionDialog();
      if (!shouldContinue) {
        return permission;
      }
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await _showOpenSettingsDialog();
    }

    return permission;
  }

  static BuildContext? _resolveDialogContext() {
    final navigatorState = AppUpdateService.navigatorKey.currentState;
    return navigatorState?.overlay?.context ??
        AppUpdateService.navigatorKey.currentContext;
  }

  static Future<bool> _showPrePermissionDialog() async {
    final dialogContext = _resolveDialogContext();
    if (dialogContext == null || !dialogContext.mounted) {
      return true;
    }

    final result = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('السماح باستخدام الموقع'),
        content: const Text(
          'نستخدم موقعك لتحديد مواقيت الصلاة بدقة، واختيار أقرب مدينة، ومعرفة اتجاه القبلة بشكل صحيح.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ليس الآن'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static Future<void> _showOpenSettingsDialog() async {
    final dialogContext = _resolveDialogContext();
    if (dialogContext == null || !dialogContext.mounted) {
      return;
    }

    await showDialog<void>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('إذن الموقع موقوف'),
        content: const Text(
          'تم إيقاف إذن الموقع نهائيًا. يمكنك تفعيله من إعدادات التطبيق إذا أردت استخدام المواقيت حسب موقعك والقبلة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لاحقًا'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openAppSettings();
              if (Platform.isAndroid) {
                await Geolocator.openLocationSettings();
              }
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}
