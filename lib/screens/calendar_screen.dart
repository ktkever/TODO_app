import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final List<Category> customCategories;
  final ValueChanged<Task> onTaskSelected;
  final ValueChanged<DateTime>? onCreateOnDate;
  final ValueChanged<Task>? onTaskChanged;
  final ValueChanged<String>? onTaskDeleted;
  final String? selectedTaskId;

  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.customCategories,
    required this.onTaskSelected,
    this.onCreateOnDate,
    this.onTaskChanged,
    this.onTaskDeleted,
    this.selectedTaskId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  static const _cellHeight = 100.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      });

  // 이번 달의 주(週) 목록 생성 (null = 이전/다음 달 여백)
  List<List<DateTime?>> _buildWeeks() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startOffset = (firstDay.weekday - 1) % 7; // 월=0, 일=6

    final days = <DateTime?>[
      ...List.filled(startOffset, null),
      ...List.generate(lastDay.day, (i) => DateTime(_focusedMonth.year, _focusedMonth.month, i + 1)),
    ];
    while (days.length % 7 != 0) {
      days.add(null);
    }

    return [
      for (int i = 0; i < days.length; i += 7) days.sublist(i, i + 7),
    ];
  }

  // 카테고리별 색상 — 사용자가 카테고리 생성/편집 시 지정한 색상을 그대로 사용
  Color _colorFor(String? categoryId) {
    if (categoryId == null) return Colors.grey;
    for (final cat in widget.customCategories) {
      if (cat.id == categoryId) return cat.color;
    }
    return Colors.grey;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // 드래그로 일정을 targetDay로 옮긴다 — 기간(duration)은 유지한 채 기한만 이동.
  void _moveTaskTo(Task task, DateTime targetDay) {
    if (widget.onTaskChanged == null) return;
    final target = DateTime(targetDay.year, targetDay.month, targetDay.day);
    if (task.startDate == null) {
      task.dueDate = target; // 단일 마감일
    } else {
      final dur = task.dueDate!.difference(task.startDate!);
      task.startDate = target;
      task.dueDate = target.add(dur);
    }
    widget.onTaskChanged!.call(task);
  }

  // 일정 우클릭 → 세부 설정 팝업(카테고리 이동 / 할일 삭제).
  Future<void> _showTaskMenu(Task task, Offset globalPos) async {
    final rect = RelativeRect.fromLTRB(
        globalPos.dx, globalPos.dy, globalPos.dx, globalPos.dy);
    final action = await showMenu<String>(
      context: context,
      position: rect,
      items: const [
        PopupMenuItem(
          value: 'move',
          child: Row(children: [
            Icon(Icons.drive_file_move_outline, size: 18),
            SizedBox(width: 8),
            Text('카테고리 이동'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18),
            SizedBox(width: 8),
            Text('할일 삭제'),
          ]),
        ),
      ],
    );
    if (!mounted) return;
    if (action == 'delete') {
      widget.onTaskDeleted?.call(task.id);
    } else if (action == 'move') {
      _showCategoryMenu(task, globalPos);
    }
  }

  // '카테고리 이동' 선택 시 카테고리 목록 팝업.
  Future<void> _showCategoryMenu(Task task, Offset globalPos) async {
    if (widget.onTaskChanged == null) return;
    final rect = RelativeRect.fromLTRB(
        globalPos.dx, globalPos.dy, globalPos.dx, globalPos.dy);
    const noneValue = '__none__';
    final picked = await showMenu<String>(
      context: context,
      position: rect,
      items: [
        const PopupMenuItem(value: noneValue, child: Text('카테고리 없음')),
        ...widget.customCategories.map((c) => PopupMenuItem(
              value: c.id,
              child: Row(children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: c.color),
                ),
                const SizedBox(width: 8),
                Text(c.name),
              ]),
            )),
      ],
    );
    if (!mounted || picked == null) return;
    task.categoryId = picked == noneValue ? null : picked;
    widget.onTaskChanged!.call(task);
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();

    return GestureDetector(
      // 좌우 스와이프로 월 페이지 넘김(오른쪽=이전 달, 왼쪽=다음 달).
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v > 0) {
          _prevMonth();
        } else if (v < 0) {
          _nextMonth();
        }
      },
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildWeekdayRow(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / 7;
              return Column(
                children: weeks
                    .map((week) => _buildWeekRow(week, cellWidth))
                    .toList(),
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Text(
            '${_focusedMonth.year}년 ${_focusedMonth.month}월',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0078D4),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _prevMonth,
            color: AppColors.of(context).textSecondary,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            color: AppColors.of(context).textSecondary,
          ),
          TextButton(
            onPressed: () => setState(() {
              final now = DateTime.now();
              _focusedMonth = DateTime(now.year, now.month);
            }),
            child: const Text('오늘', style: TextStyle(color: Color(0xFF0078D4))),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow() {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border),
          top: BorderSide(color: colors.border),
        ),
        color: colors.surfaceAlt,
      ),
      child: Row(
        children: _weekdays.map((label) {
          final isSat = label == '토';
          final isSun = label == '일';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSun
                      ? Colors.red[400]
                      : isSat
                          ? Colors.blue[400]
                          : colors.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekRow(List<DateTime?> week, double cellWidth) {
    final today = DateTime.now();
    final colors = AppColors.of(context);

    // 이 주에 표시할 일정 수집
    final barItems = _collectBarsForWeek(week, cellWidth);

    return SizedBox(
      height: _cellHeight,
      child: Stack(
        children: [
          // 날짜 셀 배경
          Row(
            children: week.map((day) {
              final isToday = day != null && _isSameDay(day, today);
              final isCurrentMonth =
                  day != null && day.month == _focusedMonth.month;
              final isSun = day != null && day.weekday == 7;
              final isSat = day != null && day.weekday == 6;

              return SizedBox(
                width: cellWidth,
                height: _cellHeight,
                child: GestureDetector(
                  // 빈 날짜 칸 더블클릭/더블탭 → 그 날짜에 새 할일 생성.
                  onDoubleTap: (day == null || widget.onCreateOnDate == null)
                      ? null
                      : () => widget.onCreateOnDate!(day),
                  child: DragTarget<Task>(
                    // 드래그해 온 일정을 이 날짜로 떨어뜨리면 기한 이동.
                    onWillAcceptWithDetails: (_) =>
                        day != null && widget.onTaskChanged != null,
                    onAcceptWithDetails: (d) => _moveTaskTo(d.data, day!),
                    builder: (context, candidate, rejected) => Container(
                  decoration: BoxDecoration(
                    color: candidate.isNotEmpty ? colors.selectedBg : null,
                    border: Border(
                      right: BorderSide(color: colors.border),
                      bottom: BorderSide(color: colors.border),
                    ),
                  ),
                  child: day == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 4, right: 6),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: isToday
                                ? Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF0078D4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: !isCurrentMonth
                                          ? colors.textMuted
                                          : isSun
                                              ? Colors.red[400]
                                              : isSat
                                                  ? Colors.blue[400]
                                                  : colors.textPrimary,
                                    ),
                                  ),
                          ),
                        ),
                ),
                ),
                ),
              );
            }).toList(),
          ),
          // 일정 바 / 블록
          ...barItems,
        ],
      ),
    );
  }

  // 해당 주에 걸치는 일정 바 위젯 목록 반환
  List<Widget> _collectBarsForWeek(List<DateTime?> week, double cellWidth) {
    final validDays = week.where((d) => d != null).toList();
    if (validDays.isEmpty) return [];

    final weekStart = validDays.first!;
    final weekEnd = validDays.last!;

    final List<({Task task, int colStart, int colEnd, bool isBar})> entries = [];

    for (final task in widget.tasks) {
      if (task.isCompleted) continue; // 완료된 할 일은 달력에 표시하지 않는다.
      if (task.startDate != null && task.dueDate != null) {
        // 기간 일정 — 이 주와 겹치는지 확인
        final s = task.startDate!;
        final e = task.dueDate!;
        final sDate = DateTime(s.year, s.month, s.day);
        final eDate = DateTime(e.year, e.month, e.day);
        final wStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
        final wEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

        if (eDate.isBefore(wStart) || sDate.isAfter(wEnd)) continue;

        final clampedStart = sDate.isBefore(wStart) ? wStart : sDate;
        final clampedEnd = eDate.isAfter(wEnd) ? wEnd : eDate;

        final colStart = _colOfDay(week, clampedStart);
        final colEnd = _colOfDay(week, clampedEnd);
        if (colStart == -1 || colEnd == -1) continue;

        entries.add((task: task, colStart: colStart, colEnd: colEnd, isBar: true));
      } else if (task.startDate == null && task.dueDate != null) {
        // 단일 마감일
        final d = task.dueDate!;
        final dDate = DateTime(d.year, d.month, d.day);
        final col = _colOfDay(week, dDate);
        if (col == -1) continue;

        entries.add((task: task, colStart: col, colEnd: col, isBar: false));
      }
    }

    final List<Widget> widgets = [];
    final Map<int, int> rowOccupied = {}; // col → 사용된 행 수

    for (final entry in entries) {
      // 이 범위에서 겹치지 않는 행 찾기
      int row = 0;
      while (true) {
        bool conflict = false;
        for (int c = entry.colStart; c <= entry.colEnd; c++) {
          if ((rowOccupied[c] ?? 0) > row) {
            conflict = true;
            break;
          }
        }
        if (!conflict) break;
        row++;
        if (row >= 3) break; // 최대 3개
      }
      if (row >= 3) continue;

      for (int c = entry.colStart; c <= entry.colEnd; c++) {
        rowOccupied[c] = row + 1;
      }

      final left = entry.colStart * cellWidth + 2;
      final width = (entry.colEnd - entry.colStart + 1) * cellWidth - 4;
      final top = 32.0 + row * 22.0;
      final color = _colorFor(entry.task.categoryId);

      final barContent = Container(
        decoration: BoxDecoration(
          color: entry.isBar ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
          border: entry.isBar ? null : Border.all(color: color, width: 1),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          entry.task.title,
          style: TextStyle(
            fontSize: 12,
            color: entry.isBar ? Colors.white : color,
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 1,
        ),
      );

      widgets.add(Positioned(
        left: left,
        top: top,
        width: width,
        height: 19,
        // 좌클릭 꾹(롱프레스) → 드래그로 다른 날짜에 떨어뜨리면 기한 이동(DragTarget=날짜 칸).
        child: LongPressDraggable<Task>(
          data: entry.task,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              height: 19,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                entry.task.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: barContent),
          child: GestureDetector(
            onTap: () => widget.onTaskSelected(entry.task),
            // 우클릭 → 세부 설정 팝업(카테고리 이동/삭제).
            onSecondaryTapDown: (d) =>
                _showTaskMenu(entry.task, d.globalPosition),
            child: barContent,
          ),
        ),
      ));
    }

    return widgets;
  }

  // 날짜가 week의 몇 번째 열인지 반환 (-1 = 없음)
  int _colOfDay(List<DateTime?> week, DateTime day) {
    for (int i = 0; i < week.length; i++) {
      final d = week[i];
      if (d != null && _isSameDay(d, day)) return i;
    }
    return -1;
  }
}
