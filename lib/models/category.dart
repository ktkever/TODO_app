enum CategoryType { today, planned, unplanned, all, custom }

class Category {
  final String id;
  final String name;
  final CategoryType type;

  const Category({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
      };

  factory Category.fromMap(Map<String, dynamic> data) => Category(
        id: data['id'] as String,
        name: data['name'] as String? ?? '',
        type: CategoryType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => CategoryType.custom,
        ),
      );
}

const List<Category> defaultCategories = [
  Category(id: 'today', name: '오늘 할일', type: CategoryType.today),
  Category(id: 'planned', name: '계획된 일정', type: CategoryType.planned),
  Category(id: 'unplanned', name: '계획 안된 일정', type: CategoryType.unplanned),
  Category(id: 'all', name: '모두', type: CategoryType.all),
];
