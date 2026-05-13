import 'package:flutter/material.dart';

/// A polished modal bottom sheet for Word export options.
/// Returns a [Map<String,dynamic>] with keys:
///   orientation: 'portrait' | 'landscape'
///   includeCover: bool
///   includeToc: bool
///   font: String
///
/// Usage:
///   final opts = await ExportOptionsSheet.show(context, title: '...');
///   if (opts != null) { /* proceed */ }
class ExportOptionsSheet extends StatefulWidget {
  final String documentTitle;

  const ExportOptionsSheet({super.key, required this.documentTitle});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String documentTitle,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportOptionsSheet(documentTitle: documentTitle),
    );
  }

  @override
  State<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<ExportOptionsSheet> {
  String _orientation = 'portrait';
  bool _includeCover = true;
  bool _includeToc = true;
  String _font = 'Times New Roman';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B579A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF2B579A), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ekspor ke Word',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        widget.documentTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Orientasi ─────────────────────────────────────────────
                const _SectionLabel(label: 'Orientasi Halaman'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _OrientationCard(
                        icon: Icons.stay_current_portrait_outlined,
                        label: 'Portrait',
                        selected: _orientation == 'portrait',
                        onTap: () => setState(() => _orientation = 'portrait'),
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OrientationCard(
                        icon: Icons.stay_current_landscape_outlined,
                        label: 'Landscape',
                        selected: _orientation == 'landscape',
                        onTap: () => setState(() => _orientation = 'landscape'),
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Konten ────────────────────────────────────────────────
                const _SectionLabel(label: 'Konten Dokumen'),
                const SizedBox(height: 8),
                _ToggleRow(
                  icon: Icons.auto_stories_outlined,
                  label: 'Halaman Sampul',
                  subtitle: 'Tambahkan halaman judul di awal',
                  value: _includeCover,
                  onChanged: (v) => setState(() => _includeCover = v),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 8),
                _ToggleRow(
                  icon: Icons.list_alt_outlined,
                  label: 'Daftar Isi',
                  subtitle: 'Tambahkan halaman daftar isi',
                  value: _includeToc,
                  onChanged: (v) => setState(() => _includeToc = v),
                  colorScheme: colorScheme,
                ),

                const SizedBox(height: 20),

                // ── Font ──────────────────────────────────────────────────
                const _SectionLabel(label: 'Font Dokumen'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _FontCard(
                        fontName: 'Times New Roman',
                        sample: 'Aa',
                        sampleStyle: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700),
                        selected: _font == 'Times New Roman',
                        onTap: () => setState(() => _font = 'Times New Roman'),
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FontCard(
                        fontName: 'Arial',
                        sample: 'Aa',
                        sampleStyle: TextStyle(fontFamily: 'sans-serif', fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        selected: _font == 'Arial',
                        onTap: () => setState(() => _font = 'Arial'),
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FontCard(
                        fontName: 'Calibri',
                        sample: 'Aa',
                        sampleStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        selected: _font == 'Calibri',
                        onTap: () => setState(() => _font = 'Calibri'),
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Export button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2B579A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text(
                      'Ekspor Sekarang',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onPressed: () => Navigator.pop(context, {
                      'orientation': _orientation,
                      'includeCover': _includeCover,
                      'includeToc': _includeToc,
                      'font': _font,
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _OrientationCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _OrientationCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2B579A).withValues(alpha: 0.12) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2B579A) : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: selected ? const Color(0xFF2B579A) : colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? const Color(0xFF2B579A) : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme colorScheme;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF2B579A).withValues(alpha: 0.08) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? const Color(0xFF2B579A).withValues(alpha: 0.4) : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: value ? const Color(0xFF2B579A) : colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF2B579A),
              activeTrackColor: const Color(0xFF2B579A).withValues(alpha: 0.4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _FontCard extends StatelessWidget {
  final String fontName;
  final String sample;
  final TextStyle sampleStyle;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;

  const _FontCard({
    required this.fontName,
    required this.sample,
    required this.sampleStyle,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2B579A).withValues(alpha: 0.12) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2B579A) : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(sample, style: sampleStyle.copyWith(color: selected ? const Color(0xFF2B579A) : colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(
              fontName,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? const Color(0xFF2B579A) : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
