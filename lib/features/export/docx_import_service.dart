import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../../shared/models/berkas_model.dart';
import '../../shared/models/section_model.dart';

/// Converts a .docx file into a [BerkasModel] with sections.
///
/// Mapping rules:
///   Title / Heading1 (first)  → berkas title
///   Any heading after first   → new teksBebas section with header delta attribute
///   Following body paragraphs → appended to same teksBebas (with inline formatting)
///   Table (w:tbl)             → tabel section
///   List paragraphs (numPr)   → checklist section
class DocxImportService {
  static const _uuid = Uuid();

  static Future<BerkasModel?> importFromPath(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final raw = filePath.split('/').last.split('\\').last;
      final nameFromFile = raw.replaceAll(RegExp(r'\.(docx?|doc)$', caseSensitive: false), '').replaceAll('_', ' ').replaceAll('-', ' ').trim();
      return _parse(bytes, fallbackTitle: nameFromFile.isEmpty ? 'Berkas dari Word' : nameFromFile);
    } catch (_) {
      return null;
    }
  }

  // ── Core parser ─────────────────────────────────────────────────────────────

  static BerkasModel? _parse(Uint8List bytes, {required String fallbackTitle}) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docEntry = archive.findFile('word/document.xml');
      if (docEntry == null) return null;

      final xmlStr = utf8.decode(docEntry.content as List<int>);
      final xmlDoc = XmlDocument.parse(xmlStr);

      final body = xmlDoc.findAllElements('w:body').firstOrNull;
      if (body == null) return null;

      String title = fallbackTitle;
      final sections = <SectionModel>[];
      int order = 0;

      final children = body.childElements.toList();
      int i = 0;

      while (i < children.length) {
        final el = children[i];

        if (el.name.local == 'p') {
          final style = _style(el);
          final text = _text(el).trim();

          // First Title/Heading1 → berkas title (unchanged)
          if ((style == 'Title' || style == 'Heading1') && sections.isEmpty) {
            if (text.isNotEmpty) title = text;
            i++;
            continue;
          }

          // Skip blank paragraphs between other blocks
          if (text.isEmpty) {
            i++;
            continue;
          }

          // List paragraph (numPr or Unicode checkbox) → checklist (collect consecutive)
          if (_isList(el) || _isCheckboxText(text)) {
            final items = <Map<String, dynamic>>[];
            _addItem(items, text);
            i++;
            while (i < children.length) {
              final next = children[i];
              if (next.name.local != 'p') break;
              final nt = _text(next).trim();
              if (!_isList(next) && !_isCheckboxText(nt)) break;
              if (nt.isNotEmpty) _addItem(items, nt);
              i++;
            }
            sections.add(SectionModel(
              id: _uuid.v4(),
              type: SectionType.checklist,
              order: order++,
              data: {'title': 'Daftar Periksa', 'items': items},
            ));
            continue;
          }

          // Heading or body paragraph → rich teksBebas with inline formatting.
          // Each heading starts a NEW section; following non-heading body paras
          // are collected into the same section.
          final allOps = <Map<String, dynamic>>[..._paragraphToOps(el)];
          i++;
          while (i < children.length) {
            final next = children[i];
            if (next.name.local != 'p') break; // table stops the block
            if (_isList(next) || _isCheckboxText(_text(next).trim())) break; // list starts its own section
            if (_isHeading(_style(next))) break; // next heading starts new section
            final ops = _paragraphToOps(next);
            if (ops.isNotEmpty) {
              allOps.addAll(ops);
            } else {
              allOps.add({'insert': '\n'}); // empty paragraph = blank line
            }
            i++;
          }
          if (allOps.isNotEmpty) {
            sections.add(SectionModel(
              id: _uuid.v4(),
              type: SectionType.teksBebas,
              order: order++,
              data: {'deltaJson': jsonEncode(allOps)},
            ));
          }
        } else if (el.name.local == 'tbl') {
          final tbl = _parseTable(el);
          if (tbl != null) {
            sections.add(SectionModel(
              id: _uuid.v4(),
              type: SectionType.tabel,
              order: order++,
              data: tbl,
            ));
          }
          i++;
        } else {
          i++;
        }
      }

      final now = DateTime.now();
      return BerkasModel(
        id: _uuid.v4(),
        title: title.isEmpty ? fallbackTitle : title,
        categoryId: '',
        iconName: '📄',
        colorTag: '#A8D8EA',
        createdAt: now,
        updatedAt: now,
        sections: sections,
      );
    } catch (_) {
      return null;
    }
  }

  // ── XML helpers ──────────────────────────────────────────────────────────────

  // ── Paragraph → Quill-delta ops ─────────────────────────────────────────────

  /// Converts a `<w:p>` element into a list of Quill delta ops.
  /// Each op is `{insert: text}` or `{insert: text, attributes: {...}}`.
  /// The paragraph is terminated by a `{insert: '\n'}` op that may carry
  /// block-level attributes (e.g. `{header: 1}`).
  static List<Map<String, dynamic>> _paragraphToOps(XmlElement p) {
    final style = _style(p);
    final ops = <Map<String, dynamic>>[];

    for (final child in p.childElements) {
      if (child.name.local == 'r') {
        _addRunOps(ops, child);
      } else if (child.name.local == 'hyperlink') {
        for (final hc in child.childElements) {
          if (hc.name.local == 'r') _addRunOps(ops, hc);
        }
      }
    }

    if (ops.isEmpty) return ops;

    final block = _blockAttrs(style);
    ops.add(block.isEmpty ? {'insert': '\n'} : {'insert': '\n', 'attributes': block});
    return ops;
  }

  /// Extracts text and inline formatting from a single `<w:r>` run.
  static void _addRunOps(List<Map<String, dynamic>> ops, XmlElement run) {
    final buf = StringBuffer();
    for (final child in run.childElements) {
      if (child.name.local == 't') {
        buf.write(child.innerText);
      } else if (child.name.local == 'tab') {
        buf.write('\t');
      } else if (child.name.local == 'br') {
        // Soft line break: flush buffered text then add bare newline
        final t = buf.toString();
        if (t.isNotEmpty) {
          buf.clear();
          final attrs = _runAttrs(run);
          ops.add(attrs.isEmpty ? {'insert': t} : {'insert': t, 'attributes': attrs});
        }
        ops.add({'insert': '\n'});
      }
    }
    final t = buf.toString();
    if (t.isEmpty) return;
    final attrs = _runAttrs(run);
    ops.add(attrs.isEmpty ? {'insert': t} : {'insert': t, 'attributes': attrs});
  }

  /// Extracts bold / italic / underline / strikethrough from `<w:rPr>`.
  static Map<String, dynamic> _runAttrs(XmlElement run) {
    final attrs = <String, dynamic>{};
    for (final child in run.childElements) {
      if (child.name.local != 'rPr') continue;
      for (final prop in child.childElements) {
        switch (prop.name.local) {
          case 'b':
            if (prop.getAttribute('w:val') != '0') attrs['bold'] = true;
          case 'i':
            if (prop.getAttribute('w:val') != '0') attrs['italic'] = true;
          case 'u':
            final uv = prop.getAttribute('w:val');
            if (uv != null && uv != 'none') attrs['underline'] = true;
          case 'strike':
            if (prop.getAttribute('w:val') != '0') attrs['strike'] = true;
        }
      }
    }
    return attrs;
  }

  /// Maps a paragraph style name to Quill block attributes.
  static Map<String, dynamic> _blockAttrs(String style) {
    return switch (style) {
      'Title' || 'Heading1' => {'header': 1},
      'Heading2' => {'header': 2},
      'Heading3' => {'header': 3},
      'Heading4' => {'header': 4},
      'Heading5' => {'header': 5},
      'Heading6' => {'header': 6},
      _ => {},
    };
  }

  static bool _isHeading(String style) => style == 'Title' || style.startsWith('Heading');

  // ── XML helpers ──────────────────────────────────────────────────────────────

  static String _style(XmlElement p) {
    for (final c in p.childElements) {
      if (c.name.local == 'pPr') {
        for (final cc in c.childElements) {
          if (cc.name.local == 'pStyle') {
            return cc.getAttribute('w:val') ?? 'Normal';
          }
        }
      }
    }
    return 'Normal';
  }

  static bool _isList(XmlElement p) {
    for (final c in p.childElements) {
      if (c.name.local == 'pPr') {
        for (final cc in c.childElements) {
          if (cc.name.local == 'numPr') return true;
        }
      }
    }
    return false;
  }

  /// Returns true if [text] starts with a Unicode checkbox / bullet symbol.
  static bool _isCheckboxText(String text) {
    if (text.isEmpty) return false;
    const checkboxChars = {'☑', '☒', '☐', '✓', '✔', '✗', '✘'};
    return checkboxChars.contains(text.substring(0, 1));
  }

  static String _text(XmlElement el) {
    final buf = StringBuffer();
    for (final t in el.findAllElements('w:t')) {
      buf.write(t.innerText);
    }
    return buf.toString();
  }

  static void _addItem(List<Map<String, dynamic>> items, String raw) {
    final checked = raw.startsWith('☑') || raw.startsWith('✓');
    final cleaned = raw.replaceAll(RegExp(r'^[☑☐✓✗●○•\-]\s*'), '').trim();
    items.add({
      'id': _uuid.v4(),
      'text': cleaned.isEmpty ? raw.trim() : cleaned,
      'checked': checked,
    });
  }

  static Map<String, dynamic>? _parseTable(XmlElement tbl) {
    final rows = tbl.findAllElements('w:tr').toList();
    if (rows.isEmpty) return null;

    final headers = <String>[];
    final dataRows = <List<String>>[];

    for (var ri = 0; ri < rows.length; ri++) {
      final cells = rows[ri].findAllElements('w:tc').toList();
      final texts = cells.map((c) {
        final buf = StringBuffer();
        for (final t in c.findAllElements('w:t')) {
          buf.write(t.innerText);
        }
        return buf.toString().trim();
      }).toList();
      if (ri == 0) {
        headers.addAll(texts);
      } else {
        dataRows.add(texts);
      }
    }

    if (headers.isEmpty) return null;
    return {'headers': headers, 'rows': dataRows};
  }
}
