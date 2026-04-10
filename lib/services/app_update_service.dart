import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService._();

  static final instance = AppUpdateService._();

  bool _checking = false;
  bool _dialogShown = false;

  Future<void> showUpdatePreview(BuildContext context) async {
    if (_dialogShown || !context.mounted) {
      return;
    }
    _dialogShown = true;
    try {
      await _showUpdateDialog(context);
    } finally {
      _dialogShown = false;
    }
  }

  Future<void> checkForUpdates(BuildContext context) async {
    if (_checking || _dialogShown || !Platform.isAndroid) {
      return;
    }
    _checking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      if (!context.mounted) {
        return;
      }

      _dialogShown = true;
      final shouldUpdate = await _showUpdateDialog(context);
      if (shouldUpdate != true) {
        return;
      }

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (_) {
      // Update checks must never block app usage.
    } finally {
      _checking = false;
      _dialogShown = false;
    }
  }

  Future<bool?> _showUpdateDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تحديث جديد متاح'),
          content: const Text(
            'هناك إصدار أحدث من التطبيق. يُفضّل التحديث للحصول على أفضل استقرار وتحسينات جديدة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('لاحقًا'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('تحديث الآن'),
            ),
          ],
        );
      },
    );
  }
}
