import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../../shared/models/section_model.dart';

class GambarWidget extends StatefulWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;

  const GambarWidget(
      {super.key, required this.section, required this.onChanged});

  @override
  State<GambarWidget> createState() => _GambarWidgetState();
}

class _GambarWidgetState extends State<GambarWidget> {
  static const _uuid = Uuid();
  String? _imagePath;
  late final TextEditingController _captionCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.section.data['imagePath'] as String?;
    _captionCtrl = TextEditingController(
        text: widget.section.data['caption'] as String? ?? '');
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged(widget.section.copyWith(data: {
      'imagePath': _imagePath,
      'caption': _captionCtrl.text,
    }));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null) {
        setState(() => _isLoading = false);
        return;
      }
      // Copy to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'images'));
      await imagesDir.create(recursive: true);
      final ext = p.extension(file.path);
      final newPath = p.join(imagesDir.path, '${_uuid.v4()}$ext');
      await File(file.path).copy(newPath);
      setState(() {
        _imagePath = newPath;
        _isLoading = false;
      });
      _update();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _removeImage() {
    setState(() => _imagePath = null);
    _update();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_imagePath != null && File(_imagePath!).existsSync())
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPickDialog(),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Ganti'),
                  ),
                  TextButton.icon(
                    onPressed: _removeImage,
                    icon: Icon(Icons.delete_outline,
                        size: 16, color: colorScheme.error),
                    label: Text('Hapus',
                        style:
                            TextStyle(color: colorScheme.error)),
                  ),
                ],
              ),
            ],
          )
        else
          GestureDetector(
            onTap: _showPickDialog,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colorScheme.outline,
                    style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 40, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Ketuk untuk menambah gambar',
                      style: GoogleFonts.poppins(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Caption
        TextField(
          controller: _captionCtrl,
          onChanged: (_) => _update(),
          decoration: const InputDecoration(
            labelText: 'Keterangan gambar (opsional)',
            prefixIcon: Icon(Icons.text_fields, size: 18),
          ),
        ),
      ],
    );
  }

  void _showPickDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
