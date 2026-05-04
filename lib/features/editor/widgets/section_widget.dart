import 'package:flutter/material.dart';
import '../../../shared/models/section_model.dart';
import 'sections/wawancara_widget.dart';
import 'sections/checklist_widget.dart';
import 'sections/pilihan_ganda_widget.dart';
import 'sections/esai_widget.dart';
import 'sections/tanda_tangan_widget.dart';
import 'sections/gambar_widget.dart';
import 'sections/tabel_widget.dart';
import 'sections/teks_bebas_widget.dart';

class SectionWidget extends StatelessWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;
  final VoidCallback onDelete;
  final int index;

  const SectionWidget({
    super.key,
    required this.section,
    required this.onChanged,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(section.type.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  section.type.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle, size: 20, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: colorScheme.onSurfaceVariant),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Hapus Bagian')),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (section.type) {
      case SectionType.wawancara:
        return WawancaraWidget(section: section, onChanged: onChanged);
      case SectionType.checklist:
        return ChecklistWidget(section: section, onChanged: onChanged);
      case SectionType.pilihanGanda:
        return PilihanGandaWidget(section: section, onChanged: onChanged);
      case SectionType.esai:
        return EsaiWidget(section: section, onChanged: onChanged);
      case SectionType.tandaTangan:
        return TandaTanganWidget(section: section, onChanged: onChanged);
      case SectionType.gambar:
        return GambarWidget(section: section, onChanged: onChanged);
      case SectionType.tabel:
        return TabelWidget(section: section, onChanged: onChanged);
      case SectionType.teksBebas:
        return TeksBebasWidget(section: section, onChanged: onChanged);
    }
  }
}
