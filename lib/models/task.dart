enum RepeatType { none, daily, weekly, monthly, yearly, custom }

class Task {
  final String id;
  String title;
  bool isCompleted;
  String? categoryId;
  bool isToday;
  DateTime? startDate;
  DateTime? dueDate;
  RepeatType repeatType;
  int repeatIntervalDays;
  bool reminderEnabled;
  String memo;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.categoryId,
    this.isToday = false,
    this.startDate,
    this.dueDate,
    this.repeatType = RepeatType.none,
    this.repeatIntervalDays = 1,
    this.reminderEnabled = false,
    this.memo = '',
  });
}
