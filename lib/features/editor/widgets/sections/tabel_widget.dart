import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/models/section_model.dart';
import 'package:uuid/uuid.dart';

class TabelWidget extends StatefulWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;

  const TabelWidget(
      {super.key, required this.section, required this.onChanged});

  @override
  State<TabelWidget> createState() => _TabelWidgetState();
}

class _TabelWidgetState extends State<TabelWidget> {
  static const _uuid = Uuid();
  late List<String> _headers;
  late List<List<String>> _rows;

  // Cell controllers: [row][col]
  late List<List<TextEditingController>> _rowControllers;
  late List<TextEditingController> _headerControllers;

  @override
  void initState() {
    super.initState();
    _headers = List<String>.from(
        widget.section.data['headers'] as List? ?? ['Kolom 1']);
    _rows = (widget.section.data['rows'] as List? ?? [])
        .map((row) => List<String>.from(row as List))
        .toList();
    if (_rows.isEmpty) _rows.add(List.filled(_headers.length, ''));
    _initControllers();
  }

  void _initControllers() {
    _headerControllers = _headers
        .map((h) => TextEditingController(text: h))
        .toList();
    _rowControllers = _rows
        .map((row) =>
            row.map((cell) => TextEditingController(text: cell)).toList())
        .toList();
  }

  @override
  void dispose() {
    for (final c in _headerControllers) {
      c.dispose();
    }
    for (final row in _rowControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _update() {
    widget.onChanged(widget.section.copyWith(data: {
      'headers': _headers,
      'rows': _rows,
    }));
  }

  void _addColumn() {
    setState(() {
      _headers.add('Kolom ${_headers.length + 1}');
      _headerControllers
          .add(TextEditingController(text: _headers.last));
      for (var i = 0; i < _rows.length; i++) {
        _rows[i].add('');
        _rowControllers[i].add(TextEditingController(text: ''));
      }
    });
    _update();
  }

  void _removeColumn(int colIdx) {
    if (_headers.length <= 1) return;
    setState(() {
      _headerControllers[colIdx].dispose();
      _headerControllers.removeAt(colIdx);
      _headers.removeAt(colIdx);
      for (var i = 0; i < _rows.length; i++) {
        _rowControllers[i][colIdx].dispose();
        _rowControllers[i].removeAt(colIdx);
        _rows[i].removeAt(colIdx);
      }
    });
    _update();
  }

  void _addRow() {
    setState(() {
      _rows.add(List.filled(_headers.length, ''));
      _rowControllers.add(
          List.generate(_headers.length, (_) => TextEditingController()));
    });
    _update();
  }

  void _removeRow(int rowIdx) {
    if (_rows.length <= 1) return;
    setState(() {
      for (final c in _rowControllers[rowIdx]) {
        c.dispose();
      }
      _rowControllers.removeAt(rowIdx);
      _rows.removeAt(rowIdx);
    });
    _update();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const cellWidth = 120.0;
    const cellHeight = 44.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action buttons
        Row(
          children: [
            TextButton.icon(
              onPressed: _addColumn,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Kolom', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4)),
            ),
            TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Baris', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Scrollable table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    ..._headers.asMap().entries.map((entry) {
                      final colIdx = entry.key;
                      return _buildHeaderCell(
                        colIdx,
                        cellWidth,
                        cellHeight,
                        colorScheme,
                      );
                    }),
                    // Remove column button placeholder
                    SizedBox(
                        width: 28,
                        height: cellHeight,
                        child: const SizedBox()),
                  ],
                ),
                // Data rows
                ..._rows.asMap().entries.map((rowEntry) {
                  final rowIdx = rowEntry.key;
                  return Row(
                    children: [
                      ..._headers.asMap().entries.map((colEntry) {
                        final colIdx = colEntry.key;
                        return _buildDataCell(
                            rowIdx, colIdx, cellWidth, cellHeight, colorScheme);
                      }),
                      // Remove row button
                      SizedBox(
                        width: 28,
                        height: cellHeight,
                        child: _rows.length > 1
                            ? IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    size: 16, color: colorScheme.error),
                                onPressed: () => _removeRow(rowIdx),
                                padding: EdgeInsets.zero,
                              )
                            : const SizedBox(),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(
      int colIdx, double w, double h, ColorScheme cs) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.15),
        border: Border.all(color: cs.outline.withOpacity(0.5)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: TextField(
                controller: _headerControllers[colIdx],
                onChanged: (v) {
                  _headers[colIdx] = v;
                  _update();
                },
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  filled: false,
                ),
              ),
            ),
          ),
          if (_headers.length > 1)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _removeColumn(colIdx),
                child: Icon(Icons.close,
                    size: 12, color: cs.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataCell(
      int rowIdx, int colIdx, double w, double h, ColorScheme cs) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: rowIdx.isEven
            ? Colors.transparent
            : cs.surfaceContainerHighest.withOpacity(0.3),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: TextField(
          controller: _rowControllers[rowIdx][colIdx],
          onChanged: (v) {
            _rows[rowIdx][colIdx] = v;
            _update();
          },
          style: GoogleFonts.poppins(fontSize: 12),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            filled: false,
          ),
        ),
      ),
    );
  }
}
