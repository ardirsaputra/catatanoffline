import 'dart:convert';
import 'section_model.dart';

enum BerkasBackground {
  solid,
  dots,
  lines,
  watercolor,
}

class BerkasModel {
  final String id;
  String title;
  String categoryId;
  String iconName;
  String colorTag;
  final DateTime createdAt;
  DateTime updatedAt;
  BerkasBackground backgroundType;
  String backgroundValue;
  List<SectionModel> sections;

  BerkasModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.iconName,
    required this.colorTag,
    required this.createdAt,
    required this.updatedAt,
    this.backgroundType = BerkasBackground.solid,
    this.backgroundValue = '#FFFFFF',
    this.sections = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'iconName': iconName,
        'colorTag': colorTag,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'backgroundType': backgroundType.name,
        'backgroundValue': backgroundValue,
        'sectionsJson': jsonEncode(
          sections.map((s) => s.toMap()).toList(),
        ),
      };

  factory BerkasModel.fromMap(Map<String, dynamic> map) {
    final sectionsRaw = map['sectionsJson'] as String? ?? '[]';
    final sectionsList = (jsonDecode(sectionsRaw) as List<dynamic>)
        .map((s) =>
            SectionModel.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return BerkasModel(
      id: map['id'] as String,
      title: map['title'] as String,
      categoryId: map['categoryId'] as String? ?? '',
      iconName: map['iconName'] as String? ?? '📄',
      colorTag: map['colorTag'] as String? ?? '#A8D8EA',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      backgroundType: BerkasBackground.values.firstWhere(
        (e) => e.name == (map['backgroundType'] as String? ?? 'solid'),
        orElse: () => BerkasBackground.solid,
      ),
      backgroundValue: map['backgroundValue'] as String? ?? '#FFFFFF',
      sections: sectionsList,
    );
  }

  BerkasModel copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? iconName,
    String? colorTag,
    DateTime? createdAt,
    DateTime? updatedAt,
    BerkasBackground? backgroundType,
    String? backgroundValue,
    List<SectionModel>? sections,
  }) {
    return BerkasModel(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      iconName: iconName ?? this.iconName,
      colorTag: colorTag ?? this.colorTag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundValue: backgroundValue ?? this.backgroundValue,
      sections: sections ?? List<SectionModel>.from(this.sections),
    );
  }
}
