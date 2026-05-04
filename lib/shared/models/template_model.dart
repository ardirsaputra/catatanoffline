import 'dart:convert';
import 'section_model.dart';

class TemplateModel {
  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final List<Map<String, dynamic>> sectionsData;
  final bool isBuiltIn;
  final DateTime createdAt;

  const TemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.sectionsData,
    required this.isBuiltIn,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'iconEmoji': iconEmoji,
        'sectionsDataJson': jsonEncode(sectionsData),
        'isBuiltIn': isBuiltIn,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    final sectionsRaw = map['sectionsDataJson'] as String? ?? '[]';
    final sectionsList = (jsonDecode(sectionsRaw) as List<dynamic>)
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
    return TemplateModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      iconEmoji: map['iconEmoji'] as String? ?? '📄',
      sectionsData: sectionsList,
      isBuiltIn: map['isBuiltIn'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  List<SectionModel> buildSections() {
    return sectionsData.asMap().entries.map((entry) {
      final idx = entry.key;
      final sData = entry.value;
      return SectionModel(
        id: 'section_${DateTime.now().millisecondsSinceEpoch}_$idx',
        type: SectionType.values.firstWhere(
          (e) => e.name == (sData['type'] as String? ?? 'teksBebas'),
          orElse: () => SectionType.teksBebas,
        ),
        order: idx,
        data: Map<String, dynamic>.from(sData['data'] as Map? ?? {}),
      );
    }).toList();
  }
}
