package com.example.todo_app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.example.todo_app.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity as homeWidgetActionStartActivity
import java.util.Calendar

private val weekdayLabels = listOf("월", "화", "수", "목", "금", "토", "일")

// 4x6 풀화면 달력 위젯(다크 테마) — calendar_screen.dart와 동일한 월요일 시작 그리드 +
// 기간 일정 막대(bar)/단일 마감일 블록 표시. 상단 연/월 좌우의 화살표로 월 단위 페이지를 넘기고,
// 연/월 자체를 탭하면 이번 달로 돌아온다. 격자 구분선(주 단위 가로줄)을 그려 날짜 구분을 명확히 한다.
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

        // 표시 중인 달 = 오늘 기준 offset개월 이동한 달(좌우 화살표로 조절).
        val offset = prefs.getInt(KEY_CALENDAR_MONTH_OFFSET, 0)
        val shown = Calendar.getInstance().apply { add(Calendar.MONTH, offset) }
        val year = shown.get(Calendar.YEAR)
        val month = shown.get(Calendar.MONTH) + 1
        val now = Calendar.getInstance()
        val today = LocalDay(now.get(Calendar.YEAR), now.get(Calendar.MONTH) + 1, now.get(Calendar.DAY_OF_MONTH))
        val weeks = buildWeeks(year, month)

        val opacityIndex =
            prefs.getInt(KEY_CALENDAR_OPACITY_INDEX, 0).coerceIn(0, OPACITY_STEPS.size - 1)
        val alpha = OPACITY_STEPS[opacityIndex]

        val textColor = Color(WIDGET_TEXT_ARGB)
        val subTextColor = Color(WIDGET_SUBTEXT_ARGB)
        val gridColor = Color(WIDGET_GRID_ARGB)

        Box(
            modifier =
                GlanceModifier.fillMaxSize()
                    .background(Color(WIDGET_BG_ARGB).copy(alpha = alpha))
                    .clickable(onClick = homeWidgetActionStartActivity<MainActivity>(context)),
        ) {
            Column(modifier = GlanceModifier.fillMaxSize().padding(6.dp)) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    // 연/월 좌우 화살표로 월 페이지 넘김.
                    Text(
                        text = "◀",
                        style = TextStyle(fontSize = 16.sp, color = ColorProvider(subTextColor)),
                        modifier =
                            GlanceModifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                .clickable(
                                    onClick = actionStartActivity(widgetActionIntent(context, "prev_month"))
                                ),
                    )
                    Text(
                        text = "${year}년 ${month}월",
                        style =
                            TextStyle(
                                fontSize = 17.sp,
                                fontWeight = FontWeight.Bold,
                                color = ColorProvider(textColor),
                            ),
                        // 연/월 탭 → 이번 달로 복귀.
                        modifier =
                            GlanceModifier.clickable(
                                onClick = actionStartActivity(widgetActionIntent(context, "reset_month"))
                            ),
                    )
                    Text(
                        text = "▶",
                        style = TextStyle(fontSize = 16.sp, color = ColorProvider(subTextColor)),
                        modifier =
                            GlanceModifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                .clickable(
                                    onClick = actionStartActivity(widgetActionIntent(context, "next_month"))
                                ),
                    )
                    Spacer(modifier = GlanceModifier.defaultWeight())
                    Text(
                        text = "${(alpha * 100).toInt()}%",
                        style = TextStyle(fontSize = 14.sp, color = ColorProvider(subTextColor)),
                        modifier =
                            GlanceModifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                .clickable(
                                    onClick = actionStartActivity(widgetActionIntent(context, "cal_opacity"))
                                ),
                    )
                }
                Spacer(modifier = GlanceModifier.height(3.dp))
                Row(modifier = GlanceModifier.fillMaxWidth()) {
                    weekdayLabels.forEach { label ->
                        Text(
                            text = label,
                            style =
                                TextStyle(
                                    fontSize = 13.sp,
                                    color = ColorProvider(subTextColor),
                                    textAlign = TextAlign.Center,
                                ),
                            modifier = GlanceModifier.defaultWeight(),
                        )
                    }
                }
                // 요일 헤더 아래 구분선.
                GridDivider(gridColor)
                Box(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                    // 세로 격자선 오버레이(내용 아래) — 각 칸을 동일 가중치 Box로 두고 오른쪽 끝에 선을 그려
                    // 날짜 열과 정확히 정렬시킨다(예전엔 선이 가로폭을 차지해 열보다 좁아져 왼쪽으로 밀렸음).
                    Row(modifier = GlanceModifier.fillMaxSize()) {
                        for (i in 0 until 7) {
                            Box(
                                modifier = GlanceModifier.defaultWeight().fillMaxHeight(),
                                contentAlignment = Alignment.CenterEnd,
                            ) {
                                if (i < 6) {
                                    Spacer(modifier = GlanceModifier.width(1.dp).fillMaxHeight().background(gridColor))
                                }
                            }
                        }
                    }
                    // 달력 내용(세로선 위).
                    Column(modifier = GlanceModifier.fillMaxSize()) {
                        weeks.forEach { week ->
                            WeekRows(week, today, categories, tasks, textColor)
                            // 주와 주 사이 가로 격자 구분선.
                            GridDivider(gridColor)
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun GridDivider(color: Color) {
        Spacer(
            modifier =
                GlanceModifier.fillMaxWidth().height(1.dp).background(color),
        )
    }

    @Composable
    private fun ColumnScope.WeekRows(
        week: List<LocalDay?>,
        today: LocalDay,
        categories: List<WidgetCategory>,
        tasks: List<WidgetTask>,
        textColor: Color,
    ) {
        // 한 주 = 하나의 균등 높이 밴드. 그 안에서 날짜 숫자 행과 일정 바 행을 위에서부터 쌓아,
        // 바가 자기 주(週)의 날짜 아래에 붙는다. (예전엔 모든 행이 한 Column의 형제로 균등 분배돼서
        // 바 행이 날짜 행들 '사이'의 독립 밴드처럼 떠 보이는 버그가 있었다.)
        Box(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
            Column(modifier = GlanceModifier.fillMaxSize()) {
                // 날짜 숫자 행 — 셀 가운데 정렬(예전 CenterEnd라 세로 격자선에 붙던 문제 수정).
                Row(modifier = GlanceModifier.fillMaxWidth()) {
                    week.forEach { day ->
                        Box(
                            modifier = GlanceModifier.defaultWeight(),
                            contentAlignment = Alignment.Center,
                        ) {
                            if (day != null) {
                                val isToday = day == today
                                Text(
                                    text = day.day.toString(),
                                    style =
                                        TextStyle(
                                            fontSize = 14.sp,
                                            fontWeight = if (isToday) FontWeight.Bold else FontWeight.Normal,
                                            color =
                                                ColorProvider(
                                                    if (isToday) Color(WIDGET_ACCENT_ARGB) else textColor
                                                ),
                                        ),
                                )
                            }
                        }
                    }
                }

                // 겹침 패킹된 일정 막대/블록 행 — 날짜 행 바로 아래에 고정 높이로 쌓는다.
                val bars = collectBarsForWeek(tasks, week)
                val maxRow = bars.maxOfOrNull { it.second } ?: -1
                for (rowSlot in 0..maxRow) {
                    Row(modifier = GlanceModifier.fillMaxWidth().padding(top = 1.dp)) {
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
                                            .height(14.dp)
                                            .padding(horizontal = 1.dp)
                                            .background(if (entry.isBar) color else color.copy(alpha = 0.25f)),
                                    contentAlignment = Alignment.CenterStart,
                                ) {
                                    if (showLabel) {
                                        Text(
                                            text = entry.task.title,
                                            maxLines = 1,
                                            style =
                                                TextStyle(
                                                    fontSize = 10.sp,
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

            // 오늘 칸 흰색 테두리 하이라이트 — 속이 빈 4선 프레임이라 안의 날짜/바를 가리지 않는다.
            if (week.any { it == today }) {
                Row(modifier = GlanceModifier.fillMaxSize()) {
                    week.forEach { day ->
                        if (day == today) {
                            Column(modifier = GlanceModifier.defaultWeight().fillMaxHeight()) {
                                Spacer(modifier = GlanceModifier.fillMaxWidth().height(2.dp).background(Color.White))
                                Row(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                                    Spacer(modifier = GlanceModifier.width(2.dp).fillMaxHeight().background(Color.White))
                                    Spacer(modifier = GlanceModifier.defaultWeight())
                                    Spacer(modifier = GlanceModifier.width(2.dp).fillMaxHeight().background(Color.White))
                                }
                                Spacer(modifier = GlanceModifier.fillMaxWidth().height(2.dp).background(Color.White))
                            }
                        } else {
                            Spacer(modifier = GlanceModifier.defaultWeight())
                        }
                    }
                }
            }
        }
    }
}
