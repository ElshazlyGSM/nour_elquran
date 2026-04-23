package com.elshazly.noorquran.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

class PrayerTimesWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateAllWidgets(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH_WIDGET) {
            updateAllWidgets(context)
        }
    }

    private fun buildViews(context: Context): RemoteViews {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val city = prefs.getString("flutter.widget_prayer_city", "—") ?: "—"
        val nextKey = prefs.getString("flutter.widget_next_prayer_key", "fajr") ?: "fajr"
        val hijriDate = prefs.getString("flutter.widget_hijri_date", "") ?: ""
        val sunrise = prefs.getString("flutter.widget_sunrise_time", "—") ?: "—"
        val fajr = prefs.getString("flutter.widget_fajr_time", "—") ?: "—"
        val dhuhr = prefs.getString("flutter.widget_dhuhr_time", "—") ?: "—"
        val asr = prefs.getString("flutter.widget_asr_time", "—") ?: "—"
        val maghrib = prefs.getString("flutter.widget_maghrib_time", "—") ?: "—"
        val isha = prefs.getString("flutter.widget_isha_time", "—") ?: "—"

        val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)
        views.setTextViewText(R.id.widget_city, city)
        views.setTextViewText(R.id.widget_hijri_date, hijriDate)
        views.setTextViewText(R.id.widget_sunrise_label, "الشروق: $sunrise")
        views.setTextViewText(R.id.widget_fajr_time, fajr)
        views.setTextViewText(R.id.widget_dhuhr_time, dhuhr)
        views.setTextViewText(R.id.widget_asr_time, asr)
        views.setTextViewText(R.id.widget_maghrib_time, maghrib)
        views.setTextViewText(R.id.widget_isha_time, isha)

        applyHighlight(views, nextKey)

        val openIntent = Intent(Intent.ACTION_VIEW).apply {
            setClass(context, MainActivity::class.java)
            data = android.net.Uri.parse("noorquran://open/prayer")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPending = PendingIntent.getActivity(
            context,
            11001,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, openPending)

        return views
    }

    private fun applyHighlight(views: RemoteViews, nextKey: String) {
        val normalText = Color.parseColor("#FFFFFF")
        val normalName = Color.parseColor("#CEE0D8")
        val activeText = Color.parseColor("#14392A")

        val items = mapOf(
            "fajr" to Triple(R.id.widget_item_fajr, R.id.widget_fajr_name, R.id.widget_fajr_time),
            "dhuhr" to Triple(R.id.widget_item_dhuhr, R.id.widget_dhuhr_name, R.id.widget_dhuhr_time),
            "asr" to Triple(R.id.widget_item_asr, R.id.widget_asr_name, R.id.widget_asr_time),
            "maghrib" to Triple(R.id.widget_item_maghrib, R.id.widget_maghrib_name, R.id.widget_maghrib_time),
            "isha" to Triple(R.id.widget_item_isha, R.id.widget_isha_name, R.id.widget_isha_time),
        )

        items.values.forEach { item ->
            views.setInt(item.first, "setBackgroundResource", R.drawable.widget_prayer_item_bg)
            views.setTextColor(item.second, normalName)
            views.setTextColor(item.third, normalText)
        }

        val active = items[nextKey] ?: return
        views.setInt(active.first, "setBackgroundResource", R.drawable.widget_prayer_item_bg_active)
        views.setTextColor(active.second, activeText)
        views.setTextColor(active.third, activeText)
    }

    companion object {
        const val ACTION_REFRESH_WIDGET = "com.elshazly.noorquran.app.REFRESH_PRAYER_WIDGET"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, PrayerTimesWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isEmpty()) return
            val provider = PrayerTimesWidgetProvider()
            ids.forEach { appWidgetId ->
                manager.updateAppWidget(appWidgetId, provider.buildViews(context))
            }
        }
    }
}
