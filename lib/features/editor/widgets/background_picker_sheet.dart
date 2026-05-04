import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../../shared/models/berkas_model.dart';

class BackgroundPickerSheet extends StatefulWidget {
  final BerkasBackground currentType;
  final String currentValue;
  final void Function(BerkasBackground, String) onSelected;

  const BackgroundPickerSheet({
    super.key,
    required this.currentType,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  State<BackgroundPickerSheet> createState() => _BackgroundPickerSheetState();
}

class _BackgroundPickerSheetState extends State<BackgroundPickerSheet> {
  late BerkasBackground _type;
  late Color _selectedColor;

  static const _presetColors = [
    Colors.white,
    Color(0xFFFAFAFA),
    Color(0xFFFFF5F5),
    Color(0xFFF0FFF4),
    Color(0xFFEBF8FF),
    Color(0xFFFFFBEB),
    Color(0xFFF5F3FF),
    Color(0xFFFFF0F0),
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFFCE4EC),
    Color(0xFFF3E5F5),
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.currentType;
    try {
      final hex = widget.currentValue.replaceFirst('#', '');
      _selectedColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      _selectedColor = Colors.white;
    }
  }

  String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Latar Belakang Editor',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Type selector
            Text('Pola',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                _TypeButton(
                  label: 'Polos',
                  icon: Icons.square_outlined,
                  selected: _type == BerkasBackground.solid,
                  onTap: () =>
                      setState(() => _type = BerkasBackground.solid),
                ),
                const SizedBox(width: 8),
                _TypeButton(
                  label: 'Titik',
                  icon: Icons.grain,
                  selected: _type == BerkasBackground.dots,
                  onTap: () =>
                      setState(() => _type = BerkasBackground.dots),
                ),
                const SizedBox(width: 8),
                _TypeButton(
                  label: 'Garis',
                  icon: Icons.reorder,
                  selected: _type == BerkasBackground.lines,
                  onTap: () =>
                      setState(() => _type = BerkasBackground.lines),
                ),
                const SizedBox(width: 8),
                _TypeButton(
                  label: 'Cat Air',
                  icon: Icons.water_outlined,
                  selected: _type == BerkasBackground.watercolor,
                  onTap: () =>
                      setState(() => _type = BerkasBackground.watercolor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Preset colors
            Text('Warna Dasar',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _presetColors.map((color) {
                final isSelected = _selectedColor.value == color.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.black12,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(Icons.check,
                            size: 18, color: colorScheme.primary)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom color picker
            ExpansionTile(
              title: Text('Warna Kustom',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              tilePadding: EdgeInsets.zero,
              children: [
                ColorPicker(
                  color: _selectedColor,
                  onColorChanged: (c) => setState(() => _selectedColor = c),
                  width: 36,
                  height: 36,
                  borderRadius: 4,
                  spacing: 5,
                  runSpacing: 5,
                  wheelDiameter: 200,
                  heading: const Text('Pilih Warna'),
                  subheading: const Text('Pilih Kecerahan'),
                  pickersEnabled: const {
                    ColorPickerType.wheel: true,
                    ColorPickerType.primary: false,
                    ColorPickerType.accent: false,
                    ColorPickerType.both: false,
                    ColorPickerType.bw: false,
                    ColorPickerType.custom: false,
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    widget.onSelected(_type, _colorToHex(_selectedColor)),
                child: const Text('Terapkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withOpacity(0.2)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 20,
                  color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
