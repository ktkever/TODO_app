package com.example.todo_app.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.google.android.gms.tasks.Tasks
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import org.json.JSONArray
import org.json.JSONObject

// 앱이 완전히 종료된 상태에서도 위젯이 다른 기기의 변경사항을 반영하도록 주기적으로
// Firestore를 읽기 전용으로 폴링해 캐시를 갱신한다(쓰기는 항상 Dart 쪽에서만 수행 —
// home_widget_service.dart의 widgetBackgroundCallback 참고). WorkSyncScheduler가 등록/해제한다.
class WidgetRefreshWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val uid = FirebaseAuth.getInstance().currentUser?.uid
            // ponytail: 프로세스 갓 시작 직후라 Auth 세션이 아직 복원 안 됐을 수 있음 —
            // 이번 주기는 건너뛰고 다음(15분 후) 주기에 맡긴다.
            ?: return Result.success()

        return try {
            val db = FirebaseFirestore.getInstance()
            val tasksSnap =
                Tasks.await(db.collection("users").document(uid).collection("tasks").get())
            val categoriesSnap =
                Tasks.await(
                    db.collection("users").document(uid).collection("categories").get()
                )

            val tasksJson = JSONArray()
            for (doc in tasksSnap.documents) {
                val o = JSONObject()
                o.put("id", doc.id)
                o.put("title", doc.getString("title") ?: "")
                o.put("isCompleted", doc.getBoolean("isCompleted") ?: false)
                o.put("categoryId", doc.getString("categoryId"))
                o.put("isToday", doc.getBoolean("isToday") ?: false)
                o.put("startDateMillis", doc.getTimestamp("startDate")?.toDate()?.time)
                o.put("dueDateMillis", doc.getTimestamp("dueDate")?.toDate()?.time)
                o.put("order", doc.getLong("order") ?: 0L)
                tasksJson.put(o)
            }

            val categoriesJson = JSONArray()
            for (doc in categoriesSnap.documents) {
                val o = JSONObject()
                o.put("id", doc.id)
                o.put("name", doc.getString("name") ?: "")
                o.put("colorArgb", doc.getLong("color") ?: 0xFF767676)
                o.put("order", doc.getLong("order") ?: 0L)
                categoriesJson.put(o)
            }

            widgetPrefs(applicationContext)
                .edit()
                .putString(KEY_TASKS_JSON, tasksJson.toString())
                .putString(KEY_CATEGORIES_JSON, categoriesJson.toString())
                .apply()

            TodoWidget().updateAll(applicationContext)
            CalendarWidget().updateAll(applicationContext)
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }
}
