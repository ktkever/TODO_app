import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final String categoryName;
  final ValueChanged<String> onTaskToggled;
  final ValueChanged<Task> onTaskSelected;
  final ValueChanged<String> onAddTask;
  final ValueChanged<String> onTaskDeleted;
  final ValueChanged<List<Task>> onTasksReordered;
  final bool hideCompleted;
  final VoidCallback onToggleHideCompleted;
  final String? selectedTaskId;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.categoryName,
    required this.onTaskToggled,
    required this.onTaskSelected,
    required this.onAddTask,
    required this.onTaskDeleted,
    required this.onTasksReordered,
    required this.hideCompleted,
    required this.onToggleHideCompleted,
    this.selectedTaskId,
  });

  @override
  Widget build(BuildContext context) {
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
        _AddTaskRow(onSubmit: onAddTask),
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Text(
                    '할 일이 없습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ),
      ],
    );
  }
}

class _AddTaskRow extends StatefulWidget {
  final ValueChanged<String> onSubmit;

  const _AddTaskRow({required this.onSubmit});

  @override
  State<_AddTaskRow> createState() => _AddTaskRowState();
}

class _AddTaskRowState extends State<_AddTaskRow> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
          IconButton(icon: const Icon(Icons.add, size: 20), onPressed: _submit),
        ],
      ),
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
                    width: 22,
                    height: 22,
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
