class CategoryModel {
  final String id;
  String name;
  String colorHex;
  String iconName;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'iconName': iconName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String? ?? '#A8D8EA',
      iconName: map['iconName'] as String? ?? '📁',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
