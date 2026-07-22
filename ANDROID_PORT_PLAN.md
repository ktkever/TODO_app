# Android 포팅 구현 계획서

작성일: 2026-07-06
목표: 현재 Windows 데스크톱 앱(Flutter)을 **동일 코드베이스**로 Android에서도 정상 동작하도록 만든다.
(CLAUDE.md §1 "2차 타깃: Android"에 해당하는 단계)

---

## 0. 현재 상태 점검 결과

이미 되어 있는 것 (추가 작업 불필요):

- `android/` 플랫폼 폴더 이미 존재 (`flutter create` 시점에 생성됨).
- Firebase Android 설정 이미 완료: `android/app/google-services.json` 존재,
  `firebase_options.dart`에 `android` 케이스 이미 등록됨, Gradle에
  `com.google.gms.google-services` 플러그인 이미 적용됨.
- Firestore 데이터 모델/서비스(`firestore_service.dart`)는 플랫폼 중립적이라 그대로 재사용 가능.
- 익명 인증(`firebase_auth`) 로직도 플랫폼 중립적.

즉, **Firebase 연동 자체는 새로 할 일이 없다.** 문제는 전부 "데스크톱 전용 UI/플러그인"과
"고정 3단 레이아웃"에서 나온다.

---

## 1. 막히는 지점 (Blocking issues)

### 1.1 데스크톱 전용 플러그인의 무조건 호출 → Android에서 크래시/에러 가능성

