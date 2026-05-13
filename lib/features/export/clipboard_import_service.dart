import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../shared/models/berkas_model.dart';
import '../../shared/models/section_model.dart';

/// Parses plain text (e.g. copied from Word / any editor) into a [BerkasModel].
///
/// Parsing rules (in priority order per line):
///   Markdown heading  # / ## / ###           → teksBebas with header block attr
///   Checkbox prefix   ☑ ☐ ✓ ✗ - * 1.        → checklist items (collected consecutively)
///   Tab-separated rows (Word table copy)      → tabel section (≥2 consecutive tab lines)
///   Pipe table rows   | … | … |               → tabel section
///   Everything else                           → teksBebas (paragraphs collected
///                                               until a heading/checklist/table appears)
///
/// The very first non-empty line is used as the berkas title when it:
///   • appears before the first blank line, AND
///   • has no heading prefix, AND
///   • is ≤ 80 characters long.
class ClipboardImportService {
  static const _uuid = Uuid();

  static BerkasModel importFromText(
    String text, {
    String fallbackTitle = 'Tempel dari Clipboard',
  }) {
    // Normalise line endings (Windows \r\n, old Mac \r)
    final lines = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final sections = <SectionModel>[];
    int order = 0;
    String title = fallbackTitle;
    bool titleTaken = false;

    // Trim trailing whitespace per line; preserve leading whitespace for indented text
    final trimmed = lines.map((l) => l.trimRight()).toList();

    int i = 0;
    final buf = <String>[]; // accumulates body-text lines for a teksBebas section

    void flushBuf() {
      if (buf.isEmpty) return;
      final ops = <Map<String, dynamic>>[];
      for (final line in buf) {
        if (line.isNotEmpty) {
          ops.add({'insert': line});
        }
        ops.add({'insert': '\n'});
      }
      sections.add(SectionModel(
        id: _uuid.v4(),
        type: SectionType.teksBebas,
        order: order++,
        data: {'deltaJson': jsonEncode(ops)},
      ));
      buf.clear();
    }

    while (i < trimmed.length) {
      final line = trimmed[i];

      // ── Empty line ────────────────────────────────────────────────────────
      if (line.isEmpty) {
        i++;
        continue;
      }

      // ── Markdown heading ──────────────────────────────────────────────────
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        flushBuf();
        final level = headingMatch.group(1)!.length;
        final content = headingMatch.group(2)!.trim();
        if (!titleTaken && level == 1) {
          title = content;
          titleTaken = true;
          i++;
          continue;
        }
        final ops = [
          {'insert': content},
          {
            'insert': '\n',
            'attributes': {'header': level},
          },
        ];
        sections.add(SectionModel(
          id: _uuid.v4(),
          type: SectionType.teksBebas,
          order: order++,
          data: {'deltaJson': jsonEncode(ops)},
        ));
        i++;
        continue;
      }

      // ── Checklist / bullet list ────────────────────────────────────────────
      if (_isCheckboxOrBullet(line)) {
        flushBuf();
        final items = <Map<String, dynamic>>[];
        while (i < trimmed.length && trimmed[i].isNotEmpty && _isCheckboxOrBullet(trimmed[i])) {
          _addItem(items, trimmed[i]);
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

      // ── Tab-separated table (Word copy-paste) ─────────────────────────────
      // Word outputs table cells separated by \t; rows by \n.
      // Treat a block of ≥2 consecutive tab-containing lines as a table.
      if (_isTabLine(line)) {
        // Collect consecutive tab lines (allow 1 empty line gap in case of
        // copy artefacts, but stop on 2 empty lines or non-tab content)
        int j = i + 1;
        while (j < trimmed.length) {
          final next = trimmed[j];
          if (next.isEmpty) break; // stop at empty line
          if (!_isTabLine(next)) break; // stop at non-tab line
          j++;
        }
        final tableLines = trimmed.sublist(i, j);
        if (tableLines.length >= 2) {
          flushBuf();
          final tbl = _parseTabTable(tableLines);
          if (tbl != null) {
            sections.add(SectionModel(
              id: _uuid.v4(),
              type: SectionType.tabel,
              order: order++,
              data: tbl,
            ));
            i = j;
            continue;
          }
        }
        // Only 1 tab line → fall through to body paragraph
      }

      // ── Pipe table ────────────────────────────────────────────────────────
      if (_isPipeLine(line)) {
        flushBuf();
        final tableLines = <String>[];
        while (i < trimmed.length && trimmed[i].isNotEmpty && _isPipeLine(trimmed[i])) {
          tableLines.add(trimmed[i]);
          i++;
        }
        final tbl = _parsePipeTable(tableLines);
        if (tbl != null) {
          sections.add(SectionModel(
            id: _uuid.v4(),
            type: SectionType.tabel,
            order: order++,
            data: tbl,
          ));
        }
        continue;
      }

      // ── Space-separated table (mobile Word/Sheets copy-paste) ──────────────
      // Mobile apps often pad table cells with 2+ spaces instead of \t.
      // Look ahead: if this + next lines all split into the same column count
      // (≥2) by 2+ spaces, treat the whole block as a table.
      final spaceTableResult = _detectSpaceTableBlock(trimmed, i);
      if (spaceTableResult != null) {
        flushBuf();
        final tbl = _parseSpaceTable(spaceTableResult.$1);
        if (tbl != null) {
          sections.add(SectionModel(
            id: _uuid.v4(),
            type: SectionType.tabel,
            order: order++,
            data: tbl,
          ));
          i = spaceTableResult.$2;
          continue;
        }
      }

      // ── One-cell-per-line table (mobile Word table copy) ──────────────────
      // Word for Android/iOS copies each cell as its own line, e.g.:
      //   No          ← header col 1
      //   Nama        ← header col 2
      //   1           ← data row 1 col 1
      //   Ahmad       ← data row 1 col 2
      // Heuristic: N consecutive short lines where N%C==0 (C=2..6) AND
      // the first-column of data rows forms a sequential int list 1,2,3...
      final cellLineResult = _detectCellPerLineTable(trimmed, i);
      if (cellLineResult != null) {
        flushBuf();
        final tbl = _parseCellPerLineTable(cellLineResult.$1, cellLineResult.$3);
        if (tbl != null) {
          sections.add(SectionModel(
            id: _uuid.v4(),
            type: SectionType.tabel,
            order: order++,
            data: tbl,
          ));
          i = cellLineResult.$2;
          continue;
        }
      }

      // ── Wawancara (Q&A) ──────────────────────────────────────────────────
      // Heuristic 1: line contains '?' with text after it → Q?A split.
      // Heuristic 2: short label before first ':' (≤80 chars) with value ≥5 chars.
      // Applies to long concatenated lines from mobile forms.
      final wawancaraData = _detectWawancara(line);
      if (wawancaraData != null) {
        flushBuf();
        sections.add(SectionModel(
          id: _uuid.v4(),
          type: SectionType.wawancara,
          order: order++,
          data: wawancaraData,
        ));
        i++;
        continue;
      }

      // ── Body paragraph ────────────────────────────────────────────────────
      if (!titleTaken && buf.isEmpty) {
        final rest = i + 1 < trimmed.length ? trimmed[i + 1] : '';
        if (line.length <= 80 && rest.isEmpty) {
          title = line.trim();
          titleTaken = true;
          i++;
          continue;
        }
      }
      buf.add(line);
      i++;
    }

    flushBuf();

    final now = DateTime.now();
    return BerkasModel(
      id: _uuid.v4(),
      title: title,
      categoryId: '',
      iconName: '📋',
      colorTag: '#B2EBF2',
      createdAt: now,
      updatedAt: now,
      sections: sections,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static const _checkboxChars = {'☑', '☒', '☐', '✓', '✔', '✗', '✘'};

  static bool _isCheckboxOrBullet(String line) {
    if (line.isEmpty) return false;
    final first = line.substring(0, 1);
    if (_checkboxChars.contains(first)) return true;
    if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('• ')) return true;
    if (RegExp(r'^\d+[.)]\s').hasMatch(line)) return true;
    return false;
  }

  /// Returns true if [line] looks like a tab-delimited table row.
  /// Must contain at least one \t and at least 2 non-empty cells.
  static bool _isTabLine(String line) {
    if (!line.contains('\t')) return false;
    final cells = line.split('\t').where((c) => c.trim().isNotEmpty).toList();
    return cells.length >= 2;
  }

  static bool _isPipeLine(String line) {
    return line.startsWith('|') && line.endsWith('|') && line.contains('|', 1);
  }

  /// Returns `{question, answer}` if [line] looks like a Q&A concatenation,
  /// otherwise null.
  static Map<String, dynamic>? _detectWawancara(String line) {
    if (line.length < 10) return null;
    if (line.startsWith('http://') || line.startsWith('https://')) return null;
    // Heuristic 1: contains '?' not at end
    final qIdx = line.indexOf('?');
    if (qIdx > 0 && qIdx < line.length - 1) {
      final answer = line.substring(qIdx + 1).trim();
      if (answer.isNotEmpty) {
        return {
          'question': line.substring(0, qIdx + 1).trim(),
          'answer': answer,
        };
      }
    }
    // Heuristic 2: short label:value (mobile form label-answer pattern)
    final cIdx = line.indexOf(':');
    if (cIdx > 0 && cIdx <= 80) {
      final label = line.substring(0, cIdx).trim();
      final value = line.substring(cIdx + 1).trim();
      if (label.isNotEmpty && !label.contains('?') && value.length >= 5) {
        return {'question': '$label:', 'answer': value};
      }
    }
    return null;
  }

  /// Looks ahead from [start] to find a block of consecutive non-empty lines
  /// that ALL split into the SAME column count (≥2) when split by 2+ spaces.
  /// Returns (lines, endIndex) if found, null otherwise.
  static (List<String>, int)? _detectSpaceTableBlock(List<String> trimmed, int start) {
    // Collect consecutive non-empty lines
    final candidates = <String>[];
    int end = start;
    while (end < trimmed.length && trimmed[end].isNotEmpty) {
      candidates.add(trimmed[end]);
      end++;
    }
    if (candidates.length < 2) return null;

    final splitPattern = RegExp(r'  +'); // 2+ spaces

    // Compute cell count per line
    final counts = candidates.map((l) {
      return l.split(splitPattern).map((c) => c.trim()).where((c) => c.isNotEmpty).length;
    }).toList();

    final firstCount = counts.first;
    if (firstCount < 2) return null;

    // ALL lines must produce exactly the same column count
    if (counts.any((c) => c != firstCount)) return null;

    return (candidates, end);
  }

  /// Parses space-separated lines (mobile table paste) into `{headers, rows}`.
  static Map<String, dynamic>? _parseSpaceTable(List<String> lines) {
    if (lines.length < 2) return null;
    final splitPattern = RegExp(r'  +');

    final headers = lines.first.split(splitPattern).map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    final colCount = headers.length;
    if (colCount < 2) return null;

    final rows = <List<String>>[];
    for (var r = 1; r < lines.length; r++) {
      final cells = lines[r].split(splitPattern).map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
      final row = List<String>.filled(colCount, '');
      for (var j = 0; j < colCount && j < cells.length; j++) {
        row[j] = cells[j];
      }
      rows.add(row);
    }
    return {'headers': headers, 'rows': rows};
  }

  /// Detects a block where each cell is on its own line (mobile Word table).
  /// Returns (lines, endIndex, colCount) or null.
  static (List<String>, int, int)? _detectCellPerLineTable(List<String> trimmed, int start) {
    final candidates = <String>[];
    int end = start;
    while (end < trimmed.length) {
      final l = trimmed[end];
      if (l.isEmpty) break;
      if (l.length > 100) return null; // long line → not a table cell
      candidates.add(l);
      end++;
    }
    final n = candidates.length;
    if (n < 6) return null; // minimum: 2 cols × 3 rows (header + 2 data)

    for (int c = 2; c <= 6; c++) {
      if (n % c != 0) continue;
      final numRows = n ~/ c; // includes header row
      if (numRows < 3) continue; // need header + ≥2 data rows

      // First-column of data rows must be sequential: 1, 2, 3...
      bool sequential = true;
      for (int row = 1; row < numRows; row++) {
        if (candidates[row * c].trim() != '$row') {
          sequential = false;
          break;
        }
      }
      if (sequential) return (candidates, end, c);
    }
    return null;
  }

  /// Parses a one-cell-per-line block into `{headers, rows}`.
  static Map<String, dynamic>? _parseCellPerLineTable(List<String> lines, int colCount) {
    if (lines.length < colCount * 2) return null;
    final headers = lines.sublist(0, colCount).map((l) => l.trim()).toList();
    final rows = <List<String>>[];
    for (int r = colCount; r < lines.length; r += colCount) {
      final row = <String>[];
      for (int c = 0; c < colCount; c++) {
        row.add(r + c < lines.length ? lines[r + c].trim() : '');
      }
      rows.add(row);
    }
    return {'headers': headers, 'rows': rows};
  }

  static void _addItem(List<Map<String, dynamic>> items, String raw) {
    final first = raw.isEmpty ? '' : raw.substring(0, 1);
    final checked = first == '☑' || first == '✓' || first == '✔' || first == '☒';
    final cleaned = raw.replaceAll(RegExp(r'^[☑☒☐✓✔✗✘●○•\-\*]\s*'), '').replaceAll(RegExp(r'^\d+[.)]\s+'), '').trim();
    items.add({
      'id': _uuid.v4(),
      'text': cleaned.isEmpty ? raw.trim() : cleaned,
      'checked': checked,
    });
  }

  /// Parses tab-separated lines (Word table copy-paste) into `{headers, rows}`.
  /// First line → headers; remaining lines → data rows.
  /// Infers consistent column count from the most common tab count.
  static Map<String, dynamic>? _parseTabTable(List<String> lines) {
    if (lines.length < 2) return null;

    // Split each line into cells, keeping empty cells for alignment
    List<List<String>> allRows = lines.map((l) => l.split('\t').map((c) => c.trim()).toList()).toList();

    // Determine target column count: use the maximum from header row
    final colCount = allRows.first.length;
    if (colCount < 2) return null;

    final headers = allRows.first;
    final rows = <List<String>>[];
    for (var r = 1; r < allRows.length; r++) {
      final row = List<String>.filled(colCount, '');
      for (var j = 0; j < colCount && j < allRows[r].length; j++) {
        row[j] = allRows[r][j];
      }
      rows.add(row);
    }

    return {'headers': headers, 'rows': rows};
  }

  /// Parses pipe-delimited table lines into `{headers, rows}`.
  /// Skips separator lines (e.g. `| --- | --- |`).
  static Map<String, dynamic>? _parsePipeTable(List<String> lines) {
    if (lines.isEmpty) return null;

    List<String>? headers;
    final rows = <List<String>>[];

    for (final line in lines) {
      final cells = line.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
      if (cells.isEmpty) continue;
      if (cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c))) continue;

      if (headers == null) {
        headers = cells;
      } else {
        final row = List<String>.filled(headers.length, '');
        for (var j = 0; j < headers.length && j < cells.length; j++) {
          row[j] = cells[j];
        }
        rows.add(row);
      }
    }

    if (headers == null) return null;
    return {'headers': headers, 'rows': rows};
  }
}
