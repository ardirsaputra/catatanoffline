import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/bundel_model.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/bundel_provider.dart';
import '../../berkas/providers/berkas_provider.dart';
import '../../berkas/providers/category_provider.dart';
import 'bundel_detail_screen.dart';

class BundelScreen extends ConsumerWidget {
  const BundelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundles = ref.watch(bundelProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bundel Kuesioner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: bundles.isEmpty
          ? EmptyStateWidget(
              emoji: '📦',
              title: 'Belum Ada Bundel',
              subtitle:
                  'Bundel memungkinkan Anda menggabungkan\nbeberapa berkas menjadi satu dokumen.',
              actionLabel: 'Buat Bundel',
              onAction: () => _showCreateDialog(context, ref),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bundles.length,
              itemBuilder: (context, index) {
                final bundle = bundles[index];
                return _BundelCard(
                  bundle: bundle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BundelDetailScreen(bundle: bundle),
                    ),
                  ),
                  onDelete: () => _confirmDelete(context, ref, bundle),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Buat Bundel'),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tentang Bundel'),
        content: const Text(
          'Bundel Kuesioner memungkinkan Anda menggabungkan beberapa berkas menjadi satu dokumen Word.\n\n'
          'Setiap berkas dalam bundel akan menjadi bab terpisah saat diekspor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateBundelSheet(
        onCreated: (bundle) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BundelDetailScreen(bundle: bundle),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, BundelModel bundle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Bundel?'),
        content: Text('Bundel "${bundle.title}" akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(bundelProvider.notifier).delete(bundle.id);
    }
  }
}

class _BundelCard extends StatelessWidget {
  final BundelModel bundle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BundelCard({
    required this.bundle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child:
                      Text('📦', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bundle.berkasIds.length} berkas · ${DateFormatter.formatShort(bundle.updatedAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (bundle.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        bundle.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon:
                    Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'open', child: Text('Buka')),
                  PopupMenuItem(
                      value: 'delete', child: Text('Hapus')),
                ],
                onSelected: (v) {
                  if (v == 'open') onTap();
                  if (v == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateBundelSheet extends ConsumerStatefulWidget {
  final void Function(BundelModel) onCreated;
  const _CreateBundelSheet({required this.onCreated});

  @override
  ConsumerState<_CreateBundelSheet> createState() =>
      _CreateBundelSheetState();
}

class _CreateBundelSheetState extends ConsumerState<_CreateBundelSheet> {
  final _titleCtrl = TextEditingController(text: 'Bundel Baru');
  final _descCtrl = TextEditingController();
  String _categoryId = '';
  final Set<String> _selectedBerkasIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cats = ref.read(categoryProvider);
      if (cats.isNotEmpty) {
        setState(() => _categoryId = cats.first.id);
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBerkas = ref.watch(berkasProvider);
    final categories = ref.watch(categoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Buat Bundel Baru',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul Bundel',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (categories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _categoryId.isEmpty ? null : _categoryId,
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
                onChanged: (v) => setState(() => _categoryId = v ?? ''),
              ),
            const SizedBox(height: 20),
            Text('Pilih Berkas',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...allBerkas.map((berkas) => CheckboxListTile(
                  title: Text(berkas.title),
                  subtitle:
                      Text('${berkas.sections.length} bagian'),
                  value: _selectedBerkasIds.contains(berkas.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedBerkasIds.add(berkas.id);
                      } else {
                        _selectedBerkasIds.remove(berkas.id);
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _create,
                child: const Text('Buat Bundel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final bundle = await ref.read(bundelProvider.notifier).create(
          title: _titleCtrl.text.trim(),
          categoryId: _categoryId,
          description: _descCtrl.text.trim(),
          berkasIds: _selectedBerkasIds.toList(),
        );
    if (mounted) {
      Navigator.pop(context);
      widget.onCreated(bundle);
    }
  }
}