- [main.dart](lib/main.dart#L15): `windowManager.ensureInitialized()`,
  `windowManager.waitUntilReadyToShow()`, `acrylic.Window.initialize()`를
  플랫폼 분기 없이 항상 호출.
- `window_manager`, `flutter_acrylic` 패키지는 Windows/macOS/Linux 데스크톱 전용이며
  Android를 지원하지 않음.
- [home_screen.dart](lib/screens/home_screen.dart#L114-L159)의 `_enterWidgetMode`/`_exitWidgetMode`도
  같은 패키지를 직접 호출.

**해결 방향**: `Platform.isWindows`(또는 `!kIsWeb && Platform.isAndroid` 역분기)로 감싸서
데스크톱 계열에서만 초기화·호출되도록 가드.

### 1.2 3단 고정 레이아웃이 폰 화면에 안 맞음

- [home_screen.dart:443-490](lib/screens/home_screen.dart#L443-L490): `Row`로
  좌측 TaskSidebar(고정 220px, [task_sidebar.dart:43](lib/widgets/task_sidebar.dart#L43)) —
  중앙 콘텐츠 — 우측 상세패널(고정 300px)을 항상 동시에 나란히 배치.
- 일반적인 폰 화면 폭(360~430dp)에서는 이 셋을 동시에 다 넣을 공간이 없음.

**결정된 방향** (화면 폭 브레이크포인트, 예: 600dp 기준으로 분기):
- **폭 좁음(폰)**:
  - 좌측 TaskSidebar → 상시 표시하지 않고, 중앙 화면 상단의 버튼으로 여는 `Drawer`(또는
    `endDrawer`)로 전환. `Scaffold.drawer` + `AppBar`의 메뉴 버튼으로 열고 닫는다.
  - 우측 상세패널(DetailPanel) → 슬라이드 패널이 아니라 task를 선택했을 때
    `Navigator.push`로 **전체화면**으로 전환. 뒤로가기(< 또는 시스템 백)로 복귀.
- **폭 넓음(태블릿 가로/데스크톱)**: 기존 3단 레이아웃(사이드바 상시 표시 + 상세패널 슬라이드) 그대로 유지.

### 1.3 "바탕화면 위젯 모드" 기능은 Windows 전용 개념

- [task_sidebar.dart](lib/widgets/task_sidebar.dart)의 위젯 모드 진입 버튼,
  [desktop_widget_shell.dart](lib/widgets/desktop_widget_shell.dart) 전체(프레임리스 창 드래그/리사이즈)는
  Windows 창 관리 API에 의존 → Android 개념 자체가 다름(홈스크린 위젯은 별도 네이티브 구현 필요, 범위 밖).

**해결 방향**: 이번 포팅 범위에서는 제외. Android에서는 해당 버튼을 숨김 처리만 한다.
(홈스크린 위젯을 원하면 별도 기획/작업으로 분리 — App Widget은 Flutter 위젯과 무관한 완전히 다른 네이티브 기능)

### 1.4 폰트: `Malgun Gothic`

- [main.dart:79,87](lib/main.dart#L79): `fontFamily: 'Malgun Gothic'`은 Windows 시스템 폰트.
  Android에는 없으므로 크래시는 안 나지만 자동으로 기본 폰트(Roboto 계열)로 대체됨 → 한글 표기가
  달라 보일 수 있음.

**해결 방향**: 우선순위 낮음. 필요 시 이후 단계에서 Noto Sans KR 등을 asset 폰트로 번들링해서
플랫폼별로 통일. 지금 단계에서는 폴백 허용하고 넘어가도 무방(요청 시 진행).

### 1.5 릴리스 빌드 시 인터넷 권한

- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)에 `INTERNET` 권한이
  명시돼 있지 않음. 디버그 빌드는 Flutter 툴이 자동으로 추가해주지만,
  **release APK/AAB는 명시적 선언이 없으면 Firestore 네트워크 요청이 실패**한다.

**해결 방향**: `<uses-permission android:name="android.permission.INTERNET"/>` 추가.

### 1.6 applicationId가 예시값 그대로

- `android/app/build.gradle.kts`의 `applicationId = "com.example.todo_app"` —
  `flutter create` 기본값. 스토어 배포 전에는 고유 ID로 변경 필요하나, 지금 단계(로컬 실행/테스트)에서는
  급하지 않음.

**해결 방향**: 우선순위 낮음. 스토어 배포 시점에 결정.

---

## 2. 구현 단계 (작게 쪼개서 진행)

| 단계 | 내용 | 확인 방법 |
| --- | --- | --- |
| **A** | `main.dart`/`home_screen.dart`에서 `window_manager`/`flutter_acrylic` 호출을 데스크톱 전용 분기로 감싸기 | `flutter run -d windows`로 기존 동작 그대로인지 먼저 확인 → 이후 Android 에뮬레이터에서 크래시 없이 앱이 뜨는지 확인 |
| **B** | `AndroidManifest.xml`에 INTERNET 권한 추가 | 에뮬레이터에서 로그인 후 Firestore 실시간 동기화 확인 |
| **C** | 반응형 레이아웃 분기 도입: 좁은 화면은 좌측 사이드바를 버튼으로 여는 Drawer로, 우측 상세패널은 task 선택 시 전체화면 push로 전환 / 넓은 화면(태블릿 가로·데스크톱)은 기존 3단 유지 | Android 에뮬레이터(폰 크기)와 `flutter run -d windows`(창 좁게/넓게) 양쪽에서 확인 |
| **D** | 위젯 모드 진입 버튼을 데스크톱에서만 노출 | Android에서 버튼 안 보이는지, Windows에서는 그대로 보이는지 확인 |
| **E** | Android 실기기 또는 에뮬레이터로 전체 기능 회귀 테스트 (로그인, 할 일 CRUD, 카테고리, 달력 뷰, 다크모드, 드래그 정렬) | 수동 테스트 체크리스트로 진행 |
| **F** (선택, 우선순위 낮음) | 폰트 통일, applicationId 변경, 앱 아이콘 교체 | 스토어 배포 준비 시점에 별도 진행 |

**진행 원칙**: CLAUDE.md 원칙대로 A→B→C→D 순서로 하나씩 끝내고 매번 실기기/에뮬레이터로 확인 후 다음 단계로 넘어간다.
C(반응형 레이아웃)가 가장 손이 많이 가는 작업이므로, 그 전에 A/B로 "일단 뜨는지"부터 확인하는 순서다.

---

## 3. 이번 범위에서 하지 않는 것

- ~~홈스크린 위젯(Android App Widget)~~ → **§4에서 구현 완료** (2026-07-22). 아래 참고.
- 푸시 알림 백엔드(§6과 동일하게 기존에도 범위 밖).
- 스토어(Play Console) 배포 설정(서명, 아이콘, 스토어 등록 정보).

---

## 4. 홈스크린 위젯 (Android App Widget) — 구현 완료 (2026-07-22)

당초 §1.3 / §3에서 "완전히 다른 네이티브 기능이라 별도 기획 필요"로 미뤄뒀던 항목을 실제로 구현했다.
Windows의 "바탕화면 위젯 모드"(프레임리스 창)와는 무관한, **안드로이드 네이티브 App Widget**이다.
Flutter 화면 코드는 재사용하지 않고, `home_widget` 패키지 + **Jetpack Glance**(Compose 기반 위젯 UI)로
네이티브에서 별도 렌더링한다.

### 4.1 제공하는 위젯 2종

| 위젯 | 크기 | 내용 | 진입 클래스 |
| --- | --- | --- | --- |
| **할 일 목록 위젯** | 3x2 | '오늘 할일' 목록을 표시. 상단 "+" 버튼으로 퀵애드, 카테고리 이름 탭으로 대상 카테고리 변경 | `TodoWidget` / `TodoWidgetReceiver` |
| **달력 위젯** | 4x6 | 이번 달 달력에 기간/단일 일정을 카테고리 색으로 표시 | `CalendarWidget` / `CalendarWidgetReceiver` |

위젯 정보(XML)는 [todo_widget_info.xml](android/app/src/main/res/xml/todo_widget_info.xml),
[calendar_widget_info.xml](android/app/src/main/res/xml/calendar_widget_info.xml)에 정의. `updatePeriodMillis=0`으로
OS 자동 갱신은 끄고, 앱/WorkManager가 갱신을 주도한다.

### 4.2 데이터 흐름 (앱 → 위젯)

1. 앱이 켜져 있는 동안 [home_screen.dart](lib/screens/home_screen.dart)의 Firestore 스트림 리스너가
   갱신될 때마다 `_syncHomeWidget()` → [HomeWidgetService.syncSnapshot()](lib/services/home_widget_service.dart#L29) 호출.
2. `syncSnapshot()`은 `Task.toWidgetMap()` / `Category.toWidgetMap()`([task.dart](lib/models/task.dart), [category.dart](lib/models/category.dart))로
   **위젯 전용 경량 JSON**을 만든다. Firestore `Timestamp` 대신 epoch millis, 색상은 ARGB int로 직렬화 —
   네이티브(Kotlin `org.json`)에서 바로 파싱할 수 있게 하기 위함.
3. `HomeWidget.saveWidgetData('tasks_json' / 'categories_json', ...)`로 SharedPreferences에 캐시 후
   `updateWidget()`으로 두 위젯을 다시 그린다.
4. 네이티브 쪽 [WidgetDataSync.kt](android/app/src/main/kotlin/com/example/todo_app/widget/WidgetDataSync.kt)가
   그 JSON을 읽어 Glance UI(할 일 목록·달력)를 구성한다.

앱이 꺼져 있을 때를 위한 백업 경로로 [WidgetRefreshWorker.kt](android/app/src/main/kotlin/com/example/todo_app/widget/WidgetRefreshWorker.kt) +
[WidgetSyncScheduler.kt](android/app/src/main/kotlin/com/example/todo_app/widget/WidgetSyncScheduler.kt)가
WorkManager 주기 작업으로 네이티브에서 Firestore/Auth를 직접 읽어 캐시를 갱신한다(빌드 의존성 `firebase-bom`, `work-runtime-ktx`).

### 4.3 위젯 → 앱 (상호작용)

- **"+" 퀵애드**: 위젯의 + 버튼 → [QuickAddActivity.kt](android/app/src/main/kotlin/com/example/todo_app/widget/QuickAddActivity.kt)
  (초경량 다이얼로그 테마 `QuickAddTheme`, [activity_quick_add.xml](android/app/src/main/res/layout/activity_quick_add.xml))에서
  제목 입력 → `homewidget://addtask?title=...&isToday=...&categoryId=...` 브로드캐스트 발송.
- 이 브로드캐스트는 `es.antonborri.home_widget.HomeWidgetBackgroundReceiver`(AndroidManifest 등록)가 받아
  Dart **헤드리스 콜백** [widgetBackgroundCallback](lib/services/home_widget_service.dart#L59)을 기동 → Firebase 초기화 후
  현재 로그인 사용자로 `FirestoreService.addTask()` 실행. 앱을 열지 않고도 할 일이 추가된다.
- **카테고리 변경**: 위젯의 카테고리 이름 탭 → [CategoryPickerActivity.kt](android/app/src/main/kotlin/com/example/todo_app/widget/CategoryPickerActivity.kt)에서
  캐시된 카테고리 목록을 다이얼로그로 띄워 선택. 선택 결과는 위젯의 대상 카테고리로 저장된다.
- 위젯 본체 탭 → AndroidManifest의 `home_widget.action.LAUNCH` 인텐트필터로 앱 실행.

### 4.4 빌드 설정 변경 (Glance/Compose 도입에 따른)

- [settings.gradle.kts](android/settings.gradle.kts) / [app/build.gradle.kts](android/app/build.gradle.kts):
  `org.jetbrains.kotlin.plugin.compose` 플러그인 추가(Kotlin 버전 2.3.20에 맞춤), `buildFeatures { compose = true }`,
  `androidx.glance:glance-appwidget`, `androidx.work:work-runtime-ktx`, `firebase-bom(34.16.0)` + firestore/auth 의존성.
- [pubspec.yaml](pubspec.yaml): `home_widget: ^0.9.3` 추가.
- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml): 위젯 리시버 2종, 백그라운드 리시버,
  QuickAdd/CategoryPicker 액티비티, LAUNCH 인텐트필터, 위젯 설명 문자열([strings.xml](android/app/src/main/res/values/strings.xml)) 등록.
- [gradle.properties](android/gradle.properties): `kotlin.incremental=false` — 프로젝트(D:)와 pub 캐시(C:) 드라이브가 달라
  Kotlin 증분 컴파일러가 "different roots"로 죽는 Windows 멀티 드라이브 버그 우회.
- [task_list_view.dart](lib/widgets/task_list_view.dart) / [grouped_task_list_view.dart](lib/widgets/grouped_task_list_view.dart):
  할 일 추가 입력행을 `SafeArea(top: false)`로 감싸 안드로이드 하단 제스처 바와 겹치지 않게 처리.

### 4.5 남은 개선 여지 (알려진 한계)

- 위젯에서 추가한 할 일은 `order=0` 고정이라 같은 카테고리 맨 앞에 올 수 있음
  (`home_widget_service.dart`의 `ponytail:` 주석 참고). 필요 시 캐시 JSON에서 max order 계산으로 개선.
- `applicationId`가 여전히 `com.example.todo_app`(예시값). 스토어 배포 시 변경 필요(§1.6).
- home_widget 패키지가 아직 Flutter Built-in Kotlin(KGP)으로 마이그레이션되지 않아 릴리스 빌드 시 경고 발생.
  현재 빌드/동작에는 영향 없음.
