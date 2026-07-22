package com.example.todo_app.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class TodoWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodoWidget>() {
    override val glanceAppWidget = TodoWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetSyncScheduler.ensureScheduled(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetSyncScheduler.cancelIfNoWidgetsRemain(context)
    }
}
