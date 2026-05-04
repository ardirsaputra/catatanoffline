package com.example.notecustomseasyuse

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews

class BerkasKuWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val recent1 = prefs.getString("flutter.widget_recent_1", "") ?: ""
        val recent2 = prefs.getString("flutter.widget_recent_2", "") ?: ""
        val recent3 = prefs.getString("flutter.widget_recent_3", "") ?: ""

        val views = RemoteViews(context.packageName, R.layout.berkaskyu_widget)

        val placeholder = "— belum ada catatan —"
        views.setTextViewText(R.id.tv_recent_1, if (recent1.isNotEmpty()) "\u2022 $recent1" else placeholder)
        views.setTextViewText(R.id.tv_recent_2, if (recent2.isNotEmpty()) "\u2022 $recent2" else "")
        views.setTextViewText(R.id.tv_recent_3, if (recent3.isNotEmpty()) "\u2022 $recent3" else "")

        // Build intent manually to avoid HomeWidgetLaunchIntent which sets
        // pendingIntentBackgroundActivityStartMode — restricted on Android 14+.
        val launchIntent = Intent(Intent.ACTION_VIEW, Uri.parse("berkaskyu://add_note")).apply {
            setClass(context, MainActivity::class.java)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else
            PendingIntent.FLAG_UPDATE_CURRENT

        val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, piFlags)
        views.setOnClickPendingIntent(R.id.btn_add_note, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
