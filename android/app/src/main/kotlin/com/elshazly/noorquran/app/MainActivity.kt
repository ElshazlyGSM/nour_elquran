package com.elshazly.noorquran.app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.appwidget.AppWidgetManager
import android.media.AudioManager
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
    private val widgetChannel = "com.elshazly.noorquran/widget"
    private var pendingLaunchTarget: String? = null
    private var lastShortcutsPublishAtMs: Long = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        handleLaunchIntent(intent)
        publishDynamicShortcutsSafely(force = true)
    }

    override fun onResume() {
        super.onResume()
        publishDynamicShortcutsSafely()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLaunchIntent(intent)
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

                    "openNotificationChannelSettings" -> {
                        val channelId = call.argument<String>("channelId")
                        if (channelId.isNullOrBlank()) {
                            result.error("invalid_args", "Missing channelId", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(openNotificationChannelSettings(channelId))
                        } catch (t: Throwable) {
                            result.error("open_notification_channel_settings_failed", t.message, null)
                        }
                    }

                    "consumeLaunchTarget" -> {
                        val target = pendingLaunchTarget
                        pendingLaunchTarget = null
                        result.success(target)
                    }

                    "getNotificationVolume" -> {
                        result.success(getNotificationVolume())
                    }

                    "getNotificationMaxVolume" -> {
                        result.success(getNotificationMaxVolume())
                    }

                    "setNotificationVolume" -> {
                        val value = call.argument<Int>("value")
                        if (value == null) {
                            result.error("invalid_args", "Missing value", null)
                            return@setMethodCallHandler
                        }
                        result.success(setNotificationVolume(value))
                    }

                    "requestPinPrayerWidget" -> {
                        result.success(requestPinPrayerWidget())
                    }
                    "hasPrayerWidget" -> {
                        result.success(hasPrayerWidget())
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "refreshPrayerWidget" -> {
                        try {
                            PrayerTimesWidgetProvider.updateAllWidgets(this)
                            result.success(true)
                        } catch (t: Throwable) {
                            result.error("refresh_widget_failed", t.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun handleLaunchIntent(intent: Intent?) {
        if (intent == null) return

        val fromExtra = intent.getStringExtra("shortcut_target")
        if (!fromExtra.isNullOrBlank()) {
            pendingLaunchTarget = fromExtra.trim().lowercase()
            return
        }

        val data = intent.data ?: return
        if (data.scheme?.lowercase() != "noorquran") return
        if (data.host?.lowercase() != "open") return
        val path = data.path?.trim('/')
        if (!path.isNullOrBlank()) {
            pendingLaunchTarget = path.lowercase()
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

    private fun openNotificationChannelSettings(channelId: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val resolved = intent.resolveActivity(packageManager)
            if (resolved != null) {
                startActivity(intent)
                return true
            }
        }
        return openNotificationSettings()
    }

    private fun getNotificationVolume(): Int {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        return audioManager?.getStreamVolume(AudioManager.STREAM_NOTIFICATION) ?: -1
    }

    private fun getNotificationMaxVolume(): Int {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        return audioManager?.getStreamMaxVolume(AudioManager.STREAM_NOTIFICATION) ?: -1
    }

    private fun setNotificationVolume(value: Int): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_NOTIFICATION)
        val safe = value.coerceIn(0, max)
        audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, safe, 0)
        return true
    }

    private fun requestPinPrayerWidget(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return false
        }
        val appWidgetManager = getSystemService(AppWidgetManager::class.java) ?: return false
        if (!appWidgetManager.isRequestPinAppWidgetSupported) {
            return false
        }
        val provider = ComponentName(this, PrayerTimesWidgetProvider::class.java)
        return appWidgetManager.requestPinAppWidget(provider, null, null)
    }

    private fun hasPrayerWidget(): Boolean {
        val appWidgetManager = getSystemService(AppWidgetManager::class.java) ?: return false
        val provider = ComponentName(this, PrayerTimesWidgetProvider::class.java)
        return appWidgetManager.getAppWidgetIds(provider).isNotEmpty()
    }

    private fun publishDynamicShortcuts() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) {
            return
        }
        val shortcutManager = getSystemService(ShortcutManager::class.java) ?: return

        fun buildShortcut(
            id: String,
            shortLabel: String,
            longLabel: String,
            target: String,
            rank: Int,
        ): ShortcutInfo {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setClass(this@MainActivity, MainActivity::class.java)
                data = Uri.parse("noorquran://open/$target")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return ShortcutInfo.Builder(this, id)
                .setShortLabel(shortLabel)
                .setLongLabel(longLabel)
                .setIcon(Icon.createWithResource(this, R.mipmap.ic_launcher))
                .setRank(rank)
                .setIntent(intent)
                .build()
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        fun readNumberPref(key: String): Int {
            val raw = prefs.all[key] ?: return 0
            return when (raw) {
                is Int -> raw
                is Long -> raw.toInt()
                is Float -> raw.toInt()
                is Double -> raw.toInt()
                is String -> raw.toIntOrNull() ?: 0
                else -> 0
            }
        }
        val lastSurah = readNumberPref("flutter.last_surah")
        val lastVerse = readNumberPref("flutter.last_verse")
        val hasContinue = lastSurah > 0 && lastVerse > 0

        val definitions = mutableListOf<Triple<String, String, String>>()
        if (hasContinue) {
            definitions += Triple("continue_dynamic", "متابعة القراءة", "الرجوع لآخر موضع قراءة")
        }
        definitions += Triple("prayer_dynamic", "مواقيت الصلاة", "فتح مواقيت الصلاة")
        definitions += Triple("adhkar_dynamic", "الأذكار", "فتح صفحة الأذكار")
        definitions += Triple("tasbih_dynamic", "السبحة", "فتح السبحة")

        val shortcuts = definitions.mapIndexed { index, item ->
            val target = when (item.first) {
                "continue_dynamic" -> "continue"
                "prayer_dynamic" -> "prayer"
                "adhkar_dynamic" -> "adhkar"
                "tasbih_dynamic" -> "tasbih"
                else -> "prayer"
            }
            buildShortcut(
                id = item.first,
                shortLabel = item.second,
                longLabel = item.third,
                target = target,
                rank = index,
            )
        }

        try {
            shortcutManager.dynamicShortcuts = shortcuts
        } catch (_: Throwable) {
        }
    }

    private fun publishDynamicShortcutsSafely(force: Boolean = false) {
        val now = System.currentTimeMillis()
        if (!force && now - lastShortcutsPublishAtMs < 2_000L) {
            return
        }
        try {
            publishDynamicShortcuts()
            lastShortcutsPublishAtMs = now
        } catch (_: Throwable) {
            // Never let shortcuts publishing crash app startup/resume.
        }
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


