import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/berkas_model.dart';
import '../../shared/models/template_model.dart';
import '../../shared/utils/constants.dart';
import '../../shared/utils/date_formatter.dart';
import '../../shared/widgets/empty_state.dart';
import '../providers/berkas_provider.dart';
import '../providers/category_provider.dart';
import '../../editor/providers/editor_provider.dart';
import '../../editor/screens/editor_screen.dart';
import '../../template/providers/template_provider.dart';
import '../../settings/providers/settings_provider.dart';

class BerkasListScreen extends ConsumerStatefulWidget {
  final bool openCreateDialog;
  final String? initialTemplateId;

  const BerkasListScreen({
    super.key,
    this.openCreateDialog = false,
    this.initialTemplateId,
  });

  @override
  ConsumerState<BerkasListScreen> createState() => _BerkasListScreenState();
}

class _BerkasListScreenState extends ConsumerState<BerkasListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.openCreateDialog || widget.initialTemplateId != null) {
        _showCreateDialog(preselectedTemplateId: widget.initialTemplateId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final berkas = ref.watch(filteredBerkasProvider);
    final categories = ref.watch(categoryProvider);
    final selectedCat = ref.watch(berkasSelectedCategoryProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isGrid = settings.defaultView == 'grid';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berkas'),
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: isGrid ? 'Tampilan Daftar' : 'Tampilan Grid',
            onPressed: () => ref
                .read(settingsProvider.notifier)
                .setDefaultView(isGrid ? 'list' : 'grid'),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Urutkan',
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      ref.read(berkasSearchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Cari berkas...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(berkasSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Category filter chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Semua'),
                        selected: selectedCat == null,
                        onSelected: (_) => ref
                            .read(berkasSelectedCategoryProvider.notifier)
                            .state = null,
                      ),
                    ),
                    ...categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('${cat.iconName} ${cat.name}'),
                            selected: selectedCat == cat.id,
                            onSelected: (_) => ref
                                .read(berkasSelectedCategoryProvider.notifier)
                                .state =
                                selectedCat == cat.id ? null : cat.id,
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: berkas.isEmpty
          ? EmptyStateWidget(
              emoji: '📂',
              title: 'Belum Ada Berkas',
              subtitle:
                  'Tekan tombol + untuk membuat berkas baru.\nAnda bisa memilih template atau mulai dari awal.',
              actionLabel: 'Buat Berkas Pertama',
              onAction: () => _showCreateDialog(),
            )
          : isGrid
              ? _buildGrid(berkas, categories, settings)
              : _buildList(berkas, categories, settings),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Buat Baru'),
      ),
    );
  }

  Widget _buildGrid(List<BerkasModel> berkas, dynamic categories, dynamic settings) {
    final cardSize = (settings as dynamic).cardSize as String;
    final crossAxisCount = cardSize == 'compact' ? 3 : cardSize == 'large' ? 1 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: berkas.length,
      itemBuilder: (context, index) {
        final item = berkas[index];
        final cat = categories.firstWhere(
          (c) => c.id == item.categoryId,
          orElse: () => null,
        );
        return _BerkasGridCard(
          berkas: item,
          categoryName: cat?.name ?? 'Umum',
          showMeta: ref.read(settingsProvider).showMetadata,
          onTap: () => _openEditor(item),
          onDelete: () => _confirmDelete(item),
        );
      },
    );
  }

  Widget _buildList(List<BerkasModel> berkas, dynamic categories, dynamic settings) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: berkas.length,
      itemBuilder: (context, index) {
        final item = berkas[index];
        final cat = categories.firstWhere(
          (c) => c.id == item.categoryId,
          orElse: () => null,
        );
        return _BerkasListItem(
          berkas: item,
          categoryName: cat?.name ?? 'Umum',
          showMeta: ref.read(settingsProvider).showMetadata,
          onTap: () => _openEditor(item),
          onDelete: () => _confirmDelete(item),
        );
      },
    );
  }

  void _openEditor(BerkasModel berkas) {
    ref.read(editorProvider.notifier).loadBerkas(berkas);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  void _showCreateDialog({String? preselectedTemplateId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateBerkasSheet(
        preselectedTemplateId: preselectedTemplateId,
        onCreated: (berkas) {
          ref.read(editorProvider.notifier).loadBerkas(berkas);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditorScreen()),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BerkasModel berkas) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Berkas?'),
        content: Text(
            'Berkas "${berkas.title}" akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(berkasProvider.notifier).delete(berkas.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berkas berhasil dihapus')),
        );
      }
    }
  }
}

// ── Grid Card ────────────────────────────────────────────────────────────────

