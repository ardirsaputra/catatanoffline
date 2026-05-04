import 'package:flutter/material.dart';
import '../../../../shared/models/section_model.dart';

class EsaiWidget extends StatefulWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;

  const EsaiWidget(
      {super.key, required this.section, required this.onChanged});

  @override
  State<EsaiWidget> createState() => _EsaiWidgetState();
}

class _EsaiWidgetState extends State<EsaiWidget> {
  late final TextEditingController _questionCtrl;
  late final TextEditingController _answerCtrl;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(
        text: widget.section.data['question'] as String? ?? '');
    _answerCtrl = TextEditingController(
        text: widget.section.data['answer'] as String? ?? '');
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged(widget.section.copyWith(data: {
      'question': _questionCtrl.text,
      'answer': _answerCtrl.text,
    }));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _questionCtrl,
            onChanged: (_) => _update(),
            style: TextStyle(fontFamily: 'Poppins', 
                fontWeight: FontWeight.w600, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Tulis pertanyaan esai...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              filled: false,
            ),
            maxLines: null,
          ),
        ),
        const SizedBox(height: 12),
        // Answer area
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: TextField(
            controller: _answerCtrl,
            onChanged: (_) => _update(),
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, height: 1.7),
            decoration: const InputDecoration(
              hintText: 'Tulis jawaban esai di sini...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              filled: false,
            ),
            maxLines: null,
            minLines: 5,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_answerCtrl.text.length} karakter',
              style: TextStyle(fontFamily: 'Poppins', 
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
