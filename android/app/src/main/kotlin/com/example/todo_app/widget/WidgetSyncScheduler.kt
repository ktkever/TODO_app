package com.example.todo_app.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

// 위젯이 하나라도 홈스크린에 있는 동안 WidgetRefreshWorker를 15분 주기(Android OS 최소
// 허용 주기)로 실행 — 위젯이 전부 제거되면 배터리 낭비를 막기 위해 작업도 취소한다.
object WidgetSyncScheduler {
    private const val WORK_NAME = "widget_refresh_periodic"

    fun ensureScheduled(context: Context) {
        val request =
            PeriodicWorkRequestBuilder<WidgetRefreshWorker>(15, TimeUnit.MINUTES).build()
        WorkManager.getInstance(context)
            .enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
    }

    fun cancelIfNoWidgetsRemain(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val todoIds = manager.getAppWidgetIds(ComponentName(context, TodoWidgetReceiver::class.java))
        val calendarIds =
            manager.getAppWidgetIds(ComponentName(context, CalendarWidgetReceiver::class.java))
        if (todoIds.isEmpty() && calendarIds.isEmpty()) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
