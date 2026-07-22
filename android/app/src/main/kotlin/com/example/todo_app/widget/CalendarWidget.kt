package com.example.todo_app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.example.todo_app.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity as homeWidgetActionStartActivity
import java.util.Calendar

private val weekdayLabels = listOf("월", "화", "수", "목", "금", "토", "일")

// 4x6 풀화면 달력 위젯 — calendar_screen.dart와 동일한 월요일 시작 그리드 +
// 기간 일정 막대(bar)/단일 마감일 블록 표시. 탭하면 앱이 열린다(특정 날짜 딥링크는 범위 밖).
//
// 주 단위 행 높이를 고정 dp로 주지 않고 defaultWeight()로 남은 세로 공간을 균등 배분한다 —
// 런처가 위젯에 실제로 내주는 크기는 기기/런처마다 달라서, 고정 높이로는 내용이 잘리거나
// 반대로 위젯 아래쪽에 빈 공간이 남는 문제가 있었다(가중치 레이아웃이면 항상 꽉 채워진다).
class CalendarWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { GlanceContent(context, currentState()) }
    }

    @Composable
    private fun GlanceContent(context: Context, state: HomeWidgetGlanceState) {
        val prefs = state.preferences
        val tasks = readTasks(prefs)
        val categories = readCategories(prefs)

        val now = Calendar.getInstance()
        val year = now.get(Calendar.YEAR)
        val month = now.get(Calendar.MONTH) + 1
        val today = LocalDay(year, month, now.get(Calendar.DAY_OF_MONTH))
        val weeks = buildWeeks(year, month)

        val opacityIndex =
            prefs.getInt(KEY_CALENDAR_OPACITY_INDEX, 0).coerceIn(0, OPACITY_STEPS.size - 1)
        val alpha = OPACITY_STEPS[opacityIndex]

        Box(
            modifier =
                GlanceModifier.fillMaxSize()
                    .background(Color.White.copy(alpha = alpha))
                    .clickable(onClick = homeWidgetActionStartActivity<MainActivity>(context)),
        ) {
            Column(modifier = GlanceModifier.fillMaxSize().padding(6.dp)) {
                Row(modifier = GlanceModifier.fillMaxWidth()) {
                    Text(
                        text = "${year}년 ${month}월",
                        style = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.Bold),
                        modifier = GlanceModifier.defaultWeight(),
                    )
                    Text(
                        text = "${(alpha * 100).toInt()}%",
                        style =
                            TextStyle(fontSize = 11.sp, color = ColorProvider(Color.Gray)),
                        modifier =
                            GlanceModifier.padding(horizontal = 4.dp)
                                .clickable(actionRunCallback<CycleCalendarOpacityAction>()),
                    )
                }
                Spacer(modifier = GlanceModifier.height(2.dp))
                Row(modifier = GlanceModifier.fillMaxWidth()) {
                    weekdayLabels.forEach { label ->
                        Text(
                            text = label,
                            style =
                                TextStyle(fontSize = 8.sp, color = ColorProvider(Color.Gray)),
                            modifier = GlanceModifier.defaultWeight(),
                        )
                    }
                }
                Column(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                    weeks.forEach { week -> WeekRows(week, today, categories, tasks) }
                }
            }
        }
    }

    @Composable
    private fun ColumnScope.WeekRows(
        week: List<LocalDay?>,
        today: LocalDay,
        categories: List<WidgetCategory>,
        tasks: List<WidgetTask>,
    ) {
        // 날짜 숫자 행
        Row(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
            week.forEach { day ->
                Box(
                    modifier = GlanceModifier.defaultWeight(),
                    contentAlignment = Alignment.CenterEnd,
                ) {
                    if (day != null) {
                        val isToday = day == today
                        Text(
                            text = day.day.toString(),
                            style =
                                TextStyle(
                                    fontSize = 9.sp,
                                    fontWeight = if (isToday) FontWeight.Bold else FontWeight.Normal,
                                    color =
                                        ColorProvider(
                                            if (isToday) Color(0xFF0078D4) else Color.DarkGray
                                        ),
                                ),
                        )
                    }
                }
            }
        }

        // 겹침 패킹된 일정 막대/블록 행 — 필요한 행만큼만 그려서 공간을 아낀다.
        val bars = collectBarsForWeek(tasks, week)
        val maxRow = bars.maxOfOrNull { it.second } ?: -1
        for (rowSlot in 0..maxRow) {
            Row(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                for (col in week.indices) {
                    val slotEntry =
                        bars.firstOrNull { (entry, row) ->
                            row == rowSlot && col in entry.colStart..entry.colEnd
                        }
                    if (slotEntry == null) {
                        Spacer(modifier = GlanceModifier.defaultWeight())
                    } else {
                        val (entry, _) = slotEntry
                        val color = Color(colorForCategory(categories, entry.task.categoryId).toInt())
                        val showLabel = col == entry.colStart
                        Box(
                            modifier =
                                GlanceModifier.defaultWeight()
                                    .padding(horizontal = 1.dp)
                                    .background(if (entry.isBar) color else color.copy(alpha = 0.15f)),
                        ) {
                            if (showLabel) {
                                Text(
                                    text = entry.task.title,
                                    maxLines = 1,
                                    style =
                                        TextStyle(
                                            fontSize = 7.sp,
                                            color =
                                                ColorProvider(
                                                    if (entry.isBar) Color.White else color
                                                ),
                                        ),
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

class CycleCalendarOpacityAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val prefs = widgetPrefs(context)
        val next = (prefs.getInt(KEY_CALENDAR_OPACITY_INDEX, 0) + 1) % OPACITY_STEPS.size
        prefs.edit().putInt(KEY_CALENDAR_OPACITY_INDEX, next).apply()
        CalendarWidget().update(context, glanceId)
    }
}
