import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/berkas_model.dart';
import '../../../shared/models/template_model.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/berkas_provider.dart';
import '../providers/category_provider.dart';
import '../../editor/providers/editor_provider.dart';
import '../../editor/screens/editor_screen.dart';
import '../../export/clipboard_import_service.dart';
import '../../export/docx_import_service.dart';
import '../../template/providers/template_provider.dart';
import '../../settings/providers/settings_provider.dart';

class BerkasListScreen extends ConsumerStatefulWidget {
  final bool openCreateDialog;
  final String? initialTemplateId;
  final DateTime? filterDate;

  const BerkasListScreen({
    super.key,
    this.openCreateDialog = false,
    this.initialTemplateId,
    this.filterDate,
  });

  @override
  ConsumerState<BerkasListScreen> createState() => _BerkasListScreenState();
}

class _BerkasListScreenState extends ConsumerState<BerkasListScreen> {
  final _searchController = TextEditingController();
  bool _heatmapExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.filterDate != null) {
        ref.read(berkasFilterDateProvider.notifier).state = widget.filterDate;
        setState(() => _heatmapExpanded = true);
      }
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
    final allBerkasCount = ref.watch(berkasProvider).length;
    final allBerkas = ref.watch(berkasProvider);
    final categories = ref.watch(categoryProvider);
    final selectedCat = ref.watch(berkasSelectedCategoryProvider);
    final filterDate = ref.watch(berkasFilterDateProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isGrid = settings.defaultView == 'grid';

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && widget.filterDate != null) {
          ref.read(berkasFilterDateProvider.notifier).state = null;
        }
      },
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (ctx, innerScrolled) => [
            SliverAppBar(
              expandedHeight: 130,
              floating: false,
              pinned: true,
              forceElevated: innerScrolled,
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black87,
              iconTheme: const IconThemeData(color: Colors.black87),
              actionsIconTheme: const IconThemeData(color: Colors.black87),
              title: const Text(
                'Berkas',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              actions: [
                // Activity heatmap filter toggle
                IconButton(
                  icon: Icon(
                    _heatmapExpanded ? Icons.grid_on : Icons.grid_off_outlined,
                    color: _heatmapExpanded ? const Color(0xFF1B5E20) : Colors.black87,
                  ),
                  tooltip: 'Filter Aktivitas',
                  onPressed: () => setState(() => _heatmapExpanded = !_heatmapExpanded),
                ),
                IconButton(
                  icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
                  tooltip: isGrid ? 'Tampilan Daftar' : 'Tampilan Grid',
                  onPressed: () => ref.read(settingsProvider.notifier).setDefaultView(isGrid ? 'list' : 'grid'),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'import_word') _importFromWord();
                    if (v == 'paste_clipboard') _importFromClipboard();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'import_word',
                      child: Row(
                        children: [
                          Icon(Icons.upload_file_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Import dari Word'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'paste_clipboard',
                      child: Row(
                        children: [
                          Icon(Icons.content_paste_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Tempel dari Clipboard'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF8F00), Color(0xFFFFB300), Color(0xFFFFD54F)],
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
                            color: Colors.black.withOpacity(0.06),
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
                            color: Colors.black.withOpacity(0.04),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 76, 20, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$allBerkasCount berkas tersimpan',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchFilterDelegate(
                searchController: _searchController,
                categories: categories,
                selectedCat: selectedCat,
                filterDate: filterDate,
                ref: ref,
                colorScheme: colorScheme,
              ),
            ),
            // Activity heatmap filter panel (hidden by default)
            if (_heatmapExpanded)
              SliverToBoxAdapter(
                child: _BerkasHeatmapFilter(
                  allBerkas: allBerkas,
                  selectedDate: filterDate,
                  colorScheme: colorScheme,
                  onDateSelected: (date) {
                    ref.read(berkasFilterDateProvider.notifier).state =
                        filterDate != null && filterDate.year == date.year && filterDate.month == date.month && filterDate.day == date.day ? null : date;
                  },
                ),
              ),
          ],
          body: berkas.isEmpty
              ? EmptyStateWidget(
                  emoji: '📂',
                  title: 'Belum Ada Berkas',
                  subtitle: 'Tekan tombol + untuk membuat berkas baru.\nAnda bisa memilih template atau mulai dari awal.',
                  actionLabel: 'Buat Berkas Pertama',
                  onAction: () => _showCreateDialog(),
                )
              : isGrid
                  ? _buildGrid(berkas, categories, settings)
                  : _buildList(berkas, categories, settings),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_berkas',
          onPressed: () => _showCreateDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Buat Baru'),
        ),
      ),
    );
  }

  Widget _buildGrid(List<BerkasModel> berkas, dynamic categories, dynamic settings) {
    final cardSize = (settings as dynamic).cardSize as String;
    final crossAxisCount = cardSize == 'compact'
        ? 3
        : cardSize == 'large'
            ? 1
            : 2;
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
        final _catWhere = categories?.where((c) => c.id == item.categoryId);
        final cat = (_catWhere == null || _catWhere.isEmpty) ? null : _catWhere.first;
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
        final _catWhere3 = categories?.where((c) => c.id == item.categoryId);
        final cat = (_catWhere3 == null || _catWhere3.isEmpty) ? null : _catWhere3.first;
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
      useSafeArea: true,
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

  Future<void> _importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard kosong atau tidak mengandung teks')),
        );
      }
      return;
    }

    final imported = ClipboardImportService.importFromText(text);

    if (!mounted) return;
    final titleController = TextEditingController(text: imported.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Tempel dari Clipboard',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${imported.sections.length} bagian berhasil dikenali dari teks.',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul Berkas',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    final newTitle = titleController.text.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) => titleController.dispose());
    if (confirmed != true || !mounted) return;

    final finalBerkas = imported.copyWith(title: newTitle.isEmpty ? imported.title : newTitle);
    await ref.read(berkasProvider.notifier).importBerkas(finalBerkas);

    if (!mounted) return;
    _openEditor(finalBerkas);
  }

  Future<void> _importFromWord() async {
    // Pick .docx file, fallback to any if extension filter not supported.
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'doc'],
        withData: false,
      );
    } catch (_) {
      try {
        result = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka file picker')),
          );
        }
        return;
      }
    }

    final picked = result?.files.firstOrNull;
    if (picked == null || picked.path == null) return;

    final ext = picked.name.toLowerCase();
    if (!ext.endsWith('.docx') && !ext.endsWith('.doc')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File harus berekstensi .docx atau .doc')),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memproses file Word...')),
    );

    final imported = await DocxImportService.importFromPath(picked.path!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (imported == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membaca file. Pastikan file adalah .docx yang valid.')),
      );
      return;
    }

    // Confirm / rename title before saving.
    final titleController = TextEditingController(text: imported.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import dari Word', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${imported.sections.length} bagian berhasil dikenali dari dokumen.',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul Berkas',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    final newTitle = titleController.text.trim();
    titleController.dispose();
    if (confirmed != true || !mounted) return;

    final finalBerkas = imported.copyWith(title: newTitle.isEmpty ? imported.title : newTitle);
    await ref.read(berkasProvider.notifier).importBerkas(finalBerkas);

    if (!mounted) return;
    _openEditor(finalBerkas);
  }

  Future<void> _confirmDelete(BerkasModel berkas) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Berkas?'),
        content: Text('Berkas "${berkas.title}" akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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

// ── Search + Filter Pinned Header ─────────────────────────────────────────────

class _SearchFilterDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final List categories;
  final String? selectedCat;
  final DateTime? filterDate;
  final WidgetRef ref;
  final ColorScheme colorScheme;

  const _SearchFilterDelegate({
    required this.searchController,
    required this.categories,
    required this.selectedCat,
    required this.ref,
    required this.colorScheme,
    this.filterDate,
  });

  @override
  double get maxExtent => filterDate != null ? 126 : 100;
  @override
  double get minExtent => filterDate != null ? 126 : 100;
  @override
  bool shouldRebuild(_SearchFilterDelegate old) => old.selectedCat != selectedCat || old.filterDate != filterDate || old.categories.length != categories.length;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return SizedBox(
        height: filterDate != null ? 126 : 100,
        child: Material(
          color: colorScheme.surface,
          elevation: overlapsContent ? 2 : 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: searchController,
                  onChanged: (v) => ref.read(berkasSearchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Cari berkas...',
                    hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchController.clear();
                              ref.read(berkasSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              // Date filter chip (shown when a date is active)
              if (filterDate != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 13, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 4),
                      Text(
                        'Filter: ${filterDate!.day} ${months[filterDate!.month - 1]} ${filterDate!.year}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => ref.read(berkasFilterDateProvider.notifier).state = null,
                        child: const Icon(Icons.close, size: 14, color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: const Text('Semua', style: TextStyle(fontFamily: 'Poppins', fontSize: 11)),
                        selected: selectedCat == null,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onSelected: (_) => ref.read(berkasSelectedCategoryProvider.notifier).state = null,
                      ),
                    ),
                    ...categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text('${cat.iconName} ${cat.name}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11)),
                            selected: selectedCat == cat.id,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onSelected: (_) => ref.read(berkasSelectedCategoryProvider.notifier).state = selectedCat == cat.id ? null : cat.id,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

// ── Berkas Heatmap Filter ────────────────────────────────────────────────────

class _BerkasHeatmapFilter extends StatelessWidget {
  final List<BerkasModel> allBerkas;
  final DateTime? selectedDate;
  final ColorScheme colorScheme;
  final void Function(DateTime) onDateSelected;

  const _BerkasHeatmapFilter({
    required this.allBerkas,
    required this.selectedDate,
    required this.colorScheme,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    const weeks = 16;
    const totalDays = weeks * 7;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // Align to the most recent Sunday, then go back (weeks-1) more weeks
    final daysSinceSunday = today.weekday % 7; // Sun=0, Mon=1..Sat=6
    final lastSunday = todayNorm.subtract(Duration(days: daysSinceSunday));
    final startDate = lastSunday.subtract(const Duration(days: (weeks - 1) * 7));

    // Build activity map
    final activityMap = <String, int>{};
    for (final b in allBerkas) {
      final d = b.updatedAt;
      final key = '${d.year}-${d.month}-${d.day}';
      activityMap[key] = (activityMap[key] ?? 0) + 1;
    }

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    // Build week columns
    final weekColumns = <List<DateTime?>>[];
    for (var w = 0; w < weeks; w++) {
      final col = <DateTime?>[];
      for (var d = 0; d < 7; d++) {
        final date = startDate.add(Duration(days: w * 7 + d));
        col.add(date.isAfter(todayNorm) ? null : date);
      }
      weekColumns.add(col);
    }

    // Month labels: find first day of each month that appears
    final monthLabels = <int, String>{}; // column index → month name
    for (var w = 0; w < weekColumns.length; w++) {
      for (final date in weekColumns[w]) {
        if (date != null && date.day <= 7) {
          monthLabels[w] = months[date.month - 1];
          break;
        }
      }
    }

    Color cellColor(int count) {
      if (count == 0) return colorScheme.surfaceContainerHighest.withOpacity(0.5);
      if (count == 1) return const Color(0xFFC6E48B);
      if (count <= 3) return const Color(0xFF7BC96F);
      if (count <= 6) return const Color(0xFF239A3B);
      return const Color(0xFF196127);
    }

    const cellSize = 14.0;
    const cellGap = 2.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded, size: 14, color: colorScheme.primary),
              const SizedBox(width: 5),
              Text(
                'Filter Aktivitas — ketuk tanggal untuk filter',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month labels row
                SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      for (var w = 0; w < weeks; w++) ...[
                        SizedBox(
                          width: cellSize + cellGap,
                          child: monthLabels.containsKey(w) ? Text(monthLabels[w]!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 8, color: Color(0xFF9E9E9E))) : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Day rows with cells
                for (var d = 0; d < 7; d++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: cellGap),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: d % 2 == 0 ? Text(dayLabels[d], style: const TextStyle(fontFamily: 'Poppins', fontSize: 8, color: Color(0xFF9E9E9E))) : null,
                        ),
                        for (var w = 0; w < weeks; w++) ...[
                          Builder(builder: (context) {
                            final date = weekColumns[w][d];
                            if (date == null) {
                              return SizedBox(width: cellSize + cellGap, height: cellSize);
                            }
                            final key = '${date.year}-${date.month}-${date.day}';
                            final count = activityMap[key] ?? 0;
                            final isSelected = selectedDate != null && selectedDate!.year == date.year && selectedDate!.month == date.month && selectedDate!.day == date.day;
                            final isToday = date.year == todayNorm.year && date.month == todayNorm.month && date.day == todayNorm.day;
                            return GestureDetector(
                              onTap: () => onDateSelected(date),
                              child: Container(
                                width: cellSize,
                                height: cellSize,
                                margin: const EdgeInsets.only(right: cellGap),
                                decoration: BoxDecoration(
                                  color: isSelected ? colorScheme.primary : cellColor(count),
                                  borderRadius: BorderRadius.circular(2),
                                  border: isToday ? Border.all(color: colorScheme.primary, width: 1.5) : null,
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                // Legend
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 24),
                    const Text('Tidak ada', style: TextStyle(fontFamily: 'Poppins', fontSize: 8, color: Color(0xFF9E9E9E))),
                    const SizedBox(width: 4),
                    for (final c in [const Color(0xFFC6E48B), const Color(0xFF7BC96F), const Color(0xFF239A3B), const Color(0xFF196127)])
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
                      ),
                    const Text('Banyak', style: TextStyle(fontFamily: 'Poppins', fontSize: 8, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      tagColor = Color(int.parse('FF${berkas.colorTag.replaceFirst('#', '')}', radix: 16));
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
                        child: Text(berkas.iconName, style: const TextStyle(fontSize: 20)),
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
                    style: TextStyle(
                      fontFamily: 'Poppins',
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatShort(berkas.updatedAt),
                      style: TextStyle(
                        fontFamily: 'Poppins',
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
                icon: Icon(Icons.more_vert, size: 18, color: colorScheme.onSurfaceVariant),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
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
      tagColor = Color(int.parse('FF${berkas.colorTag.replaceFirst('#', '')}', radix: 16));
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
                  child: Text(berkas.iconName, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      berkas.title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              categoryName,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${berkas.sections.length} bagian',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatRelative(berkas.updatedAt),
                            style: TextStyle(
                              fontFamily: 'Poppins',
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
                icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Buka')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
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
  final _titleController = TextEditingController(text: '');
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
        final _tmplWhere = templates.where((t) => t.id == widget.preselectedTemplateId);
        final tmpl = _tmplWhere.isEmpty ? null : _tmplWhere.first;
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
      child: SafeArea(
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
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700),
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
                  onChanged: (v) => setState(() => _selectedCategoryId = v ?? ''),
                ),
              const SizedBox(height: 16),

              // Icon picker
              Text('Ikon', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: AppConstants.cardIcons
                      .map((icon) => GestureDetector(
                            onTap: () => setState(() => _selectedIcon = icon),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _selectedIcon == icon ? colorScheme.primary.withOpacity(0.3) : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                                border: _selectedIcon == icon ? Border.all(color: colorScheme.primary, width: 2) : null,
                              ),
                              child: Center(
                                child: Text(icon, style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Color tag
              Text('Warna Tag', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: AppConstants.colorTags.map((color) {
                    final c = Color(int.parse('FF${color.replaceFirst('#', '')}', radix: 16));
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: _selectedColor == color ? Border.all(color: Colors.black38, width: 2.5) : Border.all(color: Colors.black12, width: 1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Template picker
              Text('Template', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
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
                                color: _selectedTemplate?.id == tmpl.id ? colorScheme.primary.withOpacity(0.2) : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: _selectedTemplate?.id == tmpl.id ? Border.all(color: colorScheme.primary, width: 2) : null,
                              ),
                              child: Column(
                                children: [
                                  Text(tmpl.iconEmoji, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(height: 4),
                                  Text(
                                    tmpl.name,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w500),
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
