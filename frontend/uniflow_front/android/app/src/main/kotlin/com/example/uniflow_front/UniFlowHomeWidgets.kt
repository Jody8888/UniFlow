package com.example.uniflow_front

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

private const val WIDGET_PREFS_NAME = "uniflow_android_widgets"
private const val WIDGET_PAYLOAD_KEY = "widget_payload"

private data class UniFlowWidgetNotice(
    val title: String,
    val source: String,
    val genre: String,
    val review: String,
    val publishedTimeLabel: String,
    val businessTimeLabel: String,
    val isExpired: Boolean,
)

private data class UniFlowWidgetPayload(
    val updatedAtLabel: String,
    val listVisibleCount: Int,
    val timelineVisibleCount: Int,
    val notices: List<UniFlowWidgetNotice>,
) {
    companion object {
        fun empty(): UniFlowWidgetPayload {
            return UniFlowWidgetPayload(
                updatedAtLabel = "",
                listVisibleCount = 3,
                timelineVisibleCount = 3,
                notices = emptyList(),
            )
        }
    }
}

internal object UniFlowWidgetRepository {
    fun savePayload(context: Context, rawPayload: String) {
        context
            .getSharedPreferences(WIDGET_PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(WIDGET_PAYLOAD_KEY, rawPayload)
            .apply()
    }

    fun loadPayload(context: Context): UniFlowWidgetPayload {
        val rawPayload =
            context
                .getSharedPreferences(WIDGET_PREFS_NAME, Context.MODE_PRIVATE)
                .getString(WIDGET_PAYLOAD_KEY, null)
                ?: return UniFlowWidgetPayload.empty()

        return try {
            val root = JSONObject(rawPayload)
            val noticeJson = root.optJSONArray("notices")
            val notices = mutableListOf<UniFlowWidgetNotice>()

            if (noticeJson != null) {
                for (index in 0 until noticeJson.length()) {
                    val item = noticeJson.optJSONObject(index) ?: continue
                    notices +=
                        UniFlowWidgetNotice(
                            title = item.optString("title"),
                            source = item.optString("source"),
                            genre = item.optString("genre"),
                            review = item.optString("review"),
                            publishedTimeLabel = item.optString("publishedTimeLabel"),
                            businessTimeLabel = item.optString("businessTimeLabel"),
                            isExpired = item.optBoolean("isExpired", false),
                        )
                }
            }

            UniFlowWidgetPayload(
                updatedAtLabel = root.optString("updatedAtLabel"),
                listVisibleCount =
                    root.optInt(
                        "listVisibleCount",
                        listVisibleCountFor(root.optString("listSize", "medium")),
                    ),
                timelineVisibleCount =
                    root.optInt(
                        "timelineVisibleCount",
                        timelineVisibleCountFor(root.optString("timelineSize", "large")),
                    ),
                notices = notices,
            )
        } catch (_: Exception) {
            UniFlowWidgetPayload.empty()
        }
    }

    private fun listVisibleCountFor(size: String): Int {
        return when (size) {
            "small" -> 2
            "large" -> 4
            else -> 3
        }
    }

    private fun timelineVisibleCountFor(size: String): Int {
        return when (size) {
            "small" -> 2
            else -> 3
        }
    }
}

internal object UniFlowWidgetUpdater {
    private val listRowIds =
        intArrayOf(
            R.id.list_row_1,
            R.id.list_row_2,
            R.id.list_row_3,
            R.id.list_row_4,
        )
    private val listTitleIds =
        intArrayOf(
            R.id.list_row_1_title,
            R.id.list_row_2_title,
            R.id.list_row_3_title,
            R.id.list_row_4_title,
        )
    private val listMetaIds =
        intArrayOf(
            R.id.list_row_1_meta,
            R.id.list_row_2_meta,
            R.id.list_row_3_meta,
            R.id.list_row_4_meta,
        )
    private val timelineRowIds =
        intArrayOf(
            R.id.timeline_row_1,
            R.id.timeline_row_2,
            R.id.timeline_row_3,
        )
    private val timelineTimeIds =
        intArrayOf(
            R.id.timeline_row_1_time,
            R.id.timeline_row_2_time,
            R.id.timeline_row_3_time,
        )
    private val timelineTitleIds =
        intArrayOf(
            R.id.timeline_row_1_title,
            R.id.timeline_row_2_title,
            R.id.timeline_row_3_title,
        )

    fun updateAll(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val listWidgetIds =
            appWidgetManager.getAppWidgetIds(
                ComponentName(context, UniFlowListWidgetProvider::class.java),
            )
        val timelineWidgetIds =
            appWidgetManager.getAppWidgetIds(
                ComponentName(context, UniFlowTimelineWidgetProvider::class.java),
            )

        updateListWidgets(context, appWidgetManager, listWidgetIds)
        updateTimelineWidgets(context, appWidgetManager, timelineWidgetIds)
    }

