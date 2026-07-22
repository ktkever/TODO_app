import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';

class GroupedTaskListView extends StatelessWidget {
  final List<Task> tasks;
  final List<Category> customCategories;
  final String categoryName;
  final ValueChanged<String> onTaskToggled;
  final ValueChanged<Task> onTaskSelected;
  final void Function(String title, {String? categoryId}) onAddTask;
  final ValueChanged<String> onTaskDeleted;
  final ValueChanged<List<Task>> onTasksReordered;
  final bool hideCompleted;
  final VoidCallback onToggleHideCompleted;
  final String? selectedTaskId;
  final VoidCallback? onSuggestTasks;

  const GroupedTaskListView({
    super.key,
    required this.tasks,
    required this.customCategories,
    required this.categoryName,
    required this.onTaskToggled,
    required this.onTaskSelected,
    required this.onAddTask,
    required this.onTaskDeleted,
    required this.onTasksReordered,
    required this.hideCompleted,
    required this.onToggleHideCompleted,
    this.selectedTaskId,
    this.onSuggestTasks,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0078D4),
                  ),
                ),
              ),
              if (onSuggestTasks != null)
                IconButton(
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  tooltip: '작업 제안',
                  color: AppColors.of(context).textMuted,
                  onPressed: onSuggestTasks,
                ),
              IconButton(
                icon: Icon(
                  hideCompleted ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                tooltip: hideCompleted ? '완료 항목 표시' : '완료 항목 숨기기',
                color: AppColors.of(context).textMuted,
                onPressed: onToggleHideCompleted,
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Text(
                    '할 일이 없습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _TaskGroup(
                      key: ValueKey(group.category.id),
                      category: group.category,
                      tasks: group.tasks,
                      selectedTaskId: selectedTaskId,
                      onTaskToggled: onTaskToggled,
                      onTaskSelected: onTaskSelected,
                      onTaskDeleted: onTaskDeleted,
                      onTasksReordered: onTasksReordered,
                    );
                  },
                ),
        ),
        _AddTaskRow(customCategories: customCategories, onSubmit: onAddTask),
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
      groups.add(
        _GroupData(
          category: const Category(
            id: '_none',
            name: '카테고리 없음',
            type: CategoryType.custom,
          ),
          tasks: uncategorized,
        ),
      );
    }

    return groups;
  }
}

class _GroupData {
  final Category category;
  final List<Task> tasks;
  const _GroupData({required this.category, required this.tasks});
}

class _AddTaskRow extends StatefulWidget {
  final List<Category> customCategories;
  final void Function(String title, {String? categoryId}) onSubmit;

  const _AddTaskRow({required this.customCategories, required this.onSubmit});

  @override
  State<_AddTaskRow> createState() => _AddTaskRowState();
}

class _AddTaskRowState extends State<_AddTaskRow> {
  final _controller = TextEditingController();
  String? _selectedCategoryId;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text, categoryId: _selectedCategoryId);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final matching = widget.customCategories.where(
      (c) => c.id == _selectedCategoryId,
    );
    final selectedCategory = matching.isEmpty ? null : matching.first;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            const SizedBox(width: 34),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '할 일 추가',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            PopupMenuButton<String?>(
              tooltip: '카테고리 선택',
              onSelected: (id) => setState(() => _selectedCategoryId = id),
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('카테고리 없음')),
                ...widget.customCategories.map(
                  (c) => PopupMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.color,
                          ),
                        ),
                        Text(c.name),
                      ],
                    ),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedCategory?.color ?? colors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedCategory?.name ?? '카테고리 없음',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskGroup extends StatelessWidget {
  final Category category;
  final List<Task> tasks;
  final String? selectedTaskId;
  final ValueChanged<String> onTaskToggled;
  final ValueChanged<Task> onTaskSelected;
  final ValueChanged<String> onTaskDeleted;
  final ValueChanged<List<Task>> onTasksReordered;

  const _TaskGroup({
    super.key,
    required this.category,
    required this.tasks,
    required this.selectedTaskId,
    required this.onTaskToggled,
    required this.onTaskSelected,
    required this.onTaskDeleted,
    required this.onTasksReordered,
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
              const Icon(
                Icons.label_outline,
                size: 14,
                color: Color(0xFF0078D4),
              ),
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
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          buildDefaultDragHandles: false,
          onReorderItem: (oldIndex, newIndex) {
            final reordered = List<Task>.from(tasks);
            final moved = reordered.removeAt(oldIndex);
            reordered.insert(newIndex, moved);
            onTasksReordered(reordered);
          },
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _TaskItem(
              key: ValueKey(task.id),
              index: index,
              task: task,
              isSelected: task.id == selectedTaskId,
              onToggle: () => onTaskToggled(task.id),
              onTap: () => onTaskSelected(task),
              onDelete: () => onTaskDeleted(task.id),
            );
          },
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  final int index;
  final Task task;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TaskItem({
    super.key,
    required this.index,
    required this.task,
    required this.isSelected,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ReorderableDragStartListener(
      index: index,
      child: Material(
        color: isSelected ? colors.itemSelectedBg : Colors.transparent,
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
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? AppColors.accent
                            : colors.textMuted,
                        width: 2,
                      ),
                      color: task.isCompleted
                          ? AppColors.accent
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 17, color: Colors.white)
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
                            ? colors.textMuted
                            : colors.textPrimary,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  color: colors.textMuted,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
