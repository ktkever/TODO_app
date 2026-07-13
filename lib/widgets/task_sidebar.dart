import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';

// 바탕화면 위젯 모드는 Windows 창 관리 API 전용 기능이라 다른 플랫폼에서는 숨긴다.
bool get _supportsDesktopWidgetMode => !kIsWeb && Platform.isWindows;

class TaskSidebar extends StatelessWidget {
  final List<Category> customCategories;
  final String selectedCategoryId;
  final bool isCalendarView;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCalendarToggle;
  final ValueChanged<Category> onAddCategory;
  final ValueChanged<Category> onEditCategoryColor;
  final ValueChanged<String> onDeleteCategory;
  final ValueChanged<List<Category>> onReorderCategories;
  final VoidCallback? onLogout;
  final VoidCallback onEnterWidgetMode;

  const TaskSidebar({
    super.key,
    required this.customCategories,
    required this.selectedCategoryId,
    required this.isCalendarView,
    required this.onCategorySelected,
    required this.onCalendarToggle,
    required this.onAddCategory,
    required this.onEditCategoryColor,
    required this.onDeleteCategory,
    required this.onReorderCategories,
    required this.onEnterWidgetMode,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      child: SizedBox(
        width: 220,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: _buildCategoryItems(context, defaultCategories),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(thickness: 1, height: 1),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: EdgeInsets.zero,
                itemCount: customCategories.length,
                onReorderItem: (oldIndex, newIndex) {
                  final reordered = List<Category>.from(customCategories);
                  final moved = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, moved);
                  onReorderCategories(reordered);
                },
                itemBuilder: (context, index) {
                  final cat = customCategories[index];
                  return _CategoryItem(
                    key: ValueKey(cat.id),
                    category: cat,
                    isSelected: cat.id == selectedCategoryId && !isCalendarView,
                    onTap: () => onCategorySelected(cat.id),
                    onEditColor: () =>
                        _showEditColorDialog(context, cat, onEditCategoryColor),
                    onDelete: () =>
                        _showDeleteCategoryConfirm(context, cat, onDeleteCategory),
                  );
                },
              ),
            ),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryItems(
    BuildContext context,
    List<Category> categories,
  ) {
    return categories
        .map((cat) => _CategoryItem(
              key: ValueKey(cat.id),
              category: cat,
              isSelected: cat.id == selectedCategoryId && !isCalendarView,
              onTap: () => onCategorySelected(cat.id),
            ))
        .toList();
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Column(
      children: [
        const Divider(thickness: 1, height: 1),
        _SidebarButton(
          icon: isCalendarView
              ? Icons.calendar_month
              : Icons.calendar_month_outlined,
          label: '달력',
          isActive: isCalendarView,
          onTap: onCalendarToggle,
        ),
        if (_supportsDesktopWidgetMode)
          _SidebarButton(
            icon: Icons.dashboard_customize_outlined,
            label: '바탕화면 위젯',
            onTap: onEnterWidgetMode,
          ),
        _SidebarButton(
          icon: Icons.add,
          label: '새 카테고리',
          onTap: () => _showAddCategoryDialog(
              context, customCategories.length, onAddCategory),
        ),
        if (onLogout != null)
          _SidebarButton(
            icon: Icons.logout,
            label: '로그아웃',
            onTap: onLogout!,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

Widget _colorSwatch(Color color, bool selected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: selected ? Colors.black : Colors.transparent,
          width: 2,
        ),
      ),
    ),
  );
}

Future<void> _showAddCategoryDialog(
  BuildContext context,
  int order,
  ValueChanged<Category> onAdd,
) async {
  final controller = TextEditingController();
  Color selectedColor = categoryColorPalette.first;

  final result = await showDialog<Category>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('새 카테고리'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '카테고리 이름'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryColorPalette
                  .map((c) => _colorSwatch(
                        c,
                        c.toARGB32() == selectedColor.toARGB32(),
                        () => setDialogState(() => selectedColor = c),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              ctx,
              Category(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: controller.text.trim(),
                type: CategoryType.custom,
                color: selectedColor,
                order: order,
              ),
            ),
            child: const Text('만들기'),
          ),
        ],
      ),
    ),
  );

  if (result != null && result.name.isNotEmpty) onAdd(result);
}

Future<void> _showEditColorDialog(
  BuildContext context,
  Category category,
  ValueChanged<Category> onEdit,
) async {
  final picked = await showDialog<Color>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("'${category.name}' 색상"),
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: categoryColorPalette
            .map((c) => _colorSwatch(
                  c,
                  c.toARGB32() == category.color.toARGB32(),
                  () => Navigator.pop(ctx, c),
                ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('닫기'),
        ),
      ],
    ),
  );

  if (picked != null) {
    onEdit(Category(
      id: category.id,
      name: category.name,
      type: category.type,
      color: picked,
      order: category.order,
    ));
  }
}

Future<void> _showDeleteCategoryConfirm(
  BuildContext context,
  Category category,
  ValueChanged<String> onDelete,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('카테고리 삭제'),
      content: Text(
          "'${category.name}' 카테고리를 삭제할까요? 이 카테고리의 할 일은 '카테고리 없음'으로 이동합니다."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );

  if (confirmed == true) onDelete(category.id);
}

class _CategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEditColor;
  final VoidCallback? onDelete;

  const _CategoryItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.onEditColor,
    this.onDelete,
  });

  IconData _iconFor(CategoryType type) {
    return switch (type) {
      CategoryType.today => Icons.wb_sunny_outlined,
      CategoryType.planned => Icons.calendar_today_outlined,
      CategoryType.unplanned => Icons.inbox_outlined,
      CategoryType.all => Icons.list_outlined,
      CategoryType.custom => Icons.label_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: colors.selectedBg,
        selectedColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        leading: onEditColor == null
            ? Icon(
                _iconFor(category.type),
                size: 20,
                color: isSelected ? AppColors.accent : colors.textSecondary,
              )
            : GestureDetector(
                onTap: onEditColor,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: category.color,
                  ),
                ),
              ),
        title: Text(
          category.name,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? AppColors.accent : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: colors.textMuted,
                onPressed: onDelete,
              ),
        onTap: onTap,
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isActive ? colors.selectedBg : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.accent : colors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? AppColors.accent : colors.textSecondary,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
