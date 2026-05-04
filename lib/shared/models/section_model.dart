import 'dart:convert';

enum SectionType {
  wawancara,
  checklist,
  pilihanGanda,
  esai,
  tandaTangan,
  gambar,
  tabel,
  teksBebas,
}

extension SectionTypeLabel on SectionType {
  String get label => switch (this) {
        SectionType.wawancara => 'Wawancara',
        SectionType.checklist => 'Checklist',
        SectionType.pilihanGanda => 'Pilihan Ganda',
        SectionType.esai => 'Kuesioner Esai',
        SectionType.tandaTangan => 'Tanda Tangan',
        SectionType.gambar => 'Gambar',
        SectionType.tabel => 'Tabel',
        SectionType.teksBebas => 'Teks Bebas',
      };

  String get icon => switch (this) {
        SectionType.wawancara => '💬',
        SectionType.checklist => '✅',
        SectionType.pilihanGanda => '🔘',
        SectionType.esai => '📝',
        SectionType.tandaTangan => '✍️',
        SectionType.gambar => '🖼️',
        SectionType.tabel => '📊',
        SectionType.teksBebas => '📄',
      };
}

class SectionModel {
  final String id;
  final SectionType type;
  int order;
  Map<String, dynamic> data;

  SectionModel({
    required this.id,
    required this.type,
    required this.order,
    required this.data,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'order': order,
        'data': jsonEncode(data),
      };

  factory SectionModel.fromMap(Map<String, dynamic> map) {
    return SectionModel(
      id: map['id'] as String,
      type: SectionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SectionType.teksBebas,
      ),
      order: (map['order'] as num).toInt(),
      data: map['data'] is String
          ? Map<String, dynamic>.from(jsonDecode(map['data'] as String) as Map)
          : Map<String, dynamic>.from(map['data'] as Map? ?? {}),
    );
  }

  SectionModel copyWith({
    String? id,
    SectionType? type,
    int? order,
    Map<String, dynamic>? data,
  }) {
    return SectionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      order: order ?? this.order,
      data: data ?? Map<String, dynamic>.from(this.data),
    );
  }

  // ── Default data factories ──────────────────────────────────────────────────

  static Map<String, dynamic> defaultWawancara() => {
        'question': 'Pertanyaan wawancara',
        'answer': '',
      };

  static Map<String, dynamic> defaultChecklist() => {
        'title': 'Daftar Periksa',
        'items': <Map<String, dynamic>>[
          {'id': 'item_1', 'text': 'Item 1', 'checked': false},
          {'id': 'item_2', 'text': 'Item 2', 'checked': false},
        ],
      };

  static Map<String, dynamic> defaultPilihanGanda() => {
        'questions': <Map<String, dynamic>>[
          {
            'id': 'q_1',
            'question': 'Pertanyaan pilihan ganda',
            'options': ['Opsi A', 'Opsi B', 'Opsi C'],
            'selectedIndex': null,
          }
        ],
      };

  static Map<String, dynamic> defaultEsai() => {
        'question': 'Pertanyaan esai',
        'answer': '',
      };

  static Map<String, dynamic> defaultTandaTangan() => {
        'label': 'Tanda Tangan',
        'signatureBase64': null,
        'signerName': '',
      };

  static Map<String, dynamic> defaultGambar() => {
        'imagePath': null,
        'caption': '',
      };

  static Map<String, dynamic> defaultTabel() => {
        'headers': ['Kolom 1', 'Kolom 2', 'Kolom 3'],
        'rows': [
          ['', '', ''],
          ['', '', ''],
        ],
      };

  static Map<String, dynamic> defaultTeksBebas() => {
        'deltaJson': '',
      };
}
