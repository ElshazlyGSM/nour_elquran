package com.elshazly.noorquran.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class SalawatUnlockService : Service() {
    private var receiverRegistered = false
    private val unlockReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                val action = intent?.action ?: return
                if (action != Intent.ACTION_USER_PRESENT) {
                    return
                }
                maybeNotify(context)
            }
        }

    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIFICATION_ID, buildOngoingNotification())
        registerUnlockReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_NOTIFY_ONCE) {
            maybeNotify(this)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        if (receiverRegistered) {
            unregisterReceiver(unlockReceiver)
            receiverRegistered = false
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun registerUnlockReceiver() {
        val filter =
            IntentFilter().apply {
                addAction(Intent.ACTION_USER_PRESENT)
            }
        registerReceiver(unlockReceiver, filter)
        receiverRegistered = true
    }

    private fun maybeNotify(context: Context) {
        val prefs = context.getSharedPreferences(
            FLUTTER_PREFS,
            Context.MODE_PRIVATE,
        )
        if (!prefs.getBoolean("$FLUTTER_PREFIX$UNLOCK_ENABLED_KEY", false)) {
            return
        }

        val now = System.currentTimeMillis()
        val last = prefs.getLong("$FLUTTER_PREFIX$UNLOCK_LAST_KEY", 0L)
        if (now - last < MIN_INTERVAL_MS) {
            return
        }
        prefs.edit().putLong("$FLUTTER_PREFIX$UNLOCK_LAST_KEY", now).apply()

        val soundUri =
            Uri.parse("android.resource://${context.packageName}/raw/saly")
        ensureNotifyChannel(soundUri, prefs)

        val builder =
            NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("الصلاة على النبي")
                .setContentText("اللهم صل وسلم وبارك على سيدنا محمد")
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setSound(soundUri)

        if (prefs.getBoolean("$FLUTTER_PREFIX$VIBRATION_KEY", false)) {
            builder.setVibrate(longArrayOf(0, 300, 180, 500))
        }

        val manager =
            ContextCompat.getSystemService(context, NotificationManager::class.java)
                ?: return
        manager.notify(ALERT_ID, builder.build())
    }

    private fun buildOngoingNotification(): android.app.Notification {
        val manager =
            ContextCompat.getSystemService(this, NotificationManager::class.java)
                ?: throw IllegalStateException("NotificationManager missing")
        val channel =
            NotificationChannel(
                SERVICE_CHANNEL_ID,
                "خدمة ذكر عند فتح الهاتف",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "تشغيل ذكر الصلاة والسلام عند فتح الجهاز"
                setSound(null, null)
            }
        manager.createNotificationChannel(channel)

        return NotificationCompat.Builder(this, SERVICE_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("ذكر عند فتح الهاتف مفعل")
            .setContentText("سيعمل تلقائيًا عند فتح قفل الجهاز")
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun ensureNotifyChannel(soundUri: Uri, prefs: android.content.SharedPreferences) {
        val manager =
            ContextCompat.getSystemService(this, NotificationManager::class.java)
                ?: return
        val channel =
            NotificationChannel(
                CHANNEL_ID,
                "تنبيه الصلاة على النبي عند فتح الجهاز",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "تنبيه سريع عند فتح قفل الهاتف"
                val attributes =
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                setSound(soundUri, attributes)
                enableVibration(
                    prefs.getBoolean("$FLUTTER_PREFIX$VIBRATION_KEY", false),
                )
            }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val ACTION_NOTIFY_ONCE = "com.elshazly.noorquran.ACTION_NOTIFY_ONCE"
        private const val CHANNEL_ID = "salawat_unlock_channel_v1"
        private const val SERVICE_CHANNEL_ID = "salawat_unlock_service_v1"
        private const val ALERT_ID = 91001
        private const val NOTIFICATION_ID = 91002
        private const val MIN_INTERVAL_MS = 45_000L
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val FLUTTER_PREFIX = "flutter."
        private const val UNLOCK_ENABLED_KEY = "salawat_unlock_enabled"
        private const val UNLOCK_LAST_KEY = "salawat_unlock_last"
        private const val VIBRATION_KEY = "salawat_vibration_enabled"
    }
}
