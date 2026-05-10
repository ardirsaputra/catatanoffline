import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../../../../shared/models/section_model.dart';

class TeksBebasWidget extends StatefulWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;

  const TeksBebasWidget({super.key, required this.section, required this.onChanged});

  @override
  State<TeksBebasWidget> createState() => _TeksBebasWidgetState();
}

class _TeksBebasWidgetState extends State<TeksBebasWidget> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

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
        final doc = quill.Document.fromJson(jsonDecode(deltaJson) as List);
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
              showStrikeThrough: false,
              showInlineCode: false,
              showColorButton: true,
              showBackgroundColorButton: false,
              showClearFormat: true,
              showAlignmentButtons: true,
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
        const SizedBox(height: 6),
        // Editor
        Container(
          constraints: const BoxConstraints(
            minHeight: 100,
            maxHeight: 420,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                autoFocus: false,
                expands: false,
                scrollable: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
