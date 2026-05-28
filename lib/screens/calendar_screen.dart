import 'package:flutter/material.dart';
import '../models/task.dart';

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final ValueChanged<Task> onTaskSelected;
  final String? selectedTaskId;

  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.onTaskSelected,
    this.selectedTaskId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  static const _cellHeight = 90.0;

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

  // 카테고리별 색상
  Color _colorFor(String? categoryId) => switch (categoryId) {
        'work' => const Color(0xFF0078D4),
        'personal' => const Color(0xFF107C10),
        'fitness' => const Color(0xFFCA5010),
        _ => Colors.grey,
      };

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();

    return Column(
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
            color: Colors.grey[700],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            color: Colors.grey[700],
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
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
          top: BorderSide(color: Colors.grey[200]!),
        ),
        color: const Color(0xFFF9F9F9),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSun
                      ? Colors.red[400]
                      : isSat
                          ? Colors.blue[400]
                          : Colors.grey[600],
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
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey[200]!),
                      bottom: BorderSide(color: Colors.grey[200]!),
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
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF0078D4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: !isCurrentMonth
                                          ? Colors.grey[300]
                                          : isSun
                                              ? Colors.red[400]
                                              : isSat
                                                  ? Colors.blue[400]
                                                  : Colors.grey[700],
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
      final top = 26.0 + row * 20.0;
      final color = _colorFor(entry.task.categoryId);

      widgets.add(Positioned(
        left: left,
        top: top,
        width: width,
        height: 16,
        child: GestureDetector(
          onTap: () => widget.onTaskSelected(entry.task),
          child: Container(
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
                fontSize: 10,
                color: entry.isBar ? Colors.white : color,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
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
