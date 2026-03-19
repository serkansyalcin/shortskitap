class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final bool isActive;
  final bool isKids;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    required this.isActive,
    this.isKids = false,
    required this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String? ?? (json['name'] as String).toLowerCase().replaceAll(' ', '-'),
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        isActive: json['is_active'] == true,
        isKids: json['is_kids'] == true,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon': icon,
        'color': color,
        'is_active': isActive,
        'is_kids': isKids,
        'sort_order': sortOrder,
      };
}
