package com.elshazly.noorquran.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.app.KeyguardManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class SalawatUnlockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_USER_PRESENT && action != Intent.ACTION_SCREEN_ON) {
            return
        }

        Log.i(TAG, "onReceive action=$action")
        if (action == Intent.ACTION_SCREEN_ON) {
            val keyguard =
                ContextCompat.getSystemService(context, KeyguardManager::class.java)
            if (keyguard?.isKeyguardLocked == true) {
                Log.i(TAG, "screen_on but keyguard locked; skip")
                return
            }
        }

        val prefs = context.getSharedPreferences(
            FLUTTER_PREFS,
            Context.MODE_PRIVATE,
        )
        if (!prefs.getBoolean("$FLUTTER_PREFIX$UNLOCK_ENABLED_KEY", false)) {
            Log.i(TAG, "unlock disabled in prefs; skip")
            return
        }

        val now = System.currentTimeMillis()
        val last = prefs.getLong("$FLUTTER_PREFIX$UNLOCK_LAST_KEY", 0L)
        if (now - last < MIN_INTERVAL_MS) {
            Log.i(TAG, "throttled: now=$now last=$last")
            return
        }
        prefs.edit().putLong("$FLUTTER_PREFIX$UNLOCK_LAST_KEY", now).apply()

        val soundUri =
            Uri.parse("android.resource://${context.packageName}/raw/saly")
        val channel = NotificationChannel(
            CHANNEL_ID,
            "تنبيه الصلاة على النبي عند فتح الجهاز",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "تنبيه سريع عند فتح قفل الهاتف"
            setSound(
                soundUri,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            enableVibration(prefs.getBoolean("$FLUTTER_PREFIX$VIBRATION_KEY", false))
        }

        val manager =
            ContextCompat.getSystemService(context, NotificationManager::class.java)
                ?: return
        manager.createNotificationChannel(channel)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("الصلاة على النبي")
            .setContentText("اللهم صل وسلم وبارك على سيدنا محمد")
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setSound(soundUri)

        if (prefs.getBoolean("$FLUTTER_PREFIX$VIBRATION_KEY", false)) {
            builder.setVibrate(longArrayOf(0, 300, 180, 500))
        }

        manager.notify(NOTIFICATION_ID, builder.build())
        Log.i(TAG, "salawat unlock notification sent")
    }

    companion object {
        private const val TAG = "SalawatUnlockReceiver"
        private const val CHANNEL_ID = "salawat_unlock_channel_v1"
        private const val NOTIFICATION_ID = 91001
        private const val MIN_INTERVAL_MS = 45_000L
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val FLUTTER_PREFIX = "flutter."
        private const val UNLOCK_ENABLED_KEY = "salawat_unlock_enabled"
        private const val UNLOCK_LAST_KEY = "salawat_unlock_last"
        private const val VIBRATION_KEY = "salawat_vibration_enabled"
    }
}
