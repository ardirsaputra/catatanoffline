import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
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
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: quill.QuillSimpleToolbar(
            controller: _controller,
            configurations: quill.QuillSimpleToolbarConfigurations(
              toolbarIconAlignment: WrapAlignment.start,
              showFontFamily: false,
              showFontSize: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showInlineCode: false,
              showColorButton: true,
              showBackgroundColorButton: false,
              showClearFormat: true,
              showAlignmentButtons: true,
              showLeftAlignment: true,
              showCenterAlignment: true,
              showRightAlignment: true,
              showJustifyAlignment: false,
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
              buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                base: quill.QuillToolbarBaseButtonOptions(
                  iconSize: 18,
                ),
              ),
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
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: quill.QuillEditor(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              configurations: quill.QuillEditorConfigurations(
                padding: const EdgeInsets.all(12),
                autoFocus: false,
                expands: false,
                scrollable: true,
                placeholder: 'Tulis teks bebas di sini...',
                customStyles: quill.DefaultStyles(
                  paragraph: quill.DefaultTextBlockStyle(
                    GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                    const quill.HorizontalSpacing(0, 0),
                    const quill.VerticalSpacing(0, 0),
                    const quill.VerticalSpacing(0, 0),
                    null,
                  ),
                ),
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