class _BerkasGridCard extends StatelessWidget {
  final BerkasModel berkas;
  final String categoryName;
  final bool showMeta;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BerkasGridCard({
    required this.berkas,
    required this.categoryName,
    required this.showMeta,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color tagColor;
    try {
      tagColor = Color(
          int.parse('FF${berkas.colorTag.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      tagColor = colorScheme.primary;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(berkas.iconName,
                            style: const TextStyle(fontSize: 20)),
                      ),
                      const Spacer(),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    berkas.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showMeta) ...[
                    const Spacer(),
                    Text(
                      categoryName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatShort(berkas.updatedAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 18, color: colorScheme.onSurfaceVariant),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Hapus')),
                ],
                onSelected: (val) {
                  if (val == 'edit') onTap();
                  if (val == 'delete') onDelete();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List Item ────────────────────────────────────────────────────────────────

class _BerkasListItem extends StatelessWidget {
  final BerkasModel berkas;
  final String categoryName;
  final bool showMeta;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BerkasListItem({
    required this.berkas,
    required this.categoryName,
    required this.showMeta,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color tagColor;
    try {
      tagColor = Color(
          int.parse('FF${berkas.colorTag.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      tagColor = colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(berkas.iconName,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      berkas.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showMeta) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              categoryName,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${berkas.sections.length} bagian',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatRelative(berkas.updatedAt),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: colorScheme.onSurfaceVariant),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit', child: Text('Buka')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Hapus')),
                ],
                onSelected: (val) {
                  if (val == 'edit') onTap();
                  if (val == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create Berkas Bottom Sheet ───────────────────────────────────────────────

class _CreateBerkasSheet extends ConsumerStatefulWidget {
  final String? preselectedTemplateId;
  final void Function(BerkasModel) onCreated;

  const _CreateBerkasSheet({
    this.preselectedTemplateId,
    required this.onCreated,
  });

  @override
  ConsumerState<_CreateBerkasSheet> createState() => _CreateBerkasSheetState();
}

class _CreateBerkasSheetState extends ConsumerState<_CreateBerkasSheet> {
  final _titleController = TextEditingController(text: 'Berkas Baru');
  String _selectedCategoryId = '';
  String _selectedIcon = '📄';
  String _selectedColor = '#A8D8EA';
  TemplateModel? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoryProvider);
      if (categories.isNotEmpty) {
        setState(() => _selectedCategoryId = categories.first.id);
      }
      if (widget.preselectedTemplateId != null) {
        final templates = ref.read(templateProvider);
        final tmpl = templates.where(
          (t) => t.id == widget.preselectedTemplateId,
        ).firstOrNull;
        if (tmpl != null) {
          setState(() {
            _selectedTemplate = tmpl;
            _titleController.text = tmpl.name;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final templates = ref.watch(templateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Buat Berkas Baru',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Berkas',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            if (categories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.iconName} ${c.name}'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCategoryId = v ?? ''),
              ),
            const SizedBox(height: 16),

            // Icon picker
            Text('Ikon',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: AppConstants.cardIcons
                    .map((icon) => GestureDetector(
                          onTap: () =>
                              setState(() => _selectedIcon = icon),
                          child: Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: _selectedIcon == icon
                                  ? colorScheme.primary.withOpacity(0.3)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: _selectedIcon == icon
                                  ? Border.all(
                                      color: colorScheme.primary, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: Text(icon,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Color tag
            Text('Warna Tag',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: AppConstants.colorTags
                    .map((color) {
                      final c = Color(int.parse(
                          'FF${color.replaceFirst('#', '')}',
                          radix: 16));
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: _selectedColor == color
                                ? Border.all(
                                    color: Colors.black38, width: 2.5)
                                : Border.all(
                                    color: Colors.black12, width: 1),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Template picker
            Text('Template',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: templates
                    .map((tmpl) => GestureDetector(
                          onTap: () => setState(() {
                            _selectedTemplate = tmpl;
                            _titleController.text = tmpl.name;
                          }),
                          child: Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _selectedTemplate?.id == tmpl.id
                                  ? colorScheme.primary.withOpacity(0.2)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: _selectedTemplate?.id == tmpl.id
                                  ? Border.all(
                                      color: colorScheme.primary, width: 2)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(tmpl.iconEmoji,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(
                                  tmpl.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _create,
                child: const Text('Buat Berkas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) return;
    if (_selectedCategoryId.isEmpty) {
      final cats = ref.read(categoryProvider);
      if (cats.isNotEmpty) _selectedCategoryId = cats.first.id;
    }

    final sections = _selectedTemplate?.buildSections() ?? [];
    final berkas = await ref.read(berkasProvider.notifier).create(
          title: _titleController.text.trim(),
          categoryId: _selectedCategoryId,
          iconName: _selectedIcon,
          colorTag: _selectedColor,
        );

    // Add template sections
    if (sections.isNotEmpty) {
      final updated = berkas.copyWith(
        sections: sections,
        updatedAt: DateTime.now(),
      );
      await ref.read(berkasProvider.notifier).update(updated);
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(updated);
      }
    } else {
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(berkas);
      }
    }
  }
}
