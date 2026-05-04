import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../../shared/models/section_model.dart';

class TandaTanganWidget extends StatefulWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;

  const TandaTanganWidget(
      {super.key, required this.section, required this.onChanged});

  @override
  State<TandaTanganWidget> createState() => _TandaTanganWidgetState();
}

class _TandaTanganWidgetState extends State<TandaTanganWidget> {
  late final SignatureController _sigController;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _labelCtrl;
  String? _signatureBase64;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _signatureBase64 =
        widget.section.data['signatureBase64'] as String?;
    _nameCtrl = TextEditingController(
        text: widget.section.data['signerName'] as String? ?? '');
    _labelCtrl = TextEditingController(
        text: widget.section.data['label'] as String? ?? 'Tanda Tangan');
    _sigController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _sigController.dispose();
    _nameCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    final pngBytes = await _sigController.toPngBytes();
    if (pngBytes == null) return;
    setState(() {
      _signatureBase64 = base64Encode(pngBytes);
      _isSigning = false;
    });
    _update();
  }

  void _clearSignature() {
    setState(() => _signatureBase64 = null);
    _sigController.clear();
    _update();
  }

  void _update() {
    widget.onChanged(widget.section.copyWith(data: {
      'label': _labelCtrl.text,
      'signatureBase64': _signatureBase64,
      'signerName': _nameCtrl.text,
    }));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        TextField(
          controller: _labelCtrl,
          onChanged: (_) => _update(),
          style: TextStyle(fontFamily: 'Poppins', 
              fontWeight: FontWeight.w600, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Label tanda tangan...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            filled: false,
          ),
        ),
        const SizedBox(height: 12),

        // Signature area
        if (_isSigning)
          Column(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Signature(
                    controller: _sigController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _sigController.clear();
                      setState(() => _isSigning = false);
                    },
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _sigController.clear(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Hapus'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveSignature,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          )
        else if (_signatureBase64 != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(_signatureBase64!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _isSigning = true),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Ubah'),
                  ),
                  TextButton.icon(
                    onPressed: _clearSignature,
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
            onTap: () => setState(() => _isSigning = true),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colorScheme.outline,
                    style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.draw_outlined,
                        size: 32, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Ketuk untuk menandatangani',
                      style: TextStyle(fontFamily: 'Poppins', 
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
        // Signer name
        TextField(
          controller: _nameCtrl,
          onChanged: (_) => _update(),
          decoration: const InputDecoration(
            labelText: 'Nama penanda tangan (opsional)',
            prefixIcon: Icon(Icons.person_outline, size: 18),
          ),
        ),
      ],
    );
  }
}
