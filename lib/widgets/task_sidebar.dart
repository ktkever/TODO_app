import 'package:flutter/material.dart';
import '../models/category.dart';

class TaskSidebar extends StatelessWidget {
  final List<Category> customCategories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const TaskSidebar({
    super.key,
    required this.customCategories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
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
                  ..._buildCategoryItems(defaultCategories),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Divider(thickness: 1, height: 1),
                  ),
                  ..._buildCategoryItems(customCategories),
                ],
              ),
            ),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryItems(List<Category> categories) {
    return categories.map((cat) => _CategoryItem(
      category: cat,
      isSelected: cat.id == selectedCategoryId,
      onTap: () => onCategorySelected(cat.id),
    )).toList();
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Column(
      children: [
        const Divider(thickness: 1, height: 1),
        _SidebarButton(
          icon: Icons.calendar_month_outlined,
          label: '달력',
          onTap: () {},
        ),
        _SidebarButton(
          icon: Icons.add,
          label: '새 카테고리',
          onTap: () {},
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  IconData _iconFor(CategoryType type) {
    switch (type) {
      case CategoryType.today:
        return Icons.wb_sunny_outlined;
      case CategoryType.planned:
        return Icons.calendar_today_outlined;
      case CategoryType.unplanned:
        return Icons.inbox_outlined;
      case CategoryType.all:
        return Icons.list_outlined;
      case CategoryType.custom:
        return Icons.label_outline;
    }
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
        onTap: onTap,
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
