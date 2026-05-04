import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/template_model.dart';
import '../../data/repositories/template_repository.dart';
import '../../shared/models/section_model.dart';

final templateRepositoryProvider = Provider<TemplateRepository>(
  (_) => TemplateRepository(),
);

final templateProvider =
    StateNotifierProvider<TemplateNotifier, List<TemplateModel>>((ref) {
  return TemplateNotifier(ref.read(templateRepositoryProvider));
});

class TemplateNotifier extends StateNotifier<List<TemplateModel>> {
  final TemplateRepository _repository;

  TemplateNotifier(this._repository) : super([]) {
    _loadTemplates();
  }

  void _loadTemplates() {
    final stored = _repository.getAll();
    if (stored.isEmpty) {
      // Use built-in templates (don't persist them)
      state = BuiltinTemplates.all;
    } else {
      // Merge built-in + custom
      final customIds = stored.map((t) => t.id).toSet();
      final builtins =
          BuiltinTemplates.all.where((t) => !customIds.contains(t.id));
      state = [...builtins, ...stored.where((t) => !t.isBuiltIn)];
    }
  }

  Future<void> saveCustom(TemplateModel template) async {
    await _repository.save(template);
    state = [...state.where((t) => t.id != template.id), template];
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = state.where((t) => t.id != id).toList();
  }
}

