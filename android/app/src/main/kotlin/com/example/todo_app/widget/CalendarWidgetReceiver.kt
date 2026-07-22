package com.example.todo_app.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class CalendarWidgetReceiver : HomeWidgetGlanceWidgetReceiver<CalendarWidget>() {
    override val glanceAppWidget = CalendarWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetSyncScheduler.ensureScheduled(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetSyncScheduler.cancelIfNoWidgetsRemain(context)
    }
}
