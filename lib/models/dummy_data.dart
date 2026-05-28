import 'category.dart';
import 'task.dart';

final List<Category> dummyCustomCategories = const [
  Category(id: 'work', name: 'Work Project', type: CategoryType.custom),
  Category(id: 'personal', name: 'Personal Errands', type: CategoryType.custom),
  Category(id: 'fitness', name: 'Fitness', type: CategoryType.custom),
];

List<Task> buildDummyTasks() {
  final now = DateTime.now();
  return [
    Task(
      id: '1',
      title: '기획서 검토하기',
      categoryId: 'work',
      isToday: true,
      startDate: now,
      dueDate: now.add(const Duration(days: 2)),
      repeatType: RepeatType.none,
      memo: '3분기 기획서 초안 검토 후 피드백 작성',
    ),
    Task(
      id: '2',
      title: '팀 미팅 준비',
      categoryId: 'work',
      isToday: true,
      dueDate: now.add(const Duration(days: 1)),
      repeatType: RepeatType.weekly,
    ),
    Task(
      id: '3',
      title: '마케팅 보고서 작성',
      categoryId: 'work',
      startDate: now.add(const Duration(days: 2)),
      dueDate: now.add(const Duration(days: 5)),
    ),
    Task(
      id: '4',
      title: '장 보기',
      categoryId: 'personal',
      isToday: true,
      repeatType: RepeatType.custom,
      repeatIntervalDays: 3,
    ),
    Task(
      id: '5',
      title: '세금 신고 서류 정리',
      categoryId: 'personal',
      dueDate: now.add(const Duration(days: 7)),
      memo: '국세청 홈택스 로그인 후 제출',
    ),
    Task(
      id: '6',
      title: '자동차 보험 갱신',
      categoryId: 'personal',
    ),
    Task(
      id: '7',
      title: '아침 조깅 30분',
      categoryId: 'fitness',
      isToday: true,
      repeatType: RepeatType.daily,
    ),
    Task(
      id: '8',
      title: '헬스장 등록하기',
      categoryId: 'fitness',
      dueDate: now.add(const Duration(days: 2)),
    ),
    Task(
      id: '9',
      title: '식단 계획 세우기',
      categoryId: 'fitness',
      memo: '탄단지 비율 고려해서 주간 식단표 작성',
    ),
  ];
}
