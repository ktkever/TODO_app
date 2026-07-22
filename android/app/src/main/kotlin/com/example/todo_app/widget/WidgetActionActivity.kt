package com.example.todo_app.widget

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle

// 위젯의 투명도/달력 월이동 버튼이 여는 무화면 트램폴린.
// Glance actionRunCallback(브로드캐스트)이 부모 clickable(앱 열기) 아래에서 안 먹히는 문제를
// 피하려고, 확실히 동작하는 actionStartActivity 경로로 대체한다. pref만 바꾸고 즉시 닫는다.
class WidgetActionActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val prefs = widgetPrefs(this)
        when (intent.getStringExtra("action")) {
            "todo_opacity" -> {
                val next = (prefs.getInt(KEY_OPACITY_INDEX, 0) + 1) % OPACITY_STEPS.size
                prefs.edit().putInt(KEY_OPACITY_INDEX, next).apply()
                notifyWidgetUpdate(this, TodoWidgetReceiver::class.java)
            }
            "cal_opacity" -> {
                val next = (prefs.getInt(KEY_CALENDAR_OPACITY_INDEX, 0) + 1) % OPACITY_STEPS.size
                prefs.edit().putInt(KEY_CALENDAR_OPACITY_INDEX, next).apply()
                notifyWidgetUpdate(this, CalendarWidgetReceiver::class.java)
            }
            "prev_month" -> shiftMonth(prefs, -1)
            "next_month" -> shiftMonth(prefs, 1)
            "reset_month" -> {
                prefs.edit().putInt(KEY_CALENDAR_MONTH_OFFSET, 0).apply()
                notifyWidgetUpdate(this, CalendarWidgetReceiver::class.java)
            }
        }
        finish()
        overridePendingTransition(0, 0) // 트램폴린이라 전환 애니메이션 제거
    }

    private fun shiftMonth(prefs: android.content.SharedPreferences, delta: Int) {
        prefs.edit()
            .putInt(KEY_CALENDAR_MONTH_OFFSET, prefs.getInt(KEY_CALENDAR_MONTH_OFFSET, 0) + delta)
            .apply()
        notifyWidgetUpdate(this, CalendarWidgetReceiver::class.java)
    }
}

// 같은 액티비티를 여는 인텐트라도 PendingIntent가 구분되도록 action별로 data Uri를 다르게 준다
// (Intent 동등성은 extras를 무시하고 data는 반영하므로).
fun widgetActionIntent(context: Context, action: String): Intent =
    Intent(context, WidgetActionActivity::class.java)
        .setData(Uri.parse("todoapp://widget/$action"))
        .putExtra("action", action)
