import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../../../../shared/models/section_model.dart';

class TeksBebasWidget extends StatefulWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;

  const TeksBebasWidget(
      {super.key, required this.section, required this.onChanged});

  @override
  State<TeksBebasWidget> createState() => _TeksBebasWidgetState();
}

class _TeksBebasWidgetState extends State<TeksBebasWidget> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
    _controller.addListener(_onContentChanged);
  }

  quill.QuillController _buildController() {
    final deltaJson = widget.section.data['deltaJson'] as String?;
    if (deltaJson != null && deltaJson.isNotEmpty) {
      try {
        final doc =
            quill.Document.fromJson(jsonDecode(deltaJson) as List);
        return quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {}
    }
    return quill.QuillController.basic();
  }

  void _onContentChanged() {
    final delta = _controller.document.toDelta().toJson();
    widget.onChanged(widget.section.copyWith(data: {
      'deltaJson': jsonEncode(delta),
    }));
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: quill.QuillSimpleToolbar(
            configurations: quill.QuillSimpleToolbarConfigurations(
              controller: _controller,
              toolbarIconAlignment: WrapAlignment.start,
              showFontFamily: false,
              showFontSize: false,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showInlineCode: false,
              showColorButton: true,
              showBackgroundColorButton: false,
              showClearFormat: true,
              showAlignmentButtons: false,
              showHeaderStyle: true,
              showListNumbers: true,
              showListBullets: true,
              showListCheck: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showLink: false,
              showUndo: true,
              showRedo: true,
              showSearchButton: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Editor
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            minHeight: 120,
            maxHeight: _expanded ? 600 : 240,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: quill.QuillEditor(
              focusNode: _focusNode,
              scrollController: _scrollController,
              configurations: quill.QuillEditorConfigurations(
                controller: _controller,
                padding: const EdgeInsets.all(12),
                autoFocus: false,
                expands: false,
                scrollable: true,
                placeholder: 'Tulis teks bebas di sini...',
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.unfold_less : Icons.unfold_more,
              size: 16,
            ),
            label: Text(
              _expanded ? 'Perkecil' : 'Perbesar',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
}
