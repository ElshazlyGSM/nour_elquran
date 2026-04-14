import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  AppUpdateService._();

  static final instance = AppUpdateService._();
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const String manifestUrl = 'https://raw.githubusercontent.com/ElshazlyGSM/mushaf-pages/main/app_update_manifest.example.json';

  static const String _ignoreVersionKey = 'app_update_ignored_version';
  static const String _remindAtKey = 'app_update_remind_at';
  static const String _remindVersionKey = 'app_update_remind_version';

  bool _checking = false;
  bool _dialogShown = false;

  Future<void> showUpdatePreview(BuildContext context) async {
    if (_dialogShown || !context.mounted) {
      return;
    }
    final preview = AppUpdateManifest.preview();
    _dialogShown = true;
    try {
      await _showUpdateDialog(context, preview, currentVersion: '2.1.3');
    } finally {
      _dialogShown = false;
    }
  }

  Future<void> checkForUpdates(BuildContext context) async {
    if (_checking || _dialogShown || !context.mounted) {
      return;
    }
    if (manifestUrl.trim().isEmpty) {
      return;
    }

    _checking = true;
    try {
      final manifest = await _fetchManifest();
      if (manifest == null) {
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();
      final latestVersion = manifest.latestVersion.trim();

      if (!_isRemoteVersionNewer(currentVersion, latestVersion)) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (!manifest.forceUpdate) {
        final ignoredVersion = prefs.getString(_ignoreVersionKey)?.trim();
        if (ignoredVersion == latestVersion) {
          return;
        }

        final remindAtMillis = prefs.getInt(_remindAtKey);
        final remindVersion = prefs.getString(_remindVersionKey)?.trim();
        if (remindVersion != null && remindVersion != latestVersion) {
          await prefs.remove(_remindAtKey);
          await prefs.remove(_remindVersionKey);
        } else if (remindAtMillis != null) {
          final remindAt = DateTime.fromMillisecondsSinceEpoch(remindAtMillis);
          if (DateTime.now().isBefore(remindAt)) {
            return;
          }
        }
      }

      if (!context.mounted) {
        return;
      }

      _dialogShown = true;
      final action = await _showUpdateDialog(
        context,
        manifest,
        currentVersion: currentVersion,
      );

      if (action == null) {
        return;
      }

      switch (action) {
        case _UpdatePromptAction.updateNow:
          await _clearLocalDecision();
          await _startUpdate(manifest);
          break;
        case _UpdatePromptAction.remindLater:
          await prefs.setInt(
            _remindAtKey,
            DateTime.now()
                .add(Duration(hours: manifest.remindAfterHours))
                .millisecondsSinceEpoch,
          );
          await prefs.setString(_remindVersionKey, latestVersion);
          break;
        case _UpdatePromptAction.ignoreVersion:
          await prefs.setString(_ignoreVersionKey, latestVersion);
          break;
      }
    } catch (_) {
      // Update checks must never block app usage.
    } finally {
      _checking = false;
      _dialogShown = false;
    }
  }

  Future<void> checkForUpdatesFromNavigator({int retryCount = 6}) async {
    final navigatorState = navigatorKey.currentState;
    final dialogContext = navigatorState?.overlay?.context ?? navigatorKey.currentContext;
    if (dialogContext == null) {
      if (retryCount <= 0) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return checkForUpdatesFromNavigator(retryCount: retryCount - 1);
    }
    await checkForUpdates(dialogContext);
  }

  Future<void> _clearLocalDecision() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ignoreVersionKey);
    await prefs.remove(_remindAtKey);
    await prefs.remove(_remindVersionKey);
  }

  Future<AppUpdateManifest?> _fetchManifest() async {
    final uri = Uri.tryParse(manifestUrl.trim());
    if (uri == null) {
      return null;
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return AppUpdateManifest.fromJson(decoded);
  }

  Future<void> _startUpdate(AppUpdateManifest manifest) async {
    if (Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
            return;
          }
          if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate();
            await InAppUpdate.completeFlexibleUpdate();
            return;
          }
        }
      } catch (_) {
        // Fall back to store URL if available.
      }
    }

    final url = (Platform.isIOS ? manifest.iosStoreUrl : manifest.storeUrl)?.trim();
    if (url == null || url.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<_UpdatePromptAction?> _showUpdateDialog(
    BuildContext context,
    AppUpdateManifest manifest, {
    required String currentVersion,
  }) {
    final title = manifest.title.isNotEmpty ? manifest.title : 'تحديث جديد متاح';
    final message = manifest.message.isNotEmpty ? manifest.message : 'هناك إصدار أحدث من التطبيق.';

    return showDialog<_UpdatePromptAction>(
      context: context,
      barrierDismissible: !manifest.forceUpdate,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 12),
                  Text(
                    'إصدارك الحالي: $currentVersion',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'الإصدار الجديد: ${manifest.latestVersion}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (manifest.whatsNew.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('ما الجديد', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final item in manifest.whatsNew)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (!manifest.forceUpdate && manifest.ignoreEnabled)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(_UpdatePromptAction.ignoreVersion),
                child: const Text('تجاهل'),
              ),
            if (!manifest.forceUpdate && manifest.remindLaterEnabled)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(_UpdatePromptAction.remindLater),
                child: const Text('ذكرني لاحقًا'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(_UpdatePromptAction.updateNow),
              child: const Text('تحديث الآن'),
            ),
          ],
        );
      },
    );
  }

  bool _isRemoteVersionNewer(String current, String remote) {
    final currentParts = _parseVersion(current);
    final remoteParts = _parseVersion(remote);
    final maxLength = currentParts.length > remoteParts.length ? currentParts.length : remoteParts.length;

    for (var i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final remoteValue = i < remoteParts.length ? remoteParts[i] : 0;
      if (remoteValue > currentValue) {
        return true;
      }
      if (remoteValue < currentValue) {
        return false;
      }
    }
    return false;
  }

  List<int> _parseVersion(String input) {
    return input
        .split('+')
        .first
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList(growable: false);
  }
}

