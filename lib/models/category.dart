import 'package:flutter/material.dart';

enum CategoryType { today, planned, unplanned, all, custom }

const List<Color> categoryColorPalette = [
  Color(0xFF0078D4), // blue
  Color(0xFF107C10), // green
  Color(0xFFCA5010), // orange
  Color(0xFFC239B3), // magenta
  Color(0xFF5C2D91), // purple
  Color(0xFFE81123), // red
  Color(0xFF00B7C3), // teal
  Color(0xFF767676), // grey
];

Color _fallbackColorForId(String id) =>
    categoryColorPalette[id.hashCode.abs() % categoryColorPalette.length];

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.color = const Color(0xFF0078D4),
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'color': color.toARGB32(),
      };

  factory Category.fromMap(Map<String, dynamic> data) {
    final id = data['id'] as String;
    return Category(
      id: id,
      name: data['name'] as String? ?? '',
      type: CategoryType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => CategoryType.custom,
      ),
      color: data['color'] != null
          ? Color(data['color'] as int)
          : _fallbackColorForId(id),
    );
  }
}

const List<Category> defaultCategories = [
  Category(id: 'today', name: '오늘 할일', type: CategoryType.today),
  Category(id: 'planned', name: '계획된 일정', type: CategoryType.planned),
  Category(id: 'unplanned', name: '계획 안된 일정', type: CategoryType.unplanned),
  Category(id: 'all', name: '모두', type: CategoryType.all),
];
