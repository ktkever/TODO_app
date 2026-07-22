package com.example.todo_app.widget

import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.glance.appwidget.updateAll
import com.example.todo_app.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

// TODO 위젯 좌상단 카테고리 이름을 탭하면 뜨는 목록 피커 — 기본 4개 뷰 + 사용자 지정
// 카테고리를 한 번에 보여주고 탭 한 번으로 바로 선택한다(예전의 탭-순환 방식을 대체).
class CategoryPickerActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_category_picker)

        val prefs = widgetPrefs(this)
        val targets = toggleTargets(readCategories(prefs))
        val currentIndex = prefs.getInt(KEY_TOGGLE_INDEX, 0).coerceIn(0, targets.size - 1)

        val list = findViewById<LinearLayout>(R.id.category_picker_list)
        val density = resources.displayMetrics.density

        targets.forEachIndexed { index, target ->
            val row = LinearLayout(this)
            row.orientation = LinearLayout.HORIZONTAL
            row.gravity = Gravity.CENTER_VERTICAL
            row.setPadding((12 * density).toInt(), (10 * density).toInt(), (12 * density).toInt(), (10 * density).toInt())
            if (index == currentIndex) {
                row.setBackgroundColor(Color.parseColor("#F0F0F0"))
            }

            if (target.isCustom) {
                val color = colorForCategory(readCategories(prefs), target.id).toInt()
                val dot = View(this)
                val dotSize = (10 * density).toInt()
                dot.layoutParams = LinearLayout.LayoutParams(dotSize, dotSize).apply {
                    marginEnd = (8 * density).toInt()
                }
                dot.background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(color)
                }
                row.addView(dot)
            }

            val label = TextView(this)
            label.text = target.name
            label.textSize = 14f
            row.addView(label)

            row.setOnClickListener {
                prefs.edit().putInt(KEY_TOGGLE_INDEX, index).apply()
                CoroutineScope(Dispatchers.Main).launch {
                    TodoWidget().updateAll(applicationContext)
                    finish()
                }
            }

            list.addView(row)
        }
    }
}
