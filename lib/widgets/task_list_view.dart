import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final String categoryName;
  final ValueChanged<String> onTaskToggled;
  final ValueChanged<Task> onTaskSelected;
  final ValueChanged<String> onAddTask;
  final String? selectedTaskId;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.categoryName,
    required this.onTaskToggled,
    required this.onTaskSelected,
    required this.onAddTask,
    this.selectedTaskId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Text(
            categoryName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0078D4),
            ),
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
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskItem(
                      task: task,
                      isSelected: task.id == selectedTaskId,
                      onToggle: () => onTaskToggled(task.id),
                      onTap: () => onTaskSelected(task),
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
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: _submit,
          ),
        ],
      ),
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
