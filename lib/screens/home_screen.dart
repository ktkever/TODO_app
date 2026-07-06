import 'dart:async';

import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/dummy_data.dart';
import '../models/task.dart';
import '../screens/calendar_screen.dart';
import '../services/firestore_service.dart';
import '../widgets/detail_panel.dart';
import '../widgets/grouped_task_list_view.dart';
import '../widgets/task_list_view.dart';
import '../widgets/task_sidebar.dart';

class HomeScreen extends StatefulWidget {
  final bool useFirebase;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;
  const HomeScreen({
    super.key,
    this.useFirebase = false,
    this.isDarkMode = false,
    required this.onToggleDarkMode,
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

    // 첫 실행이면 더미 데이터로 초기 시드
    await svc.seedIfEmpty(buildDummyTasks(), List.from(dummyCustomCategories));

    // 실시간 스트림 구독
    _categoriesSub = svc.watchCategories().listen((cats) {
      if (mounted) {
        setState(() {
          _customCategories = cats;
          _loading = false;
        });
      }
    });

    _tasksSub = svc.watchTasks().listen((tasks) {
      if (mounted) setState(() => _tasks = tasks);
    });
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
    setState(() {
      _selectedTask = (_selectedTask?.id == task.id) ? null : task;
    });
  }

  void _onTaskChanged(Task updated) {
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == updated.id);
      if (idx != -1) _tasks[idx] = updated;
      _selectedTask = updated;
    });
    if (widget.useFirebase) FirestoreService.instance.updateTask(updated);
  }

  void _onAddTask(String title) {
    final allCategories = [...defaultCategories, ..._customCategories];
    final selected =
        allCategories.firstWhere((c) => c.id == _selectedCategoryId);
    final categoryId = selected.type == CategoryType.custom ? selected.id : null;

    // 같은 카테고리 내 맨 뒤에 붙도록 order 계산 (드래그로 재정렬된
    // 카테고리에 새 항목이 끼어들지 않게 함)
    final siblingOrders =
        _tasks.where((t) => t.categoryId == categoryId).map((t) => t.order);
    final nextOrder = siblingOrders.isEmpty
        ? 0
        : siblingOrders.reduce((a, b) => a > b ? a : b) + 1;

    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      isToday: selected.type == CategoryType.today,
      categoryId: categoryId,
      order: nextOrder,
    );
    setState(() => _tasks.add(task));
    if (widget.useFirebase) FirestoreService.instance.addTask(task);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Firebase 미연결 배너
          if (!widget.useFirebase)
            Material(
              color: const Color(0xFFFFF4CE),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, size: 16,
                        color: Color(0xFF8A6914)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '로컬 모드 — Firebase 미연결. flutterfire configure 후 재빌드하면 클라우드 동기화가 활성화됩니다.',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF8A6914)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  isDarkMode: widget.isDarkMode,
                  onToggleDarkMode: widget.onToggleDarkMode,
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
}
