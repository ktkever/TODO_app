package com.example.todo_app.widget

import android.content.Context
import android.content.SharedPreferences
import java.util.Calendar
import org.json.JSONArray

// Dart 쪽 HomeWidgetService.syncSnapshot / widgetBackgroundCallback과 공유하는 캐시 포맷.
// (lib/services/home_widget_service.dart, lib/models/task.dart의 toWidgetMap 참고)
const val WIDGET_PREFS_NAME = "HomeWidgetPreferences"
const val KEY_TASKS_JSON = "tasks_json"
const val KEY_CATEGORIES_JSON = "categories_json"
const val KEY_TOGGLE_INDEX = "todo_widget_toggle_index"
const val KEY_OPACITY_INDEX = "todo_widget_opacity_index"
const val KEY_CALENDAR_OPACITY_INDEX = "calendar_widget_opacity_index"

// 100/75/50/25% — TODO 위젯 투명도 아이콘을 탭할 때마다 이 목록을 순환한다.
val OPACITY_STEPS = listOf(1.0f, 0.75f, 0.5f, 0.25f)

data class WidgetTask(
    val id: String,
    val title: String,
    val isCompleted: Boolean,
    val categoryId: String?,
    val isToday: Boolean,
    val startDateMillis: Long?,
    val dueDateMillis: Long?,
    val order: Int,
)

data class WidgetCategory(
    val id: String,
    val name: String,
    val colorArgb: Long,
    val order: Int,
)

// CLAUDE.md §4.1 고정 순서(기본 4개 뷰) + 사용자 지정 카테고리를 하나로 합친 토글 대상.
data class ToggleTarget(val id: String, val name: String, val isCustom: Boolean)

private val defaultToggleTargets = listOf(
    ToggleTarget("today", "오늘 할일", false),
    ToggleTarget("planned", "계획된 일정", false),
    ToggleTarget("unplanned", "계획 안된 일정", false),
    ToggleTarget("all", "모두", false),
)

fun widgetPrefs(context: Context): SharedPreferences =
    context.getSharedPreferences(WIDGET_PREFS_NAME, Context.MODE_PRIVATE)

fun readTasks(prefs: SharedPreferences): List<WidgetTask> {
    val raw = prefs.getString(KEY_TASKS_JSON, null) ?: return emptyList()
    return try {
        val arr = JSONArray(raw)
        (0 until arr.length()).map { i ->
            val o = arr.getJSONObject(i)
            WidgetTask(
                id = o.getString("id"),
                title = o.optString("title", ""),
                isCompleted = o.optBoolean("isCompleted", false),
                categoryId = if (o.isNull("categoryId")) null else o.optString("categoryId"),
                isToday = o.optBoolean("isToday", false),
                startDateMillis =
                    if (o.isNull("startDateMillis")) null else o.optLong("startDateMillis"),
                dueDateMillis =
                    if (o.isNull("dueDateMillis")) null else o.optLong("dueDateMillis"),
                order = o.optInt("order", 0),
            )
        }
    } catch (e: Exception) {
        emptyList()
    }
}

fun readCategories(prefs: SharedPreferences): List<WidgetCategory> {
    val raw = prefs.getString(KEY_CATEGORIES_JSON, null) ?: return emptyList()
    return try {
        val arr = JSONArray(raw)
        (0 until arr.length())
            .map { i ->
                val o = arr.getJSONObject(i)
                WidgetCategory(
                    id = o.getString("id"),
                    name = o.optString("name", ""),
                    colorArgb = o.optLong("colorArgb", 0xFF767676),
                    order = o.optInt("order", 0),
                )
            }
            .sortedBy { it.order }
    } catch (e: Exception) {
        emptyList()
    }
}

fun toggleTargets(categories: List<WidgetCategory>): List<ToggleTarget> =
    defaultToggleTargets + categories.map { ToggleTarget(it.id, it.name, true) }

// home_screen.dart의 _filteredTasks와 동일한 필터 규칙(미완료 먼저, order 순).
fun filterTasks(tasks: List<WidgetTask>, target: ToggleTarget): List<WidgetTask> {
    val base = when (target.id) {
        "today" -> tasks.filter { it.isToday }
        "planned" -> tasks.filter { it.dueDateMillis != null }
        "unplanned" -> tasks.filter { it.dueDateMillis == null && it.startDateMillis == null }
        "all" -> tasks
        else -> tasks.filter { it.categoryId == target.id }
    }
    val incomplete = base.filter { !it.isCompleted }.sortedBy { it.order }
    val completed = base.filter { it.isCompleted }.sortedBy { it.order }
    return incomplete + completed
}

