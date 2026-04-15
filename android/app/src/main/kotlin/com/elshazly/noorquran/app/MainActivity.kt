package com.elshazly.noorquran.app

import android.content.ComponentName
import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

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

                    else -> result.notImplemented()
                }
            }
    }

    private fun openBackgroundSettings(): Boolean {
        val intents = mutableListOf<Intent>()
        val packageUri = Uri.parse("package:$packageName")
        val manufacturer = Build.MANUFACTURER.lowercase()

        if (manufacturer.contains("oppo") || manufacturer.contains("realme") || manufacturer.contains("oneplus")) {
            intents += Intent().apply {
                component = ComponentName(
                    "com.coloros.oppoguardelf",
                    "com.coloros.powermanager.fuelgaue.PowerUsageModelActivity",
                )
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

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            registerWithMediaStore(sourceFile, fileName)
        } else {
            registerWithPublicNotificationsDir(sourceFile, fileName)
        }
    }

    private fun registerWithMediaStore(sourceFile: File, fileName: String): String? {
        val resolver = applicationContext.contentResolver
        val relativePath = "${Environment.DIRECTORY_NOTIFICATIONS}/NoorQuran"
        val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val projection = arrayOf(MediaStore.Audio.Media._ID)
        val selection =
            "${MediaStore.Audio.Media.DISPLAY_NAME}=? AND ${MediaStore.Audio.Media.RELATIVE_PATH}=?"
        val selectionArgs = arrayOf(fileName, "$relativePath/")

        resolver.query(collection, projection, selection, selectionArgs, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                return Uri.withAppendedPath(collection, id.toString()).toString()
            }
        }

        val values =
            ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Audio.Media.MIME_TYPE, guessMimeType(fileName))
                put(MediaStore.Audio.Media.RELATIVE_PATH, relativePath)
                put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            }

        val uri = resolver.insert(collection, values) ?: return null
        resolver.openOutputStream(uri)?.use { output ->
            FileInputStream(sourceFile).use { input ->
                input.copyTo(output)
            }
        } ?: return null

        values.clear()
        values.put(MediaStore.Audio.Media.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return uri.toString()
    }

    private fun registerWithPublicNotificationsDir(sourceFile: File, fileName: String): String? {
        val notificationsDir =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_NOTIFICATIONS)
        val targetDir = File(notificationsDir, "NoorQuran")
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }
        val targetFile = File(targetDir, fileName)
        if (!targetFile.exists() || targetFile.length() != sourceFile.length()) {
            sourceFile.copyTo(targetFile, overwrite = true)
        }
        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(targetFile.absolutePath),
            arrayOf(guessMimeType(fileName)),
            null,
        )
        return Uri.fromFile(targetFile).toString()
    }

    private fun guessMimeType(fileName: String): String =
        when {
            fileName.endsWith(".ogg", ignoreCase = true) -> "audio/ogg"
            fileName.endsWith(".mp3", ignoreCase = true) -> "audio/mpeg"
            fileName.endsWith(".wav", ignoreCase = true) -> "audio/wav"
            fileName.endsWith(".m4a", ignoreCase = true) -> "audio/mp4"
            else -> "audio/*"
        }
}


