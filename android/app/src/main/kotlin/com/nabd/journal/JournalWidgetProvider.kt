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

        /** Mood buttons, in layout order, with the mood id each one opens. */
        private val moods = listOf(
            R.id.widget_mood_happy to "happy",
            R.id.widget_mood_peaceful to "peaceful",
            R.id.widget_mood_neutral to "neutral",
            R.id.widget_mood_anxious to "anxious",
            R.id.widget_mood_sad to "sad",
        )

        private fun openEditor(context: Context, requestCode: Int, link: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse(link)
            }
            // A distinct request code per button, or Android would merge the
            // PendingIntents and every button would open the same mood.
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.widget_journal).apply {
                setOnClickPendingIntent(R.id.widget_root, openEditor(context, id * 10, "nabd://editor"))
                moods.forEachIndexed { index, (viewId, mood) ->
                    setOnClickPendingIntent(
                        viewId,
                        openEditor(context, id * 10 + index + 1, "nabd://editor?mood=$mood"),
                    )
                }
                prefs.getString("title", null)?.let { setTextViewText(R.id.widget_title, it) }
                prefs.getString("prompt", null)?.let { setTextViewText(R.id.widget_subtitle, it) }
                setTextViewText(R.id.widget_streak, prefs.getString("streak", "") ?: "")
            }
            manager.updateAppWidget(id, views)
        }
    }
}
