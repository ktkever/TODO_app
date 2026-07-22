package com.example.todo_app.widget

import android.content.Context
import android.content.Intent
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
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.Column
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

// 3x2 TODO 위젯 — 카테고리 토글(좌상단) / 투명도 순환 / + 퀵애드(우상단) / 빈 영역 탭 시 앱 열림.
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

        val addIntent =
            Intent(context, QuickAddActivity::class.java).apply {
                putExtra("categoryName", target.name)
                putExtra("isToday", target.id == "today")
                putExtra("categoryId", if (target.isCustom) target.id else null as String?)
            }
        val pickerIntent = Intent(context, CategoryPickerActivity::class.java)

        Box(
            modifier =
                GlanceModifier.fillMaxSize()
                    .background(Color.White.copy(alpha = alpha))
                    .clickable(
                        onClick =
                            homeWidgetActionStartActivity<MainActivity>(context)
                    ),
        ) {
            Column(modifier = GlanceModifier.fillMaxSize().padding(8.dp)) {
                Row(modifier = GlanceModifier.fillMaxWidth()) {
                    Text(
                        text = target.name,
                        maxLines = 1,
                        style = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.Bold),
                        modifier =
                            GlanceModifier.defaultWeight()
                                .clickable(onClick = actionStartActivity(pickerIntent)),
                    )
                    Text(
                        text = "${(alpha * 100).toInt()}%",
                        style =
                            TextStyle(fontSize = 11.sp, color = ColorProvider(Color.Gray)),
                        modifier =
                            GlanceModifier.padding(horizontal = 4.dp)
                                .clickable(actionRunCallback<CycleOpacityAction>()),
                    )
                    Text(
                        text = "+",
                        style = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Bold),
                        modifier =
                            GlanceModifier.padding(horizontal = 2.dp)
                                .clickable(onClick = actionStartActivity(addIntent)),
                    )
                }
                Spacer(modifier = GlanceModifier.height(4.dp))
                if (tasks.isEmpty()) {
                    Text(
                        text = "할 일 없음",
                        style =
                            TextStyle(fontSize = 12.sp, color = ColorProvider(Color.Gray)),
                    )
                } else {
                    tasks.forEach { t ->
                        Text(text = "· ${t.title}", maxLines = 1, style = TextStyle(fontSize = 12.sp))
                    }
                }
            }
        }
    }
}

class CycleOpacityAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val prefs = widgetPrefs(context)
        val next = (prefs.getInt(KEY_OPACITY_INDEX, 0) + 1) % OPACITY_STEPS.size
        prefs.edit().putInt(KEY_OPACITY_INDEX, next).apply()
        TodoWidget().update(context, glanceId)
    }
}