// ── 달력 위젯(4단계): calendar_screen.dart의 _buildWeeks/_collectBarsForWeek 포팅 ──
// minSdk 24라 java.time 대신 java.util.Calendar를 쓴다(데스슈가링 없이 API 24에서 바로 동작).

data class LocalDay(val year: Int, val month: Int, val day: Int) : Comparable<LocalDay> {
    private val key get() = year * 10000 + month * 100 + day
    override fun compareTo(other: LocalDay) = key.compareTo(other.key)
}

fun millisToLocalDay(millis: Long): LocalDay {
    val cal = Calendar.getInstance()
    cal.timeInMillis = millis
    return LocalDay(cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH))
}

// 이번 달의 주(週) 목록 생성 (null = 이전/다음 달 여백). calendar_screen.dart의 _buildWeeks와 동일 규칙
// (월요일 시작, startOffset = (weekday - 1) % 7, weekday: 월=1..일=7 — Dart의 DateTime.weekday와 동일하게 맞춤).
fun buildWeeks(year: Int, month: Int): List<List<LocalDay?>> {
    val first = Calendar.getInstance()
    first.set(year, month - 1, 1, 0, 0, 0)
    first.set(Calendar.MILLISECOND, 0)
    val daysInMonth = first.getActualMaximum(Calendar.DAY_OF_MONTH)

    val dowSunBased = first.get(Calendar.DAY_OF_WEEK) // Calendar.SUNDAY=1 .. SATURDAY=7
    val mondayBasedWeekday = if (dowSunBased == Calendar.SUNDAY) 7 else dowSunBased - 1 // 월=1..일=7
    val startOffset = (mondayBasedWeekday - 1) % 7

    val days = mutableListOf<LocalDay?>()
    repeat(startOffset) { days.add(null) }
    for (d in 1..daysInMonth) days.add(LocalDay(year, month, d))
    while (days.size % 7 != 0) days.add(null)

    return days.chunked(7)
}

data class BarEntry(val task: WidgetTask, val colStart: Int, val colEnd: Int, val isBar: Boolean)

private fun colOfDay(week: List<LocalDay?>, day: LocalDay): Int {
    for (i in week.indices) if (week[i] == day) return i
    return -1
}

// 해당 주에 걸치는 일정을 (막대, 겹침 방지용 행 번호 0~2) 목록으로 반환.
// _collectBarsForWeek와 동일한 그리디 행 배정 알고리즘(최대 3행).
fun collectBarsForWeek(tasks: List<WidgetTask>, week: List<LocalDay?>): List<Pair<BarEntry, Int>> {
    val validDays = week.filterNotNull()
    if (validDays.isEmpty()) return emptyList()
    val weekStart = validDays.first()
    val weekEnd = validDays.last()

    val entries = mutableListOf<BarEntry>()
    for (task in tasks) {
        val startMillis = task.startDateMillis
        val dueMillis = task.dueDateMillis
        if (startMillis != null && dueMillis != null) {
            val sDate = millisToLocalDay(startMillis)
            val eDate = millisToLocalDay(dueMillis)
            if (eDate < weekStart || sDate > weekEnd) continue
            val clampedStart = if (sDate < weekStart) weekStart else sDate
            val clampedEnd = if (eDate > weekEnd) weekEnd else eDate
            val colStart = colOfDay(week, clampedStart)
            val colEnd = colOfDay(week, clampedEnd)
            if (colStart == -1 || colEnd == -1) continue
            entries.add(BarEntry(task, colStart, colEnd, true))
        } else if (startMillis == null && dueMillis != null) {
            val dDate = millisToLocalDay(dueMillis)
            val col = colOfDay(week, dDate)
            if (col == -1) continue
            entries.add(BarEntry(task, col, col, false))
        }
    }

    val result = mutableListOf<Pair<BarEntry, Int>>()
    val rowOccupied = HashMap<Int, Int>()
    for (entry in entries) {
        var row = 0
        while (true) {
            var conflict = false
            for (c in entry.colStart..entry.colEnd) {
                if ((rowOccupied[c] ?: 0) > row) {
                    conflict = true
                    break
                }
            }
            if (!conflict) break
            row++
            if (row >= 3) break
        }
        if (row >= 3) continue
        for (c in entry.colStart..entry.colEnd) rowOccupied[c] = row + 1
        result.add(entry to row)
    }
    return result
}

fun colorForCategory(categories: List<WidgetCategory>, categoryId: String?): Long {
    if (categoryId == null) return 0xFF808080
    return categories.firstOrNull { it.id == categoryId }?.colorArgb ?: 0xFF808080
}
