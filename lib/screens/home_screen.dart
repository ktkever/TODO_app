import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/dummy_data.dart';
import '../models/task.dart';
import '../widgets/detail_panel.dart';
import '../widgets/task_list_view.dart';
import '../widgets/task_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategoryId = 'today';
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = buildDummyTasks();
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  void _onTaskToggled(String taskId) {
    setState(() {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      task.isCompleted = !task.isCompleted;
    });
  }

  List<Task> get _filteredTasks {
    final allCategories = [...defaultCategories, ...dummyCustomCategories];
    final selected = allCategories.firstWhere((c) => c.id == _selectedCategoryId);

    return switch (selected.type) {
      CategoryType.today => _tasks.where((t) => t.isToday).toList(),
      CategoryType.planned => _tasks.where((t) => t.dueDate != null).toList(),
      CategoryType.unplanned => _tasks.where((t) => t.dueDate == null).toList(),
      CategoryType.all => List.from(_tasks),
      CategoryType.custom => _tasks.where((t) => t.categoryId == selected.id).toList(),
    };
  }

  String get _selectedCategoryName {
    final allCategories = [...defaultCategories, ...dummyCustomCategories];
    return allCategories.firstWhere((c) => c.id == _selectedCategoryId).name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          TaskSidebar(
            customCategories: dummyCustomCategories,
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: _onCategorySelected,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: TaskListView(
              tasks: _filteredTasks,
              categoryName: _selectedCategoryName,
              onTaskToggled: _onTaskToggled,
            ),
          ),
          const DetailPanel(),
        ],
      ),
    );
  }
}
