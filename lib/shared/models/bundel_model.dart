class BundelModel {
  final String id;
  String title;
  String categoryId;
  String description;
  List<String> berkasIds;
  final DateTime createdAt;
  DateTime updatedAt;

  BundelModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.description,
    required this.berkasIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'description': description,
        'berkasIds': berkasIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BundelModel.fromMap(Map<String, dynamic> map) {
    return BundelModel(
      id: map['id'] as String,
      title: map['title'] as String,
      categoryId: map['categoryId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      berkasIds: List<String>.from(map['berkasIds'] as List? ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  BundelModel copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? description,
    List<String>? berkasIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BundelModel(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      berkasIds: berkasIds ?? List<String>.from(this.berkasIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
