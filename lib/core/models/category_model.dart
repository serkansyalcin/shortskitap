class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final bool isActive;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    required this.isActive,
    required this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        isActive: json['is_active'] == true,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon': icon,
        'color': color,
        'is_active': isActive,
        'sort_order': sortOrder,
      };
}
