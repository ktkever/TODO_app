package com.example.todo_app.widget

import android.app.Activity
import android.net.Uri
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import com.example.todo_app.R
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

// TODO 위젯의 "+" 버튼에서 여는 초경량 다이얼로그. 제목만 받아 홈위젯 백그라운드
// 브로드캐스트를 쏘고 닫는다 — 실제 Firestore 쓰기는 Dart의 widgetBackgroundCallback이 처리
// (home_widget_service.dart) 하므로 여기서는 Firestore를 직접 건드리지 않는다.
class QuickAddActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
        setContentView(R.layout.activity_quick_add)

        val categoryName = intent.getStringExtra("categoryName") ?: "오늘 할일"
        val isToday = intent.getBooleanExtra("isToday", false)
        val categoryId = intent.getStringExtra("categoryId")

        findViewById<TextView>(R.id.quick_add_category_label).text = "'$categoryName'에 추가"
        val titleField = findViewById<EditText>(R.id.quick_add_title)
        titleField.requestFocus()

        findViewById<Button>(R.id.quick_add_save).setOnClickListener {
            save(titleField.text.toString(), isToday, categoryId)
        }
    }

    private fun save(title: String, isToday: Boolean, categoryId: String?) {
        val trimmed = title.trim()
        if (trimmed.isNotEmpty()) {
            val uriBuilder =
                Uri.parse("homewidget://addtask")
                    .buildUpon()
                    .appendQueryParameter("title", trimmed)
                    .appendQueryParameter("isToday", isToday.toString())
            if (categoryId != null) uriBuilder.appendQueryParameter("categoryId", categoryId)
            HomeWidgetBackgroundIntent.getBroadcast(this, uriBuilder.build()).send()
        }
        finish()
    }
}
