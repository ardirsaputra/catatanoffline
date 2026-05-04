import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../features/berkas/providers/category_provider.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/settings_model.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFF9A3C),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            actionsIconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Pengaturan',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF9A3C), Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -20,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 76, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Tema, tampilan & kategori',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 4),
              // ── Tampilan ─────────────────────────────────────────────────
              _SectionHeader(title: 'Tampilan', icon: '🎨'),
              _ThemePresetTile(settings: settings, ref: ref),
              _SwitchTile(
                title: 'Mode Gelap',
                subtitle: 'Gunakan tema gelap',
                icon: Icons.dark_mode_outlined,
                value: settings.darkMode,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDarkMode(v),
              ),

              const Divider(height: 16),

              // ── Berkas ───────────────────────────────────────────────────
              _SectionHeader(title: 'Berkas & Editor', icon: '📄'),
              _ChoiceTile(
                title: 'Tampilan Default',
                subtitle: settings.defaultView == 'grid' ? 'Tampilan Grid' : 'Tampilan Daftar',
                icon: Icons.grid_view_outlined,
                choices: const {'grid': 'Grid', 'list': 'Daftar'},
                selected: settings.defaultView,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultView(v),
              ),
              _ChoiceTile(
                title: 'Ukuran Kartu',
                subtitle: _cardSizeLabel(settings.cardSize),
                icon: Icons.crop_square_outlined,
                choices: const {'compact': 'Kecil', 'normal': 'Normal', 'large': 'Besar'},
                selected: settings.cardSize,
                onChanged: (v) => ref.read(settingsProvider.notifier).setCardSize(v),
              ),
              _ChoiceTile(
                title: 'Ukuran Font',
                subtitle: _fontSizeLabel(settings.fontSize),
                icon: Icons.text_fields_outlined,
                choices: const {'small': 'Kecil', 'medium': 'Sedang', 'large': 'Besar'},
                selected: settings.fontSize,
                onChanged: (v) => ref.read(settingsProvider.notifier).setFontSize(v),
              ),
              _SwitchTile(
                title: 'Tampilkan Metadata',
                subtitle: 'Tanggal & kategori pada kartu berkas',
                icon: Icons.info_outline,
                value: settings.showMetadata,
                onChanged: (v) => ref.read(settingsProvider.notifier).setShowMetadata(v),
              ),

              const Divider(height: 16),

              // ── Editor ───────────────────────────────────────────────────
              _SectionHeader(title: 'Editor', icon: '✏️'),
              _ChoiceTile(
                title: 'Latar Belakang Default',
                subtitle: _backgroundLabel(settings.defaultBackground),
                icon: Icons.wallpaper_outlined,
                choices: const {
                  'solid': 'Polos',
                  'dots': 'Polkadot',
                  'lines': 'Garis',
                  'watercolor': 'Watercolor',
                },
                selected: settings.defaultBackground,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultBackground(v),
              ),
              _ChoiceTile(
                title: 'Interval Auto-Simpan',
                subtitle: '${settings.autoSaveInterval} detik',
                icon: Icons.save_outlined,
                choices: const {
                  '5': '5 detik',
                  '10': '10 detik',
                  '30': '30 detik',
                  '60': '60 detik',
                },
                selected: settings.autoSaveInterval.toString(),
                onChanged: (v) => ref.read(settingsProvider.notifier).setAutoSaveInterval(int.parse(v)),
              ),

              const Divider(height: 16),

              // ── Kategori ─────────────────────────────────────────────────
              _SectionHeader(title: 'Kategori', icon: '🗂️'),
              _CategoryManagerTile(ref: ref),

              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }

  String _cardSizeLabel(String size) {
    const m = {'compact': 'Kecil (3 kolom)', 'normal': 'Normal (2 kolom)', 'large': 'Besar (1 kolom)'};
    return m[size] ?? size;
  }

  String _fontSizeLabel(String size) {
    const m = {'small': 'Kecil (12sp)', 'medium': 'Sedang (14sp)', 'large': 'Besar (16sp)'};
    return m[size] ?? size;
  }

  String _backgroundLabel(String bg) {
    const m = {'solid': 'Warna Polos', 'dots': 'Polkadot', 'lines': 'Garis', 'watercolor': 'Watercolor'};
    return m[bg] ?? bg;
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11)),
      secondary: Icon(icon, size: 20),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Map<String, String> choices;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.choices,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11)),
      trailing: Icon(Icons.arrow_forward_ios, size: 12, color: Theme.of(context).colorScheme.outline),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...choices.entries.map((e) => RadioListTile<String>(
                    title: Text(e.value),
                    value: e.key,
                    groupValue: selected,
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ── Theme Preset Tile ─────────────────────────────────────────────────────────

class _ThemePresetTile extends StatelessWidget {
  final SettingsModel settings;
  final WidgetRef ref;

  const _ThemePresetTile({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context) {
    final presets = [
      (key: 'biru', label: 'Biru', color: const Color(0xFFA8D8EA)),
      (key: 'lavender', label: 'Lavender', color: const Color(0xFFC9B8E8)),
      (key: 'mint', label: 'Mint', color: const Color(0xFFB5EAD7)),
      (key: 'peach', label: 'Peach', color: const Color(0xFFFFDFD3)),
      (key: 'rose', label: 'Rose', color: const Color(0xFFFFB7C5)),
    ];

    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text('Tema Warna', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: presets.map((p) {
              final selected = settings.themePreset == p.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => ref.read(settingsProvider.notifier).setTheme(p.key),
                  child: Tooltip(
                    message: p.label,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: p.color.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: selected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Category Manager ──────────────────────────────────────────────────────────

class _CategoryManagerTile extends ConsumerWidget {
  final WidgetRef ref;

  const _CategoryManagerTile({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef watchRef) {
    final categories = watchRef.watch(categoryProvider);
    return Column(
      children: [
        ...categories.map((cat) => ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _colorFromHex(cat.colorHex).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(cat.iconName, style: const TextStyle(fontSize: 16)),
                ),
              ),
              title: Text(cat.name, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showCategoryForm(context, watchRef, cat),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                    onPressed: () => _deleteCategory(context, watchRef, cat),
                  ),
                ],
              ),
            )),
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 20),
          ),
          title: Text('Tambah Kategori', style: TextStyle(fontFamily: 'Poppins', color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
          onTap: () => _showCategoryForm(context, watchRef, null),
        ),
      ],
    );
  }

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFFA8D8EA);
    }
  }

  void _showCategoryForm(
    BuildContext context,
    WidgetRef ref,
    CategoryModel? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryForm(
        existing: existing,
        onSave: (name, icon, color) async {
          if (existing != null) {
            await ref.read(categoryProvider.notifier).update(existing.copyWith(
                  name: name,
                  iconName: icon,
                  colorHex: color,
                ));
          } else {
            await ref.read(categoryProvider.notifier).add(
                  name: name,
                  iconName: icon,
                  colorHex: color,
                );
          }
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryModel cat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('Kategori "${cat.name}" akan dihapus. Berkas terkait tidak akan terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoryProvider.notifier).delete(cat.id);
    }
  }
}

class _CategoryForm extends StatefulWidget {
  final CategoryModel? existing;
  final Future<void> Function(String name, String icon, String color) onSave;

  const _CategoryForm({this.existing, required this.onSave});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _nameController = TextEditingController();
  String _selectedIcon = '📁';
  String _selectedColor = '#A8D8EA';
  bool _saving = false;

  static const _icons = [
    '📁',
    '📂',
    '💼',
    '📋',
    '📊',
    '📝',
    '🗂️',
    '📌',
    '🏥',
    '🏫',
    '🏢',
    '💰',
    '📷',
    '🎓',
    '⚖️',
    '🔬',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _selectedIcon = widget.existing!.iconName;
      _selectedColor = widget.existing!.colorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.existing == null ? 'Tambah Kategori' : 'Edit Kategori',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),

          // Name field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Kategori',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 16),

          // Icon picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Pilih Ikon', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _icons.map((icon) {
                final selected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? colorScheme.primary : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Color picker (simple swatches)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Pilih Warna', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          _ColorSwatches(
            selectedHex: _selectedColor,
            onChanged: (hex) => setState(() => _selectedColor = hex),
          ),
          const SizedBox(height: 20),

          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong')));
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(name, _selectedIcon, _selectedColor);
    if (mounted) setState(() => _saving = false);
  }
}

class _ColorSwatches extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onChanged;

  static const _colors = [
    '#A8D8EA',
    '#C9B8E8',
    '#B5EAD7',
    '#FFDFD3',
    '#FFB7C5',
    '#FFF9C4',
    '#D7E8BA',
    '#B8D4E8',
    '#F5C6CB',
    '#D4E6F1',
    '#E8D5B7',
    '#C8E6C9',
    '#F8BBD9',
    '#B2DFDB',
    '#E1BEE7',
  ];

  const _ColorSwatches({required this.selectedHex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _colors.map((hex) {
          Color c;
          try {
            c = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
          } catch (_) {
            c = Colors.blue;
          }
          final selected = selectedHex == hex;
          return GestureDetector(
            onTap: () => onChanged(hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: selected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : [],
              ),
              child: selected ? Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
