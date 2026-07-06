import 'package:flutter/material.dart';
import '../models/category.dart';

class TaskSidebar extends StatelessWidget {
  final List<Category> customCategories;
  final String selectedCategoryId;
  final bool isCalendarView;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCalendarToggle;
  final ValueChanged<Category> onAddCategory;
  final ValueChanged<String> onDeleteCategory;

  const TaskSidebar({
    super.key,
    required this.customCategories,
    required this.selectedCategoryId,
    required this.isCalendarView,
    required this.onCategorySelected,
    required this.onCalendarToggle,
    required this.onAddCategory,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F2F1),
      child: SizedBox(
        width: 220,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  ..._buildCategoryItems(context, defaultCategories),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Divider(thickness: 1, height: 1),
                  ),
                  ..._buildCategoryItems(context, customCategories,
                      deletable: true),
                ],
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
    List<Category> categories, {
    bool deletable = false,
  }) {
    return categories
        .map((cat) => _CategoryItem(
              category: cat,
              isSelected: cat.id == selectedCategoryId && !isCalendarView,
              onTap: () => onCategorySelected(cat.id),
              onDelete: deletable
                  ? () => _showDeleteCategoryConfirm(
                      context, cat, onDeleteCategory)
                  : null,
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
        _SidebarButton(
          icon: Icons.add,
          label: '새 카테고리',
          onTap: () => _showAddCategoryDialog(context, onAddCategory),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

Future<void> _showAddCategoryDialog(
  BuildContext context,
  ValueChanged<Category> onAdd,
) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('새 카테고리'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '카테고리 이름'),
        onSubmitted: (value) => Navigator.pop(ctx, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('만들기'),
        ),
      ],
    ),
  );

  final trimmed = name?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    onAdd(Category(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      type: CategoryType.custom,
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
  final VoidCallback? onDelete;

  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: const Color(0xFFDEECF9),
        selectedColor: const Color(0xFF0078D4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        leading: Icon(
          _iconFor(category.type),
          size: 20,
          color: isSelected ? const Color(0xFF0078D4) : Colors.grey[700],
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? const Color(0xFF0078D4) : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: Colors.grey[400],
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isActive
            ? const Color(0xFFDEECF9)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF0078D4) : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? const Color(0xFF0078D4) : Colors.grey[700],
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
