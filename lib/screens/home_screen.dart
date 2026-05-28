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
  const HomeScreen({super.key, this.useFirebase = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategoryId = 'today';
  bool _isCalendarView = false;
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

  void _onTaskToggled(String taskId) {
    setState(() {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      task.isCompleted = !task.isCompleted;
      if (widget.useFirebase) FirestoreService.instance.updateTask(task);
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

  // ── 필터 ─────────────────────────────────────────────────────

  List<Task> get _filteredTasks {
    final allCategories = [...defaultCategories, ..._customCategories];
    final selected =
        allCategories.firstWhere((c) => c.id == _selectedCategoryId);

    return switch (selected.type) {
      CategoryType.today => _tasks.where((t) => t.isToday).toList(),
      CategoryType.planned => _tasks.where((t) => t.dueDate != null).toList(),
      CategoryType.unplanned =>
        _tasks.where((t) => t.dueDate == null && t.startDate == null).toList(),
      CategoryType.all => List.from(_tasks),
      CategoryType.custom =>
        _tasks.where((t) => t.categoryId == selected.id).toList(),
    };
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
        onTaskSelected: _onTaskSelected,
        selectedTaskId: _selectedTask?.id,
      );
    }

    final isCustom = _customCategories.any((c) => c.id == _selectedCategoryId);
    if (isCustom) {
      return TaskListView(
        tasks: _filteredTasks,
        categoryName: _selectedCategoryName,
        onTaskToggled: _onTaskToggled,
        onTaskSelected: _onTaskSelected,
        selectedTaskId: _selectedTask?.id,
      );
    }

    return GroupedTaskListView(
      tasks: _filteredTasks,
      customCategories: _customCategories,
      categoryName: _selectedCategoryName,
      onTaskToggled: _onTaskToggled,
      onTaskSelected: _onTaskSelected,
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
