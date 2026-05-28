import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/task.dart';

class GroupedTaskListView extends StatelessWidget {
  final List<Task> tasks;
  final List<Category> customCategories;
  final ValueChanged<String> onTaskToggled;
  final ValueChanged<Task> onTaskSelected;
  final String? selectedTaskId;

  const GroupedTaskListView({
    super.key,
    required this.tasks,
    required this.customCategories,
    required this.onTaskToggled,
    required this.onTaskSelected,
    this.selectedTaskId,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Text(
            '계획 안된 일정',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0078D4),
            ),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Text(
                    '계획 안된 일정이 없습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _TaskGroup(
                      category: group.category,
                      tasks: group.tasks,
                      selectedTaskId: selectedTaskId,
                      onTaskToggled: onTaskToggled,
                      onTaskSelected: onTaskSelected,
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<_GroupData> _buildGroups() {
    final groups = <_GroupData>[];

    for (final cat in customCategories) {
      final catTasks = tasks.where((t) => t.categoryId == cat.id).toList();
      if (catTasks.isNotEmpty) {
        groups.add(_GroupData(category: cat, tasks: catTasks));
      }
    }

    // 카테고리 미지정 할 일
    final uncategorized = tasks.where((t) => t.categoryId == null).toList();
    if (uncategorized.isNotEmpty) {
      groups.add(_GroupData(
        category: const Category(
          id: '_none',
          name: '카테고리 없음',
          type: CategoryType.custom,
        ),
        tasks: uncategorized,
      ));
    }

    return groups;
  }
}

class _GroupData {
  final Category category;
  final List<Task> tasks;
  const _GroupData({required this.category, required this.tasks});
}

class _TaskGroup extends StatelessWidget {
  final Category category;
  final List<Task> tasks;
  final String? selectedTaskId;
  final ValueChanged<String> onTaskToggled;
  final ValueChanged<Task> onTaskSelected;

  const _TaskGroup({
    required this.category,
    required this.tasks,
    required this.selectedTaskId,
    required this.onTaskToggled,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Row(
            children: [
              const Icon(Icons.label_outline,
                  size: 14, color: Color(0xFF0078D4)),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0078D4),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${tasks.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => _TaskItem(
              task: task,
              isSelected: task.id == selectedTaskId,
              onToggle: () => onTaskToggled(task.id),
              onTap: () => onTaskSelected(task),
            )),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TaskItem({
    required this.task,
    required this.isSelected,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFEFF6FC) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? const Color(0xFF0078D4)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: task.isCompleted
                        ? const Color(0xFF0078D4)
                        : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: task.isCompleted
                          ? Colors.grey[400]
                          : Colors.grey[800],
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