    fun updateListWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        if (appWidgetIds.isEmpty()) {
            return
        }

        val payload = UniFlowWidgetRepository.loadPayload(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.uniflow_widget_list)
            bindSubtitle(
                context = context,
                views = views,
                subtitleId = R.id.widget_list_subtitle,
                payload = payload,
            )
            bindListRows(views, payload)
            bindOpenAppIntent(
                context = context,
                views = views,
                rootId = R.id.widget_list_root,
                clickableIds = listRowIds + intArrayOf(R.id.widget_list_empty),
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    fun updateTimelineWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        if (appWidgetIds.isEmpty()) {
            return
        }

        val payload = UniFlowWidgetRepository.loadPayload(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.uniflow_widget_timeline)
            bindSubtitle(
                context = context,
                views = views,
                subtitleId = R.id.widget_timeline_subtitle,
                payload = payload,
            )
            bindTimelineRows(context, views, payload)
            bindOpenAppIntent(
                context = context,
                views = views,
                rootId = R.id.widget_timeline_root,
                clickableIds = timelineRowIds + intArrayOf(R.id.widget_timeline_empty),
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun bindSubtitle(
        context: Context,
        views: RemoteViews,
        subtitleId: Int,
        payload: UniFlowWidgetPayload,
    ) {
        val subtitle =
            if (payload.updatedAtLabel.isBlank()) {
                context.getString(R.string.uniflow_widget_waiting_sync)
            } else {
                context.getString(R.string.uniflow_widget_synced_at, payload.updatedAtLabel)
            }
        views.setTextViewText(subtitleId, subtitle)
    }

    private fun bindListRows(
        views: RemoteViews,
        payload: UniFlowWidgetPayload,
    ) {
        val visibleItems = payload.notices.take(payload.listVisibleCount)
        views.setViewVisibility(
            R.id.widget_list_empty,
            if (visibleItems.isEmpty()) View.VISIBLE else View.GONE,
        )

        listRowIds.forEachIndexed { index, rowId ->
            if (index < visibleItems.size) {
                val notice = visibleItems[index]
                views.setViewVisibility(rowId, View.VISIBLE)
                views.setTextViewText(listTitleIds[index], notice.title)
                views.setTextViewText(listMetaIds[index], buildListMeta(notice))
            } else {
                views.setViewVisibility(rowId, View.GONE)
            }
        }
    }

    private fun bindTimelineRows(
        context: Context,
        views: RemoteViews,
        payload: UniFlowWidgetPayload,
    ) {
        val visibleItems = payload.notices.take(payload.timelineVisibleCount)
        views.setViewVisibility(
            R.id.widget_timeline_empty,
            if (visibleItems.isEmpty()) View.VISIBLE else View.GONE,
        )

        timelineRowIds.forEachIndexed { index, rowId ->
            if (index < visibleItems.size) {
                val notice = visibleItems[index]
                views.setViewVisibility(rowId, View.VISIBLE)
                views.setTextViewText(timelineTitleIds[index], notice.title)
                views.setTextViewText(
                    timelineTimeIds[index],
                    buildTimelineTime(context, notice),
                )
            } else {
                views.setViewVisibility(rowId, View.GONE)
            }
        }
    }

    private fun buildListMeta(notice: UniFlowWidgetNotice): String {
        val primary =
            listOf(notice.source, notice.genre)
                .filter { it.isNotBlank() }
                .joinToString(" · ")
        if (primary.isNotBlank()) {
            return primary
        }
        return notice.review.ifBlank { notice.publishedTimeLabel }
    }

    private fun buildTimelineTime(
        context: Context,
        notice: UniFlowWidgetNotice,
    ): String {
        if (notice.isExpired) {
            return context.getString(
                R.string.uniflow_widget_expired_time,
                notice.businessTimeLabel,
            )
        }
        return notice.businessTimeLabel.ifBlank { notice.publishedTimeLabel }
    }

    private fun bindOpenAppIntent(
        context: Context,
        views: RemoteViews,
        rootId: Int,
        clickableIds: IntArray,
    ) {
        val pendingIntent =
            PendingIntent.getActivity(
                context,
                1001,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        views.setOnClickPendingIntent(rootId, pendingIntent)
        clickableIds.forEach { viewId ->
            views.setOnClickPendingIntent(viewId, pendingIntent)
        }
    }
}

class UniFlowListWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        UniFlowWidgetUpdater.updateListWidgets(context, appWidgetManager, appWidgetIds)
    }
}

class UniFlowTimelineWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        UniFlowWidgetUpdater.updateTimelineWidgets(context, appWidgetManager, appWidgetIds)
    }
}
