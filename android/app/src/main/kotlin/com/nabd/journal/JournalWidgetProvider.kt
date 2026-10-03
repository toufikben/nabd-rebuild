package com.nabd.journal

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

/**
 * Home screen widget: the writing streak and a short prompt, set by the app
 * through the `nabd/widget` channel. It never shows journal text.
 */
class JournalWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { render(context, appWidgetManager, it) }
    }

    companion object {
        const val PREFS = "nabd_widget"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, JournalWidgetProvider::class.java),
            )
            ids.forEach { render(context, manager, it) }
        }

        private fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("nabd://editor")
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val views = RemoteViews(context.packageName, R.layout.widget_journal).apply {
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                prefs.getString("title", null)?.let { setTextViewText(R.id.widget_title, it) }
                prefs.getString("prompt", null)?.let { setTextViewText(R.id.widget_subtitle, it) }
                setTextViewText(R.id.widget_streak, prefs.getString("streak", "") ?: "")
            }
            manager.updateAppWidget(id, views)
        }
    }
}
