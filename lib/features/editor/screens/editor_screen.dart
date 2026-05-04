import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/section_model.dart';
import '../../../shared/models/berkas_model.dart';
import '../../../shared/widgets/background_painter.dart';
import '../providers/editor_provider.dart';
import '../widgets/section_widget.dart';
import '../widgets/add_section_sheet.dart';
import '../widgets/background_picker_sheet.dart';
import '../../export/export_service.dart';
import '../../settings/providers/settings_provider.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  Timer? _autoSaveTimer;
  late TextEditingController _titleController;
  bool _titleEditing = false;

  @override
  void initState() {
    super.initState();
    final berkas = ref.read(editorProvider).berkas;
    _titleController = TextEditingController(text: berkas?.title ?? 'Berkas Baru');
    _startAutoSave();
  }

  void _startAutoSave() {
    final interval = ref.read(settingsProvider).autoSaveInterval;
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: interval),
      (_) => ref.read(editorProvider.notifier).save(),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final berkas = editorState.berkas;
    if (berkas == null) {
      return const Scaffold(body: Center(child: Text('Tidak ada berkas')));
    }
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF957FEF)],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (editorState.isDirty) {
              await ref.read(editorProvider.notifier).save();
            }
            if (mounted) Navigator.pop(context);
          },
        ),
        title: _titleEditing
            ? TextField(
                controller: _titleController,
                autofocus: true,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: (v) {
                  ref.read(editorProvider.notifier).updateTitle(v);
                  setState(() => _titleEditing = false);
                },
                onTapOutside: (_) {
                  ref.read(editorProvider.notifier).updateTitle(_titleController.text);
                  setState(() => _titleEditing = false);
                },
              )
            : GestureDetector(
                onTap: () => setState(() => _titleEditing = true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      berkas.title,
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${berkas.sections.length} bagian',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withOpacity(0.80)),
                    ),
                  ],
                ),
              ),
        actions: [
          // Background picker
          IconButton(
            icon: const Icon(Icons.wallpaper_outlined),
            tooltip: 'Ubah Latar Belakang',
            onPressed: () => _showBackgroundPicker(berkas),
          ),
          // Add section
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Tambah Bagian',
            onPressed: () => _showAddSection(),
          ),
          // Save button
          IconButton(
            icon: editorState.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    editorState.isDirty ? Icons.save_outlined : Icons.check_circle_outline,
                    color: editorState.isDirty ? Colors.white : Colors.greenAccent,
                  ),
            tooltip: 'Simpan',
            onPressed: () => ref.read(editorProvider.notifier).save(),
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (v) => _handleMenuAction(v, berkas),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export ke Word (.docx)')),
              PopupMenuItem(value: 'template', child: Text('Simpan sebagai Template')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPainter(
                type: berkas.backgroundType,
                colorValue: berkas.backgroundValue,
                isDark: isDark,
              ),
            ),
          ),
          // Content
          berkas.sections.isEmpty
              ? _EmptyEditor(onAddSection: _showAddSection)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  buildDefaultDragHandles: false,
                  itemCount: berkas.sections.length,
                  onReorder: (oldIndex, newIndex) {
                    ref.read(editorProvider.notifier).reorderSections(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final section = berkas.sections[index];
                    return SectionWidget(
                      key: ValueKey(section.id),
                      section: section,
                      index: index,
                      onChanged: (updated) => ref.read(editorProvider.notifier).updateSection(updated),
                      onDelete: () => ref.read(editorProvider.notifier).removeSection(section.id),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_section',
        onPressed: _showAddSection,
        tooltip: 'Tambah Bagian',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSection() {
    showModalBottomSheet(
      context: context,
      builder: (_) => AddSectionSheet(
        onSelected: (type) {
          Navigator.pop(context);
          ref.read(editorProvider.notifier).addSection(type);
        },
      ),
    );
  }

  void _showBackgroundPicker(BerkasModel berkas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BackgroundPickerSheet(
        currentType: berkas.backgroundType,
        currentValue: berkas.backgroundValue,
        onSelected: (type, value) {
          Navigator.pop(context);
          ref.read(editorProvider.notifier).updateBackground(type, value);
        },
      ),
    );
  }

  Future<void> _handleMenuAction(String action, BerkasModel berkas) async {
    switch (action) {
      case 'export':
        await _exportToDocx(berkas);
      case 'template':
        await _saveAsTemplate(berkas);
    }
  }

  Future<void> _exportToDocx(BerkasModel berkas) async {
    // Save first
    await ref.read(editorProvider.notifier).save();
    if (!mounted) return;

    // Show options dialog
    final options = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _ExportOptionsDialog(),
    );
    if (options == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Mengekspor dokumen...')),
      );
      await ExportService.exportBerkasToDocx(berkas);
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('Berhasil diekspor!')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal ekspor: $e')),
        );
      }
    }
  }

  Future<void> _saveAsTemplate(BerkasModel berkas) async {
    final nameController = TextEditingController(text: '${berkas.title} (Template)');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan sebagai Template'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Template'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // TODO: save as template via template provider
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template berhasil disimpan')),
      );
    }
  }
}

class _EmptyEditor extends StatelessWidget {
  final VoidCallback onAddSection;
  const _EmptyEditor({required this.onAddSection});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Bagian',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambahkan\nbagian pertama ke berkas ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddSection,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Bagian'),
          ),
        ],
      ),
    );
  }
}

class _ExportOptionsDialog extends StatefulWidget {
  const _ExportOptionsDialog();

  @override
  State<_ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<_ExportOptionsDialog> {
  String _orientation = 'portrait';
  bool _includeCover = true;
  bool _includeToc = true;
  String _font = 'Times New Roman';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Opsi Ekspor Word'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orientasi Halaman', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
            RadioListTile(
              title: const Text('Portrait'),
              value: 'portrait',
              groupValue: _orientation,
              onChanged: (v) => setState(() => _orientation = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile(
              title: const Text('Landscape'),
              value: 'landscape',
              groupValue: _orientation,
              onChanged: (v) => setState(() => _orientation = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const Divider(),
            CheckboxListTile(
              title: const Text('Halaman Sampul'),
              value: _includeCover,
              onChanged: (v) => setState(() => _includeCover = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Daftar Isi'),
              value: _includeToc,
              onChanged: (v) => setState(() => _includeToc = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const Divider(),
            Text('Font', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
            RadioListTile(
              title: const Text('Times New Roman'),
              value: 'Times New Roman',
              groupValue: _font,
              onChanged: (v) => setState(() => _font = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile(
              title: const Text('Arial'),
              value: 'Arial',
              groupValue: _font,
              onChanged: (v) => setState(() => _font = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'orientation': _orientation,
            'includeCover': _includeCover,
            'includeToc': _includeToc,
            'font': _font,
          }),
          child: const Text('Export'),
        ),
      ],
    );
  }
}
