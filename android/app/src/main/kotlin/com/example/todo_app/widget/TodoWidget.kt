package com.example.todo_app.widget

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.example.todo_app.MainActivity
import com.example.todo_app.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity as homeWidgetActionStartActivity

// 3x2 TODO 위젯(다크 테마) — 카테고리 토글(좌상단, 아이콘+큰 글씨) / 투명도 순환 / + 퀵애드(우상단) /
// 빈 영역 탭 시 위젯에 선택된 카테고리로 앱이 열린다.
class TodoWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { GlanceContent(context, currentState()) }
    }

    @Composable
    private fun GlanceContent(context: Context, state: HomeWidgetGlanceState) {
        val prefs = state.preferences
        val categories = readCategories(prefs)
        val targets = toggleTargets(categories)
        val toggleIndex = prefs.getInt(KEY_TOGGLE_INDEX, 0).coerceIn(0, targets.size - 1)
        val target = targets[toggleIndex]
        val tasks =
            filterTasks(readTasks(prefs), target).filter { !it.isCompleted }.take(3)
        val opacityIndex =
            prefs.getInt(KEY_OPACITY_INDEX, 0).coerceIn(0, OPACITY_STEPS.size - 1)
        val alpha = OPACITY_STEPS[opacityIndex]

        val textColor = Color(WIDGET_TEXT_ARGB)
        val subTextColor = Color(WIDGET_SUBTEXT_ARGB)

        val addIntent =
            Intent(context, QuickAddActivity::class.java).apply {
                putExtra("categoryName", target.name)
                putExtra("isToday", target.id == "today")
                putExtra("categoryId", if (target.isCustom) target.id else null as String?)
            }
        val pickerIntent = Intent(context, CategoryPickerActivity::class.java)
        // 빈 영역 탭 → 위젯에 선택된 카테고리로 앱을 연다(홈스크린 위젯 딥링크).
        val openUri = Uri.parse("homewidget://open?target=${target.id}")

        Box(
            modifier =
                GlanceModifier.fillMaxSize()
                    .background(Color(WIDGET_BG_ARGB).copy(alpha = alpha))
                    .clickable(
                        onClick =
                            homeWidgetActionStartActivity<MainActivity>(context, openUri)
                    ),
        ) {
            Column(modifier = GlanceModifier.fillMaxSize().padding(8.dp)) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    // 좌상단 카테고리 선택 — 아이콘 + 큰 글씨, 탭하면 카테고리 피커.
                    Row(
                        modifier =
                            GlanceModifier.defaultWeight()
                                .clickable(onClick = actionStartActivity(pickerIntent)),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_widget_category),
                            contentDescription = "카테고리 선택",
                            colorFilter = ColorFilter.tint(ColorProvider(textColor)),
                            modifier = GlanceModifier.size(20.dp),
                        )
                        Spacer(modifier = GlanceModifier.width(6.dp))
                        Text(
                            text = target.name,
                            maxLines = 1,
                            style =
                                TextStyle(
                                    fontSize = 17.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = ColorProvider(textColor),
                                ),
                        )
                    }
                    Text(
                        text = "${(alpha * 100).toInt()}%",
                        style =
                            TextStyle(fontSize = 14.sp, color = ColorProvider(subTextColor)),
                        modifier =
                            GlanceModifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                .clickable(
                                    onClick =
                                        actionStartActivity(
                                            widgetActionIntent(context, "todo_opacity")
                                        )
                                ),
                    )
                    Text(
                        text = "+",
                        style =
                            TextStyle(
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Bold,
                                color = ColorProvider(textColor),
                            ),
                        modifier =
                            GlanceModifier.padding(horizontal = 6.dp)
                                .clickable(onClick = actionStartActivity(addIntent)),
                    )
                }
                Spacer(modifier = GlanceModifier.height(6.dp))
                if (tasks.isEmpty()) {
                    Text(
                        text = "할 일 없음",
                        style = TextStyle(fontSize = 13.sp, color = ColorProvider(subTextColor)),
                    )
                } else {
                    tasks.forEach { t ->
                        Text(
                            text = "· ${t.title}",
                            maxLines = 1,
                            style = TextStyle(fontSize = 13.sp, color = ColorProvider(textColor)),
                        )
                    }
                }
            }
        }
    }
}
