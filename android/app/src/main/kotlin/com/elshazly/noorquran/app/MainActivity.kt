package com.elshazly.noorquran.app

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.FileProvider
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val adhanChannel = "com.elshazly.noorquran/adhan_audio"
    private val settingsChannel = "com.elshazly.noorquran/device_settings"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, adhanChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "registerNotificationSound" -> {
                        val filePath = call.argument<String>("filePath")
                        val fileName = call.argument<String>("fileName")
                        if (filePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                            result.error("invalid_args", "Missing filePath or fileName", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(registerNotificationSound(filePath, fileName))
                        } catch (t: Throwable) {
                            result.error("register_failed", t.message, null)
                        }
                    }

                    "openNotificationSettings" -> {
                        try {
                            result.success(openNotificationSettings())
                        } catch (t: Throwable) {
                            result.error("open_notification_settings_failed", t.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, settingsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBackgroundSettings" -> {
                        try {
                            result.success(openBackgroundSettings())
                        } catch (t: Throwable) {
                            result.error("open_background_settings_failed", t.message, null)
                        }
                    }

                    "openNotificationSettings" -> {
                        try {
                            result.success(openNotificationSettings())
                        } catch (t: Throwable) {
                            result.error("open_notification_settings_failed", t.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }


    private fun openNotificationSettings(): Boolean {
        val packageUri = Uri.parse("package:$packageName")
        val intents = mutableListOf<Intent>()

        intents += Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            putExtra("app_package", packageName)
            putExtra("app_uid", applicationInfo.uid)
        }

        intents += Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = packageUri
        }

        intents += Intent(Settings.ACTION_SETTINGS)

        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            val resolved = intent.resolveActivity(packageManager)
            if (resolved != null) {
                startActivity(intent)
                return true
            }
        }

        return false
    }
    private fun openBackgroundSettings(): Boolean {
        val intents = mutableListOf<Intent>()
        val packageUri = Uri.parse("package:$packageName")
        val manufacturer = Build.MANUFACTURER.lowercase()

        intents += Intent("android.settings.APP_BATTERY_SETTINGS").apply {
            putExtra("android.provider.extra.APP_PACKAGE", packageName)
            data = packageUri
        }
        intents += Intent("android.settings.VIEW_ADVANCED_POWER_USAGE_DETAIL").apply {
            data = packageUri
            putExtra("package_name", packageName)
            putExtra("packageName", packageName)
        }

        if (manufacturer.contains("oppo") || manufacturer.contains("realme") || manufacturer.contains("oneplus")) {
            intents += Intent().apply {
                component = ComponentName(
                    "com.coloros.oppoguardelf",
                    "com.coloros.powermanager.fuelgaue.PowerUsageModelActivity",
                )
                putExtra("packageName", packageName)
                putExtra("pkg_name", packageName)
            }
            intents += Intent().apply {
                component = ComponentName(
                    "com.coloros.oppoguardelf",
                    "com.coloros.powermanager.fuelgaue.PowerConsumptionActivity",
                )
                putExtra("packageName", packageName)
                putExtra("pkg_name", packageName)
            }
            intents += Intent().apply {
                component = ComponentName(
                    "com.coloros.oppoguardelf",
                    "com.coloros.powermanager.fuelgaue.PowerControlActivity",
                )
                putExtra("packageName", packageName)
                putExtra("pkg_name", packageName)
            }
            intents += Intent().apply {
                component = ComponentName(
                    "com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity",
                )
            }
            intents += Intent().apply {
                component = ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.startupapp.StartupAppListActivity",
                )
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(PowerManager::class.java)
            if (powerManager != null && !powerManager.isIgnoringBatteryOptimizations(packageName)) {
                intents += Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = packageUri
                }
            }
            intents += Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        }

        intents += Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = packageUri
        }
        intents += Intent(Settings.ACTION_SETTINGS)

        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            val resolved = intent.resolveActivity(packageManager)
            if (resolved != null) {
                startActivity(intent)
                return true
            }
        }

        return false
    }

    private fun registerNotificationSound(filePath: String, fileName: String): String? {
        val sourceFile = File(filePath)
        if (!sourceFile.exists() || sourceFile.length() <= 0L) {
            return null
        }

        val targetDir = File(filesDir, "adhan_audio")
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }

        // Cleanup old public copy (legacy behavior) when possible.
        val legacyFile = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_NOTIFICATIONS),
            "NoorQuran/$fileName",
        )
        if (legacyFile.exists()) {
            legacyFile.delete()
        }

        val targetFile = File(targetDir, fileName)
        if (!targetFile.exists() || targetFile.length() != sourceFile.length()) {
            sourceFile.copyTo(targetFile, overwrite = true)
        }

        val authority = "$packageName.fileprovider"
        val uri = FileProvider.getUriForFile(this, authority, targetFile)
        grantUriPermission("android", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        grantUriPermission("com.android.systemui", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return uri.toString()
    }
}


