import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'categoryId': categoryId,
        'isToday': isToday,
        'startDate':
            startDate != null ? Timestamp.fromDate(startDate!) : null,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'repeatType': repeatType.name,
        'repeatIntervalDays': repeatIntervalDays,
        'reminderEnabled': reminderEnabled,
        'memo': memo,
      };

  factory Task.fromMap(Map<String, dynamic> data) => Task(
        id: data['id'] as String,
        title: data['title'] as String? ?? '',
        isCompleted: data['isCompleted'] as bool? ?? false,
        categoryId: data['categoryId'] as String?,
        isToday: data['isToday'] as bool? ?? false,
        startDate: (data['startDate'] as Timestamp?)?.toDate(),
        dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
        repeatType: RepeatType.values.firstWhere(
          (r) => r.name == data['repeatType'],
          orElse: () => RepeatType.none,
        ),
        repeatIntervalDays: data['repeatIntervalDays'] as int? ?? 1,
        reminderEnabled: data['reminderEnabled'] as bool? ?? false,
        memo: data['memo'] as String? ?? '',
      );
}
