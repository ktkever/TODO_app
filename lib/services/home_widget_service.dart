import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../firebase_options.dart';
import '../models/category.dart';
import '../models/task.dart';
import 'firestore_service.dart';

// android/app/src/main/kotlin/.../widget/ 아래에 2단계에서 만들 위젯 리시버의 정규 클래스명.
const _todoWidgetReceiver = 'com.example.todo_app.widget.TodoWidgetReceiver';
const _calendarWidgetReceiver =
    'com.example.todo_app.widget.CalendarWidgetReceiver';

bool get isAndroidWidgetHost => !kIsWeb && Platform.isAndroid;

// Flutter 앱 ↔ 네이티브 홈스크린 위젯 사이의 데이터 동기화 및 위젯에서 시작된
// 백그라운드 작업(할 일 추가)을 담당한다. ANDROID_PORT_PLAN 홈스크린 위젯 계획 1단계.
class HomeWidgetService {
  HomeWidgetService._();

  // 앱이 켜져 있을 때 Firestore 스트림이 갱신될 때마다 호출 — 위젯 캐시를 최신 상태로 유지.
  static Future<void> syncSnapshot({
    required List<Task> tasks,
    required List<Category> categories,
  }) async {
    if (!isAndroidWidgetHost) return;

    final tasksJson = jsonEncode(tasks.map((t) => t.toWidgetMap()).toList());
    final categoriesJson =
        jsonEncode(categories.map((c) => c.toWidgetMap()).toList());

    await HomeWidget.saveWidgetData('tasks_json', tasksJson);
    await HomeWidget.saveWidgetData('categories_json', categoriesJson);
    await HomeWidget.updateWidget(qualifiedAndroidName: _todoWidgetReceiver);
    await HomeWidget.updateWidget(
        qualifiedAndroidName: _calendarWidgetReceiver);
  }

  // main()에서 1회 호출 — 위젯의 "+" 버튼이 이 콜백을 헤드리스 엔진으로 기동시킨다.
  static Future<void> registerBackgroundCallback() async {
    if (!isAndroidWidgetHost) return;
    await HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }

  // 위젯의 빈 영역 탭 등으로 앱이 열릴 때 전달되는 딥링크(homewidget://open?target=...).
  // 앱이 이미 떠 있을 때는 이 스트림으로, 콜드 스타트 때는 initialLaunchUri()로 들어온다.
  static Stream<Uri?> get launchUris =>
      isAndroidWidgetHost ? HomeWidget.widgetClicked : const Stream.empty();

  static Future<Uri?> initialLaunchUri() async {
    if (!isAndroidWidgetHost) return null;
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }
}

// 위젯에서 보낸 homewidget://addtask?title=...&isToday=...&categoryId=... 브로드캐스트를
// 처리하는 헤드리스 엔진 진입점. 반복 일정/정렬 순서 계산 등은 앱 UI에서 하는 것과
// 달리 생략한다 — 위젯에서 빠르게 한 줄 추가하는 용도이므로 order는 기본값(0)에 맡긴다.
// ponytail: order=0 고정이라 위젯에서 추가한 항목이 같은 카테고리 맨 앞에 올 수 있음,
// 거슬리면 나중에 캐시된 tasks_json으로 max order 계산 추가.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null || uri.host != 'addtask') return;
  final title = uri.queryParameters['title']?.trim();
  if (title == null || title.isEmpty) return;

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final user = FirebaseAuth.instance.currentUser ??
      await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
  if (user == null) return;

  FirestoreService.instance.bindUser(user.uid);
  await FirestoreService.instance.addTask(Task(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    title: title,
    isToday: uri.queryParameters['isToday'] == 'true',
    categoryId: uri.queryParameters['categoryId'],
  ));
}
