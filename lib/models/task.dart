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
  bool nextGenerated;
  int order;

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
    this.nextGenerated = false,
    this.order = 0,
  });

  // Android 홈스크린 위젯 캐시용 — Firestore Timestamp 대신 epoch millis를 쓴다
  // (위젯은 Kotlin에서 org.json으로 파싱하므로 Timestamp 객체를 그대로 넘길 수 없음).
  Map<String, dynamic> toWidgetMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'categoryId': categoryId,
        'isToday': isToday,
        'startDateMillis': startDate?.millisecondsSinceEpoch,
        'dueDateMillis': dueDate?.millisecondsSinceEpoch,
        'order': order,
      };

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
        'nextGenerated': nextGenerated,
        'order': order,
      };

  // 반복 설정에 따라 다음 회차 할 일을 만들어 반환. 반복 없음이거나
  // 기한이 없거나 이미 다음 회차를 생성한 적이 있으면(체크 해제 후 재체크로
  // 중복 생성되는 것을 방지) null.
  Task? nextOccurrence(String newId) {
    if (repeatType == RepeatType.none || dueDate == null || nextGenerated) {
      return null;
    }

    DateTime advance(DateTime d) => switch (repeatType) {
          RepeatType.daily => d.add(const Duration(days: 1)),
          RepeatType.weekly => d.add(const Duration(days: 7)),
          RepeatType.monthly => DateTime(d.year, d.month + 1, d.day),
          RepeatType.yearly => DateTime(d.year + 1, d.month, d.day),
          RepeatType.custom => d.add(Duration(days: repeatIntervalDays)),
          RepeatType.none => d,
        };

    return Task(
      id: newId,
      title: title,
      categoryId: categoryId,
      // isToday를 유지 — '오늘 할일'로 표시해둔 반복 일정은 다음 회차도
      // 계속 '오늘 할일'에 나타나야 함(false로 고정하면 완료 즉시 그 뷰에서
      // 사라져 "반복이 생성 안 된 것"처럼 보임).
      isToday: isToday,
      startDate: startDate != null ? advance(startDate!) : null,
      dueDate: advance(dueDate!),
      repeatType: repeatType,
      repeatIntervalDays: repeatIntervalDays,
      reminderEnabled: reminderEnabled,
      memo: memo,
    );
  }

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
        nextGenerated: data['nextGenerated'] as bool? ?? false,
        order: data['order'] as int? ?? 0,
      );
}
