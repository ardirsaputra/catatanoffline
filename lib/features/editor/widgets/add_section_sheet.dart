import 'package:flutter/material.dart';
import '../../../shared/models/section_model.dart';

class AddSectionSheet extends StatelessWidget {
  final void Function(SectionType) onSelected;

  const AddSectionSheet({super.key, required this.onSelected});

  static const _items = [
    (SectionType.wawancara, '💬', 'Wawancara', 'Pertanyaan & jawaban wawancara'),
    (SectionType.checklist, '✅', 'Checklist', 'Daftar item dengan checkbox'),
    (SectionType.pilihanGanda, '🔘', 'Pilihan Ganda', 'Pertanyaan dengan opsi pilihan'),
    (SectionType.esai, '📝', 'Kuesioner Esai', 'Pertanyaan dengan jawaban panjang'),
    (SectionType.tabel, '📊', 'Tabel', 'Tabel dengan baris dan kolom'),
    (SectionType.teksBebas, '📄', 'Teks Bebas', 'Editor teks kaya dengan pemformatan'),
    (SectionType.gambar, '🖼️', 'Gambar', 'Sisipkan gambar dari galeri atau kamera'),
    (SectionType.tandaTangan, '✍️', 'Tanda Tangan', 'Area tanda tangan digital'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Tambah Bagian',
                  style: TextStyle(fontFamily: 'Poppins', 
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              padding: const EdgeInsets.all(12),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: _items
                  .map((item) => _SectionTypeCard(
                        emoji: item.$2,
                        label: item.$3,
                        subtitle: item.$4,
                        onTap: () => onSelected(item.$1),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTypeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SectionTypeCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontFamily: 'Poppins', 
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontFamily: 'Poppins', 
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
