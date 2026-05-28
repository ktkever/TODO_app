import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/dummy_data.dart';
import '../models/task.dart';
import '../screens/calendar_screen.dart';
import '../widgets/detail_panel.dart';
import '../widgets/grouped_task_list_view.dart';
import '../widgets/task_list_view.dart';
import '../widgets/task_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategoryId = 'today';
  bool _isCalendarView = false;
  late List<Task> _tasks;
  Task? _selectedTask;

  @override
  void initState() {
    super.initState();
    _tasks = buildDummyTasks();
  }

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
  }

  List<Task> get _filteredTasks {
    final allCategories = [...defaultCategories, ...dummyCustomCategories];
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
    final allCategories = [...defaultCategories, ...dummyCustomCategories];
    return allCategories.firstWhere((c) => c.id == _selectedCategoryId).name;
  }

  Widget _buildMainContent() {
    if (_isCalendarView) {
      return CalendarScreen(
        tasks: _tasks,
        onTaskSelected: _onTaskSelected,
        selectedTaskId: _selectedTask?.id,
      );
    }

    // 사용자 지정 카테고리: 단일 카테고리이므로 그룹 헤더 없이 플랫 리스트
    final isCustom =
        dummyCustomCategories.any((c) => c.id == _selectedCategoryId);
    if (isCustom) {
      return TaskListView(
        tasks: _filteredTasks,
        categoryName: _selectedCategoryName,
        onTaskToggled: _onTaskToggled,
        onTaskSelected: _onTaskSelected,
        selectedTaskId: _selectedTask?.id,
      );
    }

    // 기본 카테고리 4개 모두 — 카테고리별 그룹화 뷰
    return GroupedTaskListView(
      tasks: _filteredTasks,
      customCategories: dummyCustomCategories,
      categoryName: _selectedCategoryName,
      onTaskToggled: _onTaskToggled,
      onTaskSelected: _onTaskSelected,
      selectedTaskId: _selectedTask?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          TaskSidebar(
            customCategories: dummyCustomCategories,
            selectedCategoryId: _selectedCategoryId,
            isCalendarView: _isCalendarView,
            onCategorySelected: _onCategorySelected,
            onCalendarToggle: _onCalendarToggle,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _buildMainContent()),
          // 슬라이드 상세 패널 — OverflowBox로 레이아웃 공간 고정, ClipRect로 시각 클리핑
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
                          onClose: () => setState(() => _selectedTask = null),
                          onTaskChanged: _onTaskChanged,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