enum _UpdatePromptAction {
  updateNow,
  remindLater,
  ignoreVersion,
}

class AppUpdateManifest {
  AppUpdateManifest({
    required this.latestVersion,
    required this.title,
    required this.message,
    required this.whatsNew,
    required this.forceUpdate,
    required this.remindLaterEnabled,
    required this.ignoreEnabled,
    required this.remindAfterHours,
    required this.storeUrl,
    required this.iosStoreUrl,
  });

  final String latestVersion;
  final String title;
  final String message;
  final List<String> whatsNew;
  final bool forceUpdate;
  final bool remindLaterEnabled;
  final bool ignoreEnabled;
  final int remindAfterHours;
  final String? storeUrl;
  final String? iosStoreUrl;

  factory AppUpdateManifest.fromJson(Map<String, dynamic> json) {
    final whatsNewRaw = json['whats_new'];
    return AppUpdateManifest(
      latestVersion: (json['latest_version'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      whatsNew: whatsNewRaw is List
          ? whatsNewRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const <String>[],
      forceUpdate: json['force_update'] == true,
      remindLaterEnabled: json['remind_later_enabled'] != false,
      ignoreEnabled: json['ignore_enabled'] != false,
      remindAfterHours: int.tryParse('${json['remind_after_hours'] ?? 24}') ?? 24,
      storeUrl: json['store_url']?.toString(),
      iosStoreUrl: json['ios_store_url']?.toString(),
    );
  }

  factory AppUpdateManifest.preview() {
    return AppUpdateManifest(
      latestVersion: '2.2.0',
      title: 'تحديث جديد متاح',
      message: 'هذا التحديث يحتوي على تحسينات مهمة وإصلاحات جديدة.',
      whatsNew: const [
        'تحسين ثبات مصحف المدينة',
        'تحسين سرعة التنقل بين السور والأجزاء',
        'إصلاحات عامة وتحسينات في الأداء',
      ],
      forceUpdate: false,
      remindLaterEnabled: true,
      ignoreEnabled: true,
      remindAfterHours: 24,
      storeUrl: 'https://play.google.com/store/apps/details?id=com.elshazly.noorquran.app',
      iosStoreUrl: null,
    );
  }
}

