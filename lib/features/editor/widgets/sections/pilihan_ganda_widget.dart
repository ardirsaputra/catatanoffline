import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/models/section_model.dart';
import 'package:uuid/uuid.dart';

class PilihanGandaWidget extends StatefulWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;

  const PilihanGandaWidget(
      {super.key, required this.section, required this.onChanged});

  @override
  State<PilihanGandaWidget> createState() => _PilihanGandaWidgetState();
}

class _PilihanGandaWidgetState extends State<PilihanGandaWidget> {
  static const _uuid = Uuid();
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = _loadQuestions();
  }

  List<Map<String, dynamic>> _loadQuestions() {
    final raw = widget.section.data['questions'];
    if (raw is List) {
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  void _update() {
    widget.onChanged(
        widget.section.copyWith(data: {'questions': _questions}));
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'id': _uuid.v4(),
        'question': '',
        'options': ['Opsi A', 'Opsi B'],
        'selectedIndex': null,
      });
    });
    _update();
  }

  void _removeQuestion(int qIdx) {
    setState(() => _questions.removeAt(qIdx));
    _update();
  }

  void _selectOption(int qIdx, int optIdx) {
    setState(() {
      _questions[qIdx]['selectedIndex'] =
          _questions[qIdx]['selectedIndex'] == optIdx ? null : optIdx;
    });
    _update();
  }

  void _addOption(int qIdx) {
    final options =
        List<String>.from(_questions[qIdx]['options'] as List? ?? []);
    if (options.length >= 6) return;
    setState(() {
      _questions[qIdx]['options'] = [...options, 'Opsi ${options.length + 1}'];
    });
    _update();
  }

  void _removeOption(int qIdx, int optIdx) {
    final options =
        List<String>.from(_questions[qIdx]['options'] as List? ?? []);
    if (options.length <= 2) return;
    setState(() {
      options.removeAt(optIdx);
      _questions[qIdx]['options'] = options;
      final sel = _questions[qIdx]['selectedIndex'] as int?;
      if (sel != null && sel >= options.length) {
        _questions[qIdx]['selectedIndex'] = null;
      }
    });
    _update();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._questions.asMap().entries.map((qEntry) {
          final qIdx = qEntry.key;
          final q = qEntry.value;
          final options =
              List<String>.from(q['options'] as List? ?? []);
          final selectedIndex = q['selectedIndex'] as int?;
          final questionCtrl = TextEditingController(
              text: q['question'] as String? ?? '');

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'P${qIdx + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_questions.length > 1)
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: colorScheme.error),
                        onPressed: () => _removeQuestion(qIdx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: questionCtrl,
                  onChanged: (v) {
                    _questions[qIdx]['question'] = v;
                    _update();
                  },
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Tulis pertanyaan...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    filled: false,
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: 12),
                ...options.asMap().entries.map((optEntry) {
                  final optIdx = optEntry.key;
                  final opt = optEntry.value;
                  final isSelected = selectedIndex == optIdx;
                  final optCtrl = TextEditingController(text: opt);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _selectOption(qIdx, optIdx),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.circle,
                                    size: 10, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: optCtrl,
                            onChanged: (v) {
                              final opts = List<String>.from(
                                  _questions[qIdx]['options'] as List);
                              opts[optIdx] = v;
                              _questions[qIdx]['options'] = opts;
                              _update();
                            },
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Opsi...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                              filled: false,
                            ),
                          ),
                        ),
                        if (options.length > 2)
                          IconButton(
                            icon: Icon(Icons.close,
                                size: 16,
                                color: colorScheme.onSurfaceVariant),
                            onPressed: () => _removeOption(qIdx, optIdx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  );
                }),
                if (options.length < 6)
                  TextButton.icon(
                    onPressed: () => _addOption(qIdx),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Opsi',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2)),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addQuestion,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Tambah Pertanyaan'),
        ),
      ],
    );
  }
}
