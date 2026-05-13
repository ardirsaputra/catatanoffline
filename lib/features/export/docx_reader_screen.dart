import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/berkas_model.dart';
import '../../shared/models/section_model.dart';
import '../berkas/providers/berkas_provider.dart';
import '../editor/providers/editor_provider.dart';
import '../editor/screens/editor_screen.dart';
import 'docx_import_service.dart';

/// Mode-pembaca untuk file .docx / .doc.
///
/// Menampilkan isi dokumen Word secara read-only.  Tombol "Simpan & Edit"
/// di bagian bawah mengimpor dokumen ke format Berkas lalu membuka editor.
class DocxReaderScreen extends ConsumerStatefulWidget {
  final String filePath;

  const DocxReaderScreen({super.key, required this.filePath});

  @override
  ConsumerState<DocxReaderScreen> createState() => _DocxReaderScreenState();
}

class _DocxReaderScreenState extends ConsumerState<DocxReaderScreen> {
  BerkasModel? _parsed;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _parse();
  }

  Future<void> _parse() async {
    final result = await DocxImportService.importFromPath(widget.filePath);
    if (!mounted) return;
    setState(() {
      _parsed = result;
      _loading = false;
      _error = result == null ? 'Gagal membaca file. Pastikan file adalah .docx yang valid.' : null;
    });
  }

  String get _fileName {
    final raw = widget.filePath.split('/').last.split('\\').last;
    return raw;
  }

  Future<void> _importAndEdit() async {
    if (_parsed == null) return;

    // Ask for title
    final titleController = TextEditingController(text: _parsed!.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Simpan sebagai Berkas',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_parsed!.sections.length} bagian akan disimpan.',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul Berkas',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan & Buka Editor'),
          ),
        ],
      ),
    );

    // Read the value first, then dispose — the dialog widget tree is fully
    // torn down by the time we reach here, so disposing is safe.
    final newTitle = titleController.text.trim();
    // Defer dispose to next frame so the dialog's exit animation completes
    // and the TextField fully unmounts before the controller is released.
    WidgetsBinding.instance.addPostFrameCallback((_) => titleController.dispose());

    if (confirmed != true || !mounted) return;

    final finalBerkas = _parsed!.copyWith(
      title: newTitle.isEmpty ? _parsed!.title : newTitle,
    );

    await ref.read(berkasProvider.notifier).importBerkas(finalBerkas);
    if (!mounted) return;

    ref.read(editorProvider.notifier).loadBerkas(finalBerkas);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mode Pembaca',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            Text(
              _fileName,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (!_loading && _parsed != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  '${_parsed!.sections.length} bagian',
                  style: const TextStyle(fontSize: 11, color: Colors.purple),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
        ],
      ),
      body: _buildBody(colorScheme),
      bottomNavigationBar: _loading || _parsed == null ? null : _BottomActionBar(onImportAndEdit: _importAndEdit),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Membaca dokumen Word...',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final berkas = _parsed!;

    return CustomScrollView(
      slivers: [
        // Document title banner
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        berkas.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dokumen Word · ${berkas.sections.length} bagian',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Read-only banner hint
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFFE3F2FD),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode Pembaca — Hanya baca. Tekan "Simpan & Edit" untuk mulai mengedit.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sections
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _SectionCard(
                section: berkas.sections[index],
                index: index,
              ),
              childCount: berkas.sections.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom action bar ──────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onImportAndEdit;

  const _BottomActionBar({required this.onImportAndEdit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onImportAndEdit,
                icon: const Icon(Icons.add_to_photos_outlined),
                label: const Text(
                  'Tambah ke Berkas & Edit',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section card (read-only) ───────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final SectionModel section;
  final int index;

  const _SectionCard({required this.section, required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section type label
            Row(
              children: [
                Text(
                  section.type.icon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  section.type.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (section.type) {
      SectionType.teksBebas => _TeksBebasView(data: section.data),
      SectionType.wawancara => _WawancaraView(data: section.data),
      SectionType.esai => _WawancaraView(data: section.data),
      SectionType.checklist => _ChecklistView(data: section.data),
      SectionType.pilihanGanda => _PilihanGandaView(data: section.data),
      SectionType.tabel => _TabelView(data: section.data),
      SectionType.tandaTangan => _TandaTanganView(data: section.data),
      SectionType.gambar => _GambarView(data: section.data),
    };
  }
}

// ── teksBebas renderer ────────────────────────────────────────────────────────

class _TeksBebasView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TeksBebasView({required this.data});

  List<Map<String, dynamic>> _loadOps() {
    try {
      final raw = data['deltaJson'] as String? ?? '';
      if (raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ops = _loadOps();
    if (ops.isEmpty) {
      return Text(
        '(kosong)',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return _DeltaRenderer(ops: ops);
  }
}

// ── Quill-delta rich-text renderer ────────────────────────────────────────────

class _DeltaRenderer extends StatelessWidget {
  final List<Map<String, dynamic>> ops;

  const _DeltaRenderer({required this.ops});

  /// Split the flat op list into logical paragraphs.
  /// Each paragraph ends with a bare or attributed '\n' op.
  List<({List<Map<String, dynamic>> runs, Map<String, dynamic> block})> _toParagraphs() {
    final result = <({List<Map<String, dynamic>> runs, Map<String, dynamic> block})>[];
    var currentRuns = <Map<String, dynamic>>[];

    for (final op in ops) {
      final text = op['insert'] as String? ?? '';
      final attrs = Map<String, dynamic>.from(op['attributes'] as Map? ?? {});

      if (text == '\n') {
        // End of paragraph — commit with block attrs from this op
        result.add((runs: [...currentRuns], block: attrs));
        currentRuns = [];
      } else if (text.contains('\n')) {
        // Inline newlines (e.g. soft line breaks): split into sub-paragraphs
        final parts = text.split('\n');
        for (var pi = 0; pi < parts.length; pi++) {
          final part = parts[pi];
          if (part.isNotEmpty) {
            currentRuns.add({'insert': part, 'attributes': op['attributes']});
          }
          if (pi < parts.length - 1) {
            result.add((runs: [...currentRuns], block: <String, dynamic>{}));
            currentRuns = [];
          }
        }
      } else if (text.isNotEmpty) {
        currentRuns.add({'insert': text, 'attributes': attrs});
      }
    }

    // Flush any trailing runs without a closing \n
    if (currentRuns.isNotEmpty) {
      result.add((runs: currentRuns, block: {}));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final paragraphs = _toParagraphs();
    if (paragraphs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) => _buildPara(para.runs, para.block, context)).toList(),
    );
  }

  Widget _buildPara(
    List<Map<String, dynamic>> runs,
    Map<String, dynamic> block,
    BuildContext context,
  ) {
    if (runs.isEmpty) return const SizedBox(height: 4);

    final headerLevel = block['header'] as int?;
    final colorScheme = Theme.of(context).colorScheme;
    final baseStyle = _blockStyle(headerLevel, colorScheme);

    final spans = runs.map((run) {
      final text = run['insert'] as String? ?? '';
      final attrs = Map<String, dynamic>.from(run['attributes'] as Map? ?? {});
      return TextSpan(text: text, style: baseStyle.merge(_inlineStyle(attrs)));
    }).toList();

    EdgeInsets padding;
    if (headerLevel == 1) {
      padding = const EdgeInsets.only(top: 12, bottom: 4);
    } else if (headerLevel != null) {
      padding = const EdgeInsets.only(top: 8, bottom: 2);
    } else {
      padding = const EdgeInsets.only(bottom: 3);
    }

    return Padding(
      padding: padding,
      child: Text.rich(TextSpan(children: spans)),
    );
  }

  TextStyle _blockStyle(int? headerLevel, ColorScheme colorScheme) => switch (headerLevel) {
        1 => TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: colorScheme.onSurface,
          ),
        2 => TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: colorScheme.onSurface,
          ),
        3 => TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: colorScheme.onSurface,
          ),
        4 || 5 || 6 => TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.45,
            color: colorScheme.onSurface,
          ),
        _ => TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            height: 1.65,
            color: colorScheme.onSurface,
          ),
      };

  TextStyle _inlineStyle(Map<String, dynamic> attrs) {
    TextDecoration? decoration;
    final underline = attrs['underline'] == true;
    final strike = attrs['strike'] == true;
    if (underline && strike) {
      decoration = TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]);
    } else if (underline) {
      decoration = TextDecoration.underline;
    } else if (strike) {
      decoration = TextDecoration.lineThrough;
    }

    return TextStyle(
      fontWeight: attrs['bold'] == true ? FontWeight.w700 : null,
      fontStyle: attrs['italic'] == true ? FontStyle.italic : null,
      decoration: decoration,
    );
  }
}

// ── wawancara renderer ────────────────────────────────────────────────────────

class _WawancaraView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _WawancaraView({required this.data});

  @override
  Widget build(BuildContext context) {
    final question = data['question'] as String? ?? '';
    final answer = data['answer'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.isNotEmpty) ...[
          Text(
            question,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 8),
        ],
        if (answer.isNotEmpty)
          Text(
            answer,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          )
        else
          Text(
            '(belum dijawab)',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

// ── checklist renderer ────────────────────────────────────────────────────────

class _ChecklistView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ChecklistView({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final raw = data['items'];
    final items = raw is List ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ...items.map((item) {
          final checked = item['checked'] == true;
          final text = item['text'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: checked ? const Color(0xFF43A047) : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      color: checked ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── tabel renderer ────────────────────────────────────────────────────────────

class _TabelView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TabelView({required this.data});

  static const _hPad = 10.0;
  static const _vPad = 7.0;
  static const _fontSize = 12.0;
  static const _minColWidth = 48.0;
  static const _maxColWidth = 240.0;

  /// Measures the rendered width of [text] using the given [style].
  double _measureText(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return tp.width;
  }

  /// Returns the ideal width for each column based on its widest cell content.
  List<double> _computeColumnWidths(
    List<String> headers,
    List<List<String>> rows,
  ) {
    const headerStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: _fontSize,
      fontWeight: FontWeight.w600,
    );
    const bodyStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: _fontSize,
    );

    return List.generate(headers.length, (col) {
      double max = _measureText(headers[col], headerStyle);
      for (final row in rows) {
        if (col < row.length) {
          final w = _measureText(row[col], bodyStyle);
          if (w > max) max = w;
        }
      }
      final width = (max + _hPad * 2).clamp(_minColWidth, _maxColWidth);
      return width;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawHeaders = data['headers'];
    final rawRows = data['rows'];
    final headers = rawHeaders is List ? rawHeaders.cast<String>() : <String>[];
    final rows = rawRows is List ? rawRows.map((r) => (r as List).cast<String>()).toList() : <List<String>>[];

    if (headers.isEmpty) {
      return const Text(
        '(tabel kosong)',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final colCount = headers.length;
    final colWidths = _computeColumnWidths(headers, rows);
    final totalWidth = colWidths.fold(0.0, (a, b) => a + b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // If all columns fit, expand them proportionally to fill the available width
        final columnWidths = <int, TableColumnWidth>{};
        if (totalWidth <= availableWidth) {
          // Distribute extra space proportionally
          final scale = availableWidth / totalWidth;
          for (var i = 0; i < colCount; i++) {
            columnWidths[i] = FixedColumnWidth(colWidths[i] * scale);
          }
        } else {
          // Table is wider than screen — use measured widths and allow scroll
          for (var i = 0; i < colCount; i++) {
            columnWidths[i] = FixedColumnWidth(colWidths[i]);
          }
        }

        final table = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Table(
            border: TableBorder.all(
              color: colorScheme.outlineVariant,
            ),
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(color: colorScheme.primaryContainer),
                children: headers.map((h) => _cell(h, bold: true, colorScheme: colorScheme)).toList(),
              ),
              // Data rows with alternating background
              ...rows.asMap().entries.map((entry) {
                final isEven = entry.key.isEven;
                final row = entry.value;
                final cells = List.generate(
                  colCount,
                  (i) => i < row.length ? row[i] : '',
                );
                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? colorScheme.surface : colorScheme.surfaceContainerLow,
                  ),
                  children: cells.map((c) => _cell(c, colorScheme: colorScheme)).toList(),
                );
              }),
            ],
          ),
        );

        if (totalWidth > availableWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: totalWidth, child: table),
          );
        }
        return table;
      },
    );
  }

  Widget _cell(String text, {bool bold = false, required ColorScheme colorScheme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: _fontSize,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ── pilihanGanda renderer ─────────────────────────────────────────────────────

class _PilihanGandaView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PilihanGandaView({required this.data});

  @override
  Widget build(BuildContext context) {
    final rawQs = data['questions'];
    final questions = rawQs is List ? rawQs.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];

    if (questions.isEmpty) {
      return Text(
        '(tidak ada pertanyaan)',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.asMap().entries.map((entry) {
        final qi = entry.key;
        final q = entry.value;
        final question = q['question'] as String? ?? '';
        final rawOpts = q['options'];
        final options = rawOpts is List ? rawOpts.cast<String>() : <String>[];
        final selected = q['selectedIndex'] as int?;

        return Padding(
          padding: EdgeInsets.only(top: qi == 0 ? 0 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (question.isNotEmpty)
                Text(
                  '${qi + 1}. $question',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 6),
              ...options.asMap().entries.map((oe) {
                final isSelected = selected == oe.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 17,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          oe.value,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── tandaTangan renderer ──────────────────────────────────────────────────────

class _TandaTanganView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TandaTanganView({required this.data});

  @override
  Widget build(BuildContext context) {
    final label = data['label'] as String? ?? '';
    final signerName = data['signerName'] as String? ?? '';
    final hasSig = data['signatureBase64'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasSig ? Icons.draw : Icons.draw_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                hasSig ? 'Tanda tangan tersedia' : 'Belum ditandatangani',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontStyle: hasSig ? FontStyle.normal : FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (signerName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Penanda tangan: $signerName',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ── gambar renderer ───────────────────────────────────────────────────────────

class _GambarView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _GambarView({required this.data});

  @override
  Widget build(BuildContext context) {
    final caption = data['caption'] as String? ?? '';
    final hasImage = data['imagePath'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasImage ? Icons.image : Icons.image_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                hasImage ? 'Gambar tersedia' : 'Belum ada gambar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontStyle: hasImage ? FontStyle.normal : FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
