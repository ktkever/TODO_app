import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';

class DetailPanel extends StatefulWidget {
  final Task task;
  final List<Category> customCategories;
  final VoidCallback onClose;
  final ValueChanged<Task> onTaskChanged;

  const DetailPanel({
    super.key,
    required this.task,
    required this.customCategories,
    required this.onClose,
    required this.onTaskChanged,
  });

  @override
  State<DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends State<DetailPanel> {
  late bool _isToday;
  late bool _isRange;
  late DateTime? _startDate;
  late DateTime? _dueDate;
  late RepeatType _repeatType;
  late int _repeatIntervalDays;
  late bool _reminderEnabled;
  late String? _categoryId;
  late TextEditingController _titleController;
  late TextEditingController _memoController;
  late TextEditingController _intervalController;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _syncFromTask(widget.task);
  }

  @override
  void didUpdateWidget(DetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _titleController.dispose();
      _memoController.dispose();
      _intervalController.dispose();
      _syncFromTask(widget.task);
    }
  }

  void _syncFromTask(Task task) {
    _isToday = task.isToday;
    _isRange = task.startDate != null;
    _startDate = task.startDate;
    _dueDate = task.dueDate;
    _repeatType = task.repeatType;
    _repeatIntervalDays = task.repeatIntervalDays;
    _reminderEnabled = task.reminderEnabled;
    _categoryId = task.categoryId;
    _titleController = TextEditingController(text: task.title);
    _memoController = TextEditingController(text: task.memo);
    _intervalController = TextEditingController(
      text: task.repeatIntervalDays.toString(),
    );
    _dateError = null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.task
      ..title = _titleController.text
      ..categoryId = _categoryId
      ..isToday = _isToday
      ..startDate = _isRange ? _startDate : null
      ..dueDate = _dueDate
      ..repeatType = _repeatType
      ..repeatIntervalDays = _repeatIntervalDays
      ..reminderEnabled = _reminderEnabled
      ..memo = _memoController.text;
    widget.onTaskChanged(widget.task);
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _startDate : _dueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;

    // 기간 설정 시 시작일이 종료일보다 늦을 수 없음 — 달력 뷰가 역전된
    // 구간을 그리지 못해 일정이 아예 안 보이는 문제로 이어지므로 저장 전에 막는다.
    if (_isRange) {
      if (isStart && _dueDate != null && picked.isAfter(_dueDate!)) {
        setState(() => _dateError = '시작일은 종료일보다 늦을 수 없습니다.');
        return;
      }
      if (!isStart && _startDate != null && picked.isBefore(_startDate!)) {
        setState(() => _dateError = '종료일은 시작일보다 빠를 수 없습니다.');
        return;
      }
    }

    setState(() {
      _dateError = null;
      if (isStart) {
        _startDate = picked;
      } else {
        _dueDate = picked;
      }
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategorySection(),
                _buildDivider(),
                _buildTodaySection(),
                _buildDivider(),
                _buildDueDateSection(),
                _buildDivider(),
                _buildRepeatSection(),
                _buildDivider(),
                _buildReminderSection(),
                _buildDivider(),
                _buildMemoSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _titleController,
              maxLines: 2,
              minLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _notifyChanged(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onClose,
            color: colors.textMuted,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // 섹션 0: 소속 카테고리
  Widget _buildCategorySection() {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.label_outline, size: 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          Text('카테고리',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary)),
          const Spacer(),
          DropdownButton<String?>(
            value: _categoryId,
            underline: const SizedBox.shrink(),
            hint: const Text('카테고리 없음', style: TextStyle(fontSize: 13)),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('카테고리 없음', style: TextStyle(fontSize: 13)),
              ),
              ...widget.customCategories.map((cat) => DropdownMenuItem<String?>(
                    value: cat.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cat.color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(cat.name, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )),
            ],
            onChanged: (v) {
              setState(() => _categoryId = v);
              _notifyChanged();
            },
          ),
        ],
      ),
    );
  }

  // 섹션 1: 오늘 할일 추가
  Widget _buildTodaySection() {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() => _isToday = !_isToday);
            _notifyChanged();
          },
          icon: Icon(
            _isToday ? Icons.wb_sunny : Icons.wb_sunny_outlined,
            size: 18,
            color: _isToday ? AppColors.accent : colors.textMuted,
          ),
          label: Text(
            _isToday ? "'오늘 할일'에서 제거" : "'오늘 할일'에 추가",
            style: TextStyle(
              fontSize: 13,
              color: _isToday ? AppColors.accent : colors.textSecondary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isToday ? AppColors.accent : colors.border,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }

  // 섹션 2: 기한 설정
  Widget _buildDueDateSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Color(0xFF0078D4)),
              const SizedBox(width: 8),
              Text('기한',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).textSecondary)),
              const Spacer(),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _dueDate != null || _startDate != null,
                  onChanged: (v) {
                    setState(() {
                      _dateError = null;
                      if (!v) {
                        _startDate = null;
                        _dueDate = null;
                        _isRange = false;
                      } else {
                        _dueDate = DateTime.now();
                      }
                    });
                    _notifyChanged();
                  },
                  activeThumbColor: const Color(0xFF0078D4),
                  activeTrackColor: const Color(0xFFB3D7F3),
                ),
              ),
            ],
          ),
          if (_dueDate != null || _startDate != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ModeChip(
                  label: '단일 마감일',
                  selected: !_isRange,
                  onTap: () => setState(() {
                    _isRange = false;
                    _dateError = null;
                  }),
                ),
                _ModeChip(
                  label: '기간',
                  selected: _isRange,
                  onTap: () => setState(() {
                    _isRange = true;
                    _startDate ??= DateTime.now();
                    _dateError = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isRange)
              _DateRow(
                label: '시작일',
                date: _startDate,
                onTap: () => _pickDate(true),
              ),
            _DateRow(
              label: _isRange ? '종료일' : '마감일',
              date: _dueDate,
              onTap: () => _pickDate(false),
            ),
            if (_dateError != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: Color(0xFFC42B1C)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _dateError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC42B1C),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // 섹션 3: 반복 설정
  Widget _buildRepeatSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat, size: 16, color: Color(0xFF0078D4)),
              const SizedBox(width: 8),
              Text('반복',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: RepeatType.values.map((type) {
              return _ModeChip(
                label: _repeatLabel(type),
                selected: _repeatType == type,
                onTap: () {
                  setState(() => _repeatType = type);
                  _notifyChanged();
                },
              );
            }).toList(),
          ),
          if (_repeatType == RepeatType.custom) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('매', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) {
                        _repeatIntervalDays = n;
                        _notifyChanged();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('일마다', style: TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 섹션 4: 알림 설정 (UI만)
  Widget _buildReminderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_outlined,
                  size: 16, color: Color(0xFF0078D4)),
              const SizedBox(width: 8),
              Text('알림',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).textSecondary)),
              const Spacer(),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _reminderEnabled,
                  onChanged: (v) {
                    setState(() => _reminderEnabled = v);
                    _notifyChanged();
                  },
                  activeThumbColor: const Color(0xFF0078D4),
                  activeTrackColor: const Color(0xFFB3D7F3),
                ),
              ),
            ],
          ),
          if (_reminderEnabled) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                // UI 표시 전용 — 실제 알림 로직 없음
                if (picked != null) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.of(context).border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: AppColors.of(context).textMuted),
                    const SizedBox(width: 8),
                    Text(
                      '알림 시간 설정 (UI 전용)',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.of(context).textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 섹션 5: 메모
  Widget _buildMemoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, size: 16, color: Color(0xFF0078D4)),
              const SizedBox(width: 8),
              Text('메모',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _memoController,
            maxLines: 4,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: '메모를 입력하세요...',
              hintStyle: TextStyle(
                  color: AppColors.of(context).textMuted, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.of(context).border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.of(context).border),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
            onChanged: (_) => _notifyChanged(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, thickness: 1, color: AppColors.of(context).border);

  String _repeatLabel(RepeatType type) => switch (type) {
        RepeatType.none => '없음',
        RepeatType.daily => '매일',
        RepeatType.weekly => '매주',
        RepeatType.monthly => '매월',
        RepeatType.yearly => '매년',
        RepeatType.custom => '사용자 지정',
      };
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : colors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateRow({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  date != null
                      ? '${date!.year}.${date!.month.toString().padLeft(2, '0')}.${date!.day.toString().padLeft(2, '0')}'
                      : '날짜 선택',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: date != null ? colors.textPrimary : colors.textMuted,
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
