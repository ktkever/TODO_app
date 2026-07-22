import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../models/category.dart';
import '../models/dummy_data.dart';
import '../models/task.dart';
import '../screens/calendar_screen.dart';
import '../services/firestore_service.dart';
import '../services/home_widget_service.dart';
import '../widgets/desktop_widget_shell.dart';
import '../widgets/detail_panel.dart';
import '../widgets/grouped_task_list_view.dart';
import '../widgets/task_list_view.dart';
import '../widgets/task_sidebar.dart';

const _widgetOpacityPrefKey = 'widgetOpacity';
const _widgetBoundsPrefKey = 'widgetBounds'; // "x,y,w,h" 형식으로 저장

// 이 폭보다 좁으면(폰) 좌측 사이드바는 Drawer로, 상세패널은 전체화면으로 전환한다.
// 이 폭 이상(태블릿 가로/데스크톱)에서는 기존 3단 레이아웃을 그대로 쓴다.
const _wideBreakpoint = 600.0;

class HomeScreen extends StatefulWidget {
  final bool useFirebase;
  final VoidCallback? onLogout;
  const HomeScreen({
    super.key,
    this.useFirebase = false,
    this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategoryId = 'today';
  bool _isCalendarView = false;
  bool _hideCompleted = false;
  List<Task> _tasks = [];
  List<Category> _customCategories = [];
  Task? _selectedTask;
  bool _loading = true;

  bool _isWidgetMode = false;
  double _widgetOpacity = 1.0;
  Rect? _boundsBeforeWidgetMode;

  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<Category>>? _categoriesSub;

  @override
  void initState() {
    super.initState();
    if (widget.useFirebase) {
      _initFirestore();
    } else {
      _tasks = buildDummyTasks();
      _customCategories = List.from(dummyCustomCategories);
      _loading = false;
    }
  }

  Future<void> _initFirestore() async {
    final svc = FirestoreService.instance;

    // 실시간 스트림 구독
    _categoriesSub = svc.watchCategories().listen((cats) {
      if (mounted) {
        setState(() {
          _customCategories = cats;
          _loading = false;
        });
      }
      _syncHomeWidget();
    });

    _tasksSub = svc.watchTasks().listen((tasks) {
      if (mounted) setState(() => _tasks = tasks);
      _syncHomeWidget();
    });
  }

  // 앱이 켜져 있는 동안 Firestore 변경사항을 Android 홈스크린 위젯 캐시에 반영.
  void _syncHomeWidget() {
    HomeWidgetService.syncSnapshot(tasks: _tasks, categories: _customCategories);
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }

  // ── 이벤트 핸들러 ─────────────────────────────────────────────

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _isCalendarView = false;
      _selectedTask = null;
    });
  }

  void _onCalendarToggle() {
    setState(() {
      _isCalendarView = !_isCalendarView;
      _selectedTask = null;
    });
  }

  void _onToggleHideCompleted() {
    setState(() => _hideCompleted = !_hideCompleted);
  }

  // ── 바탕화면 위젯 모드 ────────────────────────────────────────

  Future<void> _enterWidgetMode() async {
    _boundsBeforeWidgetMode = await windowManager.getBounds();

    final prefs = await SharedPreferences.getInstance();
    final opacity = prefs.getDouble(_widgetOpacityPrefKey) ?? 1.0;
    final savedBounds = prefs.getString(_widgetBoundsPrefKey);
    final bounds = savedBounds != null
        ? _parseBounds(savedBounds)
        : const Rect.fromLTWH(100, 100, 380, 320);

    await windowManager.setTitleBarStyle(TitleBarStyle.hidden,
        windowButtonVisibility: false);
    await windowManager.setAsFrameless();
    await windowManager.setResizable(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setAlwaysOnBottom(true);
    // 창 전체를 균일하게 흐리는 setOpacity 대신, 창 자체를 픽셀 단위
    // 투명(per-pixel alpha)으로 바꾸고 배경 레이어만 알파를 조절한다.
    // (달력 격자/숫자/텍스트는 DesktopWidgetShell에서 별도로 항상 불투명하게 그림)
    await acrylic.Window.setEffect(effect: acrylic.WindowEffect.transparent);
    await windowManager.setBounds(bounds);

    setState(() {
      _isWidgetMode = true;
      _isCalendarView = true;
      _selectedTask = null;
      _widgetOpacity = opacity;
    });
  }

  Future<void> _exitWidgetMode() async {
    final bounds = await windowManager.getBounds();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_widgetBoundsPrefKey, _boundsToString(bounds));
    await prefs.setDouble(_widgetOpacityPrefKey, _widgetOpacity);

    await windowManager.setAlwaysOnBottom(false);
    await windowManager.setSkipTaskbar(false);
    await acrylic.Window.setEffect(effect: acrylic.WindowEffect.disabled);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    if (_boundsBeforeWidgetMode != null) {
      await windowManager.setBounds(_boundsBeforeWidgetMode!);
    }

    setState(() => _isWidgetMode = false);
  }

  void _onWidgetOpacityChanged(double opacity) {
    setState(() => _widgetOpacity = opacity);
  }

  String _boundsToString(Rect r) =>
      '${r.left},${r.top},${r.width},${r.height}';

  Rect _parseBounds(String s) {
    final parts = s.split(',').map(double.parse).toList();
    return Rect.fromLTWH(parts[0], parts[1], parts[2], parts[3]);
  }

  void _onTaskToggled(String taskId) {
    setState(() {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final completingNow = !task.isCompleted;
      task.isCompleted = completingNow;

      // 체크 해제 후 재체크를 반복해도 같은 회차에서 다음 일정이
      // 중복 생성되지 않도록 nextGenerated로 1회만 생성되게 막는다.
      Task? next;
      if (completingNow) {
        next = task.nextOccurrence(
          DateTime.now().microsecondsSinceEpoch.toString(),
        );
        if (next != null) task.nextGenerated = true;
      }

      if (widget.useFirebase) FirestoreService.instance.updateTask(task);

      if (next != null) {
        _tasks.add(next);
        if (widget.useFirebase) FirestoreService.instance.addTask(next);
      }
    });
  }

  void _onTaskSelected(Task task) {
    if (MediaQuery.sizeOf(context).width < _wideBreakpoint) {
      _pushDetailPanelFullScreen(task);
      return;
    }
    setState(() {
      _selectedTask = (_selectedTask?.id == task.id) ? null : task;
    });
  }

  // 좁은 화면(폰)에서는 상세패널을 슬라이드 패널 대신 전체화면으로 띄운다.
  void _pushDetailPanelFullScreen(Task task) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (routeContext) => Scaffold(
        body: SafeArea(
          child: DetailPanel(
            key: ValueKey(task.id),
            task: task,
            customCategories: _customCategories,
            onClose: () => Navigator.of(routeContext).pop(),
            onTaskChanged: _onTaskChanged,
          ),
        ),
      ),
    ));
  }

  void _onTaskChanged(Task updated) {
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == updated.id);
      if (idx != -1) _tasks[idx] = updated;
      _selectedTask = updated;
    });
    if (widget.useFirebase) FirestoreService.instance.updateTask(updated);
  }

  void _onAddTask(String title, {String? categoryId}) {
    final allCategories = [...defaultCategories, ..._customCategories];
    final selected =
        allCategories.firstWhere((c) => c.id == _selectedCategoryId);
    // 커스텀 카테고리 뷰에서는 그 카테고리로 고정. 기본 뷰(오늘 할일 등)에서는
    // 할일 추가 칸의 카테고리 선택 토글로 고른 값을 그대로 쓴다.
    final resolvedCategoryId =
        selected.type == CategoryType.custom ? selected.id : categoryId;

    // 같은 카테고리 내 맨 뒤에 붙도록 order 계산 (드래그로 재정렬된
    // 카테고리에 새 항목이 끼어들지 않게 함)
    final siblingOrders = _tasks
        .where((t) => t.categoryId == resolvedCategoryId)
        .map((t) => t.order);
    final nextOrder = siblingOrders.isEmpty
        ? 0
        : siblingOrders.reduce((a, b) => a > b ? a : b) + 1;

    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      isToday: selected.type == CategoryType.today,
      categoryId: resolvedCategoryId,
      order: nextOrder,
    );
    setState(() => _tasks.add(task));
    if (widget.useFirebase) FirestoreService.instance.addTask(task);
  }

  // '오늘 할일'에 아직 없는 작업들을 보여주고, +를 누르는 즉시 오늘 할일에 추가한다.
  Future<void> _showTaskSuggestionDialog() async {
    final candidates = _tasks.where((t) => !t.isToday).toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('작업 제안'),
          content: SizedBox(
            width: 360,
            height: 400,
            child: candidates.isEmpty
                ? const Center(child: Text('추가할 수 있는 작업이 없습니다.'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final task = candidates[index];
                      return ListTile(
                        title: Text(task.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: '오늘 할일에 추가',
                          onPressed: () {
                            _onAddTasksToToday({task.id});
                            setDialogState(() => candidates.removeAt(index));
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddTasksToToday(Set<String> taskIds) {
    setState(() {
      for (final task in _tasks) {
        if (taskIds.contains(task.id)) {
          task.isToday = true;
          if (widget.useFirebase) FirestoreService.instance.updateTask(task);
        }
      }
    });
  }

  void _onTasksReordered(List<Task> reordered) {
    setState(() {
      for (int i = 0; i < reordered.length; i++) {
        final t = reordered[i];
        if (t.order != i) {
          t.order = i;
          if (widget.useFirebase) FirestoreService.instance.updateTask(t);
        }
      }
    });
  }

  void _onAddCategory(Category category) {
    setState(() => _customCategories.add(category));
    if (widget.useFirebase) FirestoreService.instance.addCategory(category);
  }

  void _onReorderCategories(List<Category> reordered) {
    final updated = <Category>[];
    for (int i = 0; i < reordered.length; i++) {
      final cat = reordered[i];
      final withOrder = Category(
        id: cat.id,
        name: cat.name,
        type: cat.type,
        color: cat.color,
        order: i,
      );
      updated.add(withOrder);
      if (widget.useFirebase && cat.order != i) {
        FirestoreService.instance.updateCategory(withOrder);
      }
    }
    setState(() => _customCategories = updated);
  }

  void _onTaskDeleted(String taskId) {
    setState(() {
      _tasks.removeWhere((t) => t.id == taskId);
      if (_selectedTask?.id == taskId) _selectedTask = null;
    });
    if (widget.useFirebase) FirestoreService.instance.deleteTask(taskId);
  }

  void _onEditCategoryColor(Category updated) {
    setState(() {
      final idx = _customCategories.indexWhere((c) => c.id == updated.id);
      if (idx != -1) _customCategories[idx] = updated;
    });
    if (widget.useFirebase) FirestoreService.instance.updateCategory(updated);
  }

  void _onRenameCategory(Category updated) {
    setState(() {
      final idx = _customCategories.indexWhere((c) => c.id == updated.id);
      if (idx != -1) _customCategories[idx] = updated;
    });
    if (widget.useFirebase) FirestoreService.instance.updateCategory(updated);
  }

  void _onDeleteCategory(String categoryId) {
    setState(() {
      _customCategories.removeWhere((c) => c.id == categoryId);
      for (final task in _tasks.where((t) => t.categoryId == categoryId)) {
        task.categoryId = null;
        if (widget.useFirebase) FirestoreService.instance.updateTask(task);
      }
      if (_selectedCategoryId == categoryId) _selectedCategoryId = 'today';
    });
    if (widget.useFirebase) FirestoreService.instance.deleteCategory(categoryId);
  }

  // ── 필터 ─────────────────────────────────────────────────────

  List<Task> get _filteredTasks {
    final allCategories = [...defaultCategories, ..._customCategories];
    final selected =
        allCategories.firstWhere((c) => c.id == _selectedCategoryId);

    final List<Task> base = switch (selected.type) {
      CategoryType.today => _tasks.where((t) => t.isToday).toList(),
      CategoryType.planned => _tasks.where((t) => t.dueDate != null).toList(),
      CategoryType.unplanned =>
        _tasks.where((t) => t.dueDate == null && t.startDate == null).toList(),
      CategoryType.all => _tasks.toList(),
      CategoryType.custom =>
        _tasks.where((t) => t.categoryId == selected.id).toList(),
    };

    // 완료된 항목은 목록 맨 아래로 (where는 원래 순서를 유지하므로 안정 정렬 효과)
    final incomplete = _sortByOrder(base.where((t) => !t.isCompleted).toList());
    if (_hideCompleted) return incomplete;
    final completed = _sortByOrder(base.where((t) => t.isCompleted).toList());
    return [...incomplete, ...completed];
  }

  // task.order로 정렬하되, order가 같으면 원래 순서를 유지(안정 정렬).
  List<Task> _sortByOrder(List<Task> list) {
    final indexed = list.asMap().entries.toList();
    indexed.sort((a, b) {
      final byOrder = a.value.order.compareTo(b.value.order);
      return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  String get _selectedCategoryName {
    final allCategories = [...defaultCategories, ..._customCategories];
    return allCategories.firstWhere((c) => c.id == _selectedCategoryId).name;
  }

  // ── 중앙 메인 콘텐츠 ──────────────────────────────────────────

  Widget _buildMainContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isCalendarView) {
      return CalendarScreen(
        tasks: _tasks,
        customCategories: _customCategories,
        onTaskSelected: _onTaskSelected,
        selectedTaskId: _selectedTask?.id,
      );
    }

    final matchingCategories =
        _customCategories.where((c) => c.id == _selectedCategoryId);
    final selectedCategory =
        matchingCategories.isEmpty ? null : matchingCategories.first;
    if (selectedCategory != null) {
      return TaskListView(
        key: ValueKey(selectedCategory.id),
        tasks: _filteredTasks,
        category: selectedCategory,
        onRenameCategory: _onRenameCategory,
        onTaskToggled: _onTaskToggled,
        onTaskSelected: _onTaskSelected,
        onAddTask: _onAddTask,
        onTaskDeleted: _onTaskDeleted,
        onTasksReordered: _onTasksReordered,
        selectedTaskId: _selectedTask?.id,
        hideCompleted: _hideCompleted,
        onToggleHideCompleted: _onToggleHideCompleted,
      );
    }

    return GroupedTaskListView(
      tasks: _filteredTasks,
      customCategories: _customCategories,
      categoryName: _selectedCategoryName,
      onTaskToggled: _onTaskToggled,
      onTaskSelected: _onTaskSelected,
      hideCompleted: _hideCompleted,
      onToggleHideCompleted: _onToggleHideCompleted,
      onAddTask: _onAddTask,
      onTaskDeleted: _onTaskDeleted,
      onTasksReordered: _onTasksReordered,
      selectedTaskId: _selectedTask?.id,
      onSuggestTasks:
          _selectedCategoryId == 'today' ? _showTaskSuggestionDialog : null,
    );
  }

  Widget _buildFirebaseBanner() {
    if (widget.useFirebase) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFFFFF4CE),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 16, color: Color(0xFF8A6914)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '로컬 모드 — Firebase 미연결. flutterfire configure 후 재빌드하면 클라우드 동기화가 활성화됩니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A6914)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isWidgetMode) {
      return DesktopWidgetShell(
        opacity: _widgetOpacity,
        onOpacityChanged: _onWidgetOpacityChanged,
        onExit: _exitWidgetMode,
        child: CalendarScreen(
          tasks: _tasks,
          customCategories: _customCategories,
          onTaskSelected: _onTaskSelected,
          selectedTaskId: _selectedTask?.id,
        ),
      );
    }

    return MediaQuery.sizeOf(context).width < _wideBreakpoint
        ? _buildNarrowScaffold()
        : _buildWideScaffold();
  }

  // 폭 넓음(태블릿 가로/데스크톱): 사이드바 상시 표시 + 상세패널 슬라이드.
  Widget _buildWideScaffold() {
    final banner = _buildFirebaseBanner();
    return Scaffold(
      body: Column(
        children: [
          banner,
          Expanded(
            child: Row(
              children: [
                TaskSidebar(
                  customCategories: _customCategories,
                  selectedCategoryId: _selectedCategoryId,
                  isCalendarView: _isCalendarView,
                  onCategorySelected: _onCategorySelected,
                  onCalendarToggle: _onCalendarToggle,
                  onAddCategory: _onAddCategory,
                  onEditCategoryColor: _onEditCategoryColor,
                  onDeleteCategory: _onDeleteCategory,
                  onReorderCategories: _onReorderCategories,
                  onLogout: widget.onLogout,
                  onEnterWidgetMode: _enterWidgetMode,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: _buildMainContent()),
                ClipRect(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    width: _selectedTask != null ? 300 : 0,
                    child: OverflowBox(
                      maxWidth: 300,
                      minWidth: 0,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 300,
                        child: _selectedTask != null
                            ? DetailPanel(
                                key: ValueKey(_selectedTask!.id),
                                task: _selectedTask!,
                                customCategories: _customCategories,
                                onClose: () =>
                                    setState(() => _selectedTask = null),
                                onTaskChanged: _onTaskChanged,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 폭 좁음(폰): 사이드바는 버튼으로 여는 Drawer, 상세패널은 task 선택 시 전체화면.
  Widget _buildNarrowScaffold() {
    final banner = _buildFirebaseBanner();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCalendarView ? '달력' : _selectedCategoryName),
        actions: [
          IconButton(
            icon: Icon(_isCalendarView
                ? Icons.calendar_month
                : Icons.calendar_month_outlined),
            tooltip: '달력 전환',
            onPressed: _onCalendarToggle,
          ),
        ],
      ),
      drawer: Drawer(
        child: Builder(
          builder: (drawerContext) => TaskSidebar(
            customCategories: _customCategories,
            selectedCategoryId: _selectedCategoryId,
            isCalendarView: _isCalendarView,
            onCategorySelected: (id) {
              _onCategorySelected(id);
              Navigator.pop(drawerContext);
            },
            onCalendarToggle: () {
              _onCalendarToggle();
              Navigator.pop(drawerContext);
            },
            onAddCategory: _onAddCategory,
            onEditCategoryColor: _onEditCategoryColor,
            onDeleteCategory: _onDeleteCategory,
            onReorderCategories: _onReorderCategories,
            onLogout: widget.onLogout,
            onEnterWidgetMode: _enterWidgetMode,
          ),
        ),
      ),
      body: Column(
        children: [
          banner,
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }
}