class BuiltinTemplates {
  static final List<TemplateModel> all = [
    TemplateModel(
      id: 'builtin_blank',
      name: 'Catatan Kosong',
      description: 'Mulai dari lembar kosong tanpa bagian',
      iconEmoji: '📝',
      sectionsData: const [],
      isBuiltIn: true,
      createdAt: DateTime(2024),
    ),
    TemplateModel(
      id: 'builtin_interview',
      name: 'Interview Klien Standar',
      description: 'Wawancara, checklist dokumen, catatan, tanda tangan',
      iconEmoji: '💼',
      sectionsData: [
        {
          'type': 'wawancara',
          'data': {
            'question': 'Bagaimana kabar Anda hari ini?',
            'answer': '',
          },
        },
        {
          'type': 'wawancara',
          'data': {
            'question': 'Apa tujuan kedatangan Anda?',
            'answer': '',
          },
        },
        {
          'type': 'checklist',
          'data': {
            'title': 'Kelengkapan Dokumen',
            'items': [
              {'id': 'i1', 'text': 'KTP/Identitas', 'checked': false},
              {'id': 'i2', 'text': 'Surat Keterangan', 'checked': false},
              {'id': 'i3', 'text': 'Formulir Pendaftaran', 'checked': false},
            ],
          },
        },
        {
          'type': 'esai',
          'data': {
            'question': 'Catatan Tambahan',
            'answer': '',
          },
        },
        {
          'type': 'tandaTangan',
          'data': {
            'label': 'Tanda Tangan Klien',
            'signatureBase64': null,
            'signerName': '',
          },
        },
      ],
      isBuiltIn: true,
      createdAt: DateTime(2024),
    ),
    TemplateModel(
      id: 'builtin_audit',
      name: 'Audit Checklist',
      description: 'Tiga kategori checklist, tabel temuan, dan catatan',
      iconEmoji: '✅',
      sectionsData: [
        {
          'type': 'checklist',
          'data': {
            'title': 'Pemeriksaan Administrasi',
            'items': [
              {'id': 'a1', 'text': 'Dokumen perizinan lengkap', 'checked': false},
              {'id': 'a2', 'text': 'Laporan keuangan tersedia', 'checked': false},
              {'id': 'a3', 'text': 'SOP terdokumentasi', 'checked': false},
            ],
          },
        },
        {
          'type': 'checklist',
          'data': {
            'title': 'Pemeriksaan Operasional',
            'items': [
              {'id': 'b1', 'text': 'Prosedur dijalankan sesuai SOP', 'checked': false},
              {'id': 'b2', 'text': 'Personel terlatih', 'checked': false},
              {'id': 'b3', 'text': 'Peralatan berfungsi baik', 'checked': false},
            ],
          },
        },
        {
          'type': 'tabel',
          'data': {
            'headers': ['No', 'Temuan', 'Tingkat Risiko', 'Rekomendasi'],
            'rows': [
              ['1', '', 'Tinggi/Sedang/Rendah', ''],
              ['2', '', 'Tinggi/Sedang/Rendah', ''],
            ],
          },
        },
        {
          'type': 'esai',
          'data': {
            'question': 'Kesimpulan Audit',
            'answer': '',
          },
        },
      ],
      isBuiltIn: true,
      createdAt: DateTime(2024),
    ),
    TemplateModel(
      id: 'builtin_survey',
      name: 'Survei Kepuasan',
      description: '5 pertanyaan pilihan ganda, esai, dan tanda tangan',
      iconEmoji: '📊',
      sectionsData: [
        {
          'type': 'pilihanGanda',
          'data': {
            'questions': [
              {
                'id': 'q1',
                'question': 'Bagaimana penilaian Anda terhadap layanan kami?',
                'options': ['Sangat Puas', 'Puas', 'Cukup', 'Tidak Puas'],
                'selectedIndex': null,
              },
              {
                'id': 'q2',
                'question': 'Seberapa mudah menghubungi kami?',
                'options': ['Sangat Mudah', 'Mudah', 'Sulit', 'Sangat Sulit'],
                'selectedIndex': null,
              },
              {
                'id': 'q3',
                'question': 'Apakah masalah Anda terselesaikan?',
                'options': ['Ya, Sepenuhnya', 'Ya, Sebagian', 'Belum Terselesaikan'],
                'selectedIndex': null,
              },
              {
                'id': 'q4',
                'question': 'Apakah Anda akan merekomendasikan kami?',
                'options': ['Pasti Ya', 'Mungkin', 'Tidak'],
                'selectedIndex': null,
              },
              {
                'id': 'q5',
                'question': 'Seberapa cepat respons tim kami?',
                'options': ['Sangat Cepat', 'Cepat', 'Lambat', 'Sangat Lambat'],
                'selectedIndex': null,
              },
            ],
          },
        },
        {
          'type': 'esai',
          'data': {
            'question': 'Saran dan masukan Anda untuk perbaikan layanan',
            'answer': '',
          },
        },
        {
          'type': 'tandaTangan',
          'data': {
            'label': 'Tanda Tangan Responden',
            'signatureBase64': null,
            'signerName': '',
          },
        },
      ],
      isBuiltIn: true,
      createdAt: DateTime(2024),
    ),
    TemplateModel(
      id: 'builtin_health',
      name: 'Kuesioner Kesehatan',
      description: 'Riwayat kesehatan, keluhan, gaya hidup, tanda tangan',
      iconEmoji: '🏥',
      sectionsData: [
        {
          'type': 'pilihanGanda',
          'data': {
            'questions': [
              {
                'id': 'h1',
                'question': 'Apakah Anda memiliki riwayat penyakit kronis?',
                'options': ['Tidak', 'Diabetes', 'Hipertensi', 'Penyakit Jantung', 'Lainnya'],
                'selectedIndex': null,
              },
              {
                'id': 'h2',
                'question': 'Seberapa sering Anda berolahraga?',
                'options': ['Setiap hari', '3-4x seminggu', '1-2x seminggu', 'Jarang/Tidak pernah'],
                'selectedIndex': null,
              },
              {
                'id': 'h3',
                'question': 'Bagaimana pola tidur Anda?',
                'options': ['Sangat Baik (7-9 jam)', 'Cukup (5-7 jam)', 'Kurang (<5 jam)'],
                'selectedIndex': null,
              },
              {
                'id': 'h4',
                'question': 'Apakah Anda merokok?',
                'options': ['Tidak pernah', 'Sudah berhenti', 'Kadang-kadang', 'Ya, aktif'],
                'selectedIndex': null,
              },
            ],
          },
        },
        {
          'type': 'esai',
          'data': {
            'question': 'Keluhan utama saat ini',
            'answer': '',
          },
        },
        {
          'type': 'esai',
          'data': {
            'question': 'Riwayat alergi dan obat-obatan',
            'answer': '',
          },
        },
        {
          'type': 'tandaTangan',
          'data': {
            'label': 'Tanda Tangan Pasien',
            'signatureBase64': null,
            'signerName': '',
          },
        },
      ],
      isBuiltIn: true,
      createdAt: DateTime(2024),
    ),
  ];
}
