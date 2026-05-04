import 'package:flutter/material.dart';
import '../../../../shared/models/section_model.dart';

class WawancaraWidget extends StatefulWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;

  const WawancaraWidget(
      {super.key, required this.section, required this.onChanged});

  @override
  State<WawancaraWidget> createState() => _WawancaraWidgetState();
}

class _WawancaraWidgetState extends State<WawancaraWidget> {
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
        // Question field
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('P',
                  style: TextStyle(fontFamily: 'Poppins', 
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _questionCtrl,
                onChanged: (_) => _update(),
                style: TextStyle(fontFamily: 'Poppins', 
                    fontWeight: FontWeight.w600, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tulis pertanyaan...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
                maxLines: null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        // Answer field
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('J',
                  style: TextStyle(fontFamily: 'Poppins', 
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _answerCtrl,
                onChanged: (_) => _update(),
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Tulis jawaban...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
                maxLines: null,
                minLines: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
