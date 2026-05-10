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
            try {
                updateWidget(context, appWidgetManager, appWidgetId)
            } catch (_: Exception) {
                val views = RemoteViews(context.packageName, R.layout.berkaskyu_widget)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            android.content.ComponentName(context, BerkasKuWidgetProvider::class.java)
        )
        onUpdate(context, manager, ids)
    }

    private fun makePendingIntent(
        context: Context,
        uriString: String,
        requestCode: Int
    ): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriString)).apply {
            setClass(context, MainActivity::class.java)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else
            PendingIntent.FLAG_UPDATE_CURRENT
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val recent1 = prefs.getString("widget_recent_1", "") ?: ""
        val recent2 = prefs.getString("widget_recent_2", "") ?: ""
        val recent3 = prefs.getString("widget_recent_3", "") ?: ""
        val icon1   = prefs.getString("widget_icon_1", "") ?: ""
        val icon2   = prefs.getString("widget_icon_2", "") ?: ""
        val icon3   = prefs.getString("widget_icon_3", "") ?: ""

        val views = RemoteViews(context.packageName, R.layout.berkaskyu_widget)

        val placeholder = "— belum ada catatan —"

        // Row 1
        if (recent1.isNotEmpty()) {
            views.setTextViewText(R.id.tv_icon_1, icon1)
            views.setTextViewText(R.id.tv_recent_1, recent1)
        } else {
            views.setTextViewText(R.id.tv_icon_1, "")
            views.setTextViewText(R.id.tv_recent_1, placeholder)
        }

        // Row 2 — hide when empty
        views.setTextViewText(R.id.tv_icon_2, if (recent2.isNotEmpty()) icon2 else "")
        views.setTextViewText(R.id.tv_recent_2, recent2)

        // Row 3 — hide when empty
        views.setTextViewText(R.id.tv_icon_3, if (recent3.isNotEmpty()) icon3 else "")
        views.setTextViewText(R.id.tv_recent_3, recent3)

        // "+ Baru" button — use appWidgetId as request code base to avoid conflicts
        val addPendingIntent = makePendingIntent(
            context, "berkaskyu://add_note", appWidgetId * 10 + 1
        )
        views.setOnClickPendingIntent(R.id.btn_add_note, addPendingIntent)

        // Tapping the recent berkas section opens the berkas list
        val openListPendingIntent = makePendingIntent(
            context, "berkaskyu://open_list", appWidgetId * 10 + 2
        )
        views.setOnClickPendingIntent(R.id.recent_rows, openListPendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
