class Task {
  final String id;
  final String title;
  bool isCompleted;
  final String? categoryId;
  final bool isToday;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.categoryId,
    this.isToday = false,
    this.dueDate,
  });
}
