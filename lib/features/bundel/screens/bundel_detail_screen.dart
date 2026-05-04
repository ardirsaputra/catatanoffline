import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/bundel_model.dart';
import '../../../shared/models/berkas_model.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../berkas/providers/berkas_provider.dart';
import '../../bundel/providers/bundel_provider.dart';
import '../../export/export_service.dart';

class BundelDetailScreen extends ConsumerWidget {
  final BundelModel bundle;

  const BundelDetailScreen({super.key, required this.bundle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBundle = ref
        .watch(bundelProvider)
        .firstWhere((b) => b.id == bundle.id, orElse: () => bundle);
    final allBerkas = ref.watch(berkasProvider);
    final berkasInBundle = allBerkas
        .where((b) => currentBundle.berkasIds.contains(b.id))
        .toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentBundle.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Berkas',
            onPressed: () =>
                _showAddBerkasDialog(context, ref, currentBundle, allBerkas),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'export') {
                await _exportBundle(context, currentBundle, berkasInBundle);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Export ke Word'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Bundle info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('📦', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentBundle.title,
                        style: TextStyle(fontFamily: 'Poppins', 
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (currentBundle.description.isNotEmpty)
                        Text(
                          currentBundle.description,
                          style: TextStyle(fontFamily: 'Poppins', 
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        '${berkasInBundle.length} berkas · ${DateFormatter.formatRelative(currentBundle.updatedAt)}',
                        style: TextStyle(fontFamily: 'Poppins', 
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Berkas list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Berkas dalam Bundel',
                  style: TextStyle(fontFamily: 'Poppins', 
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Berkas list
          Expanded(
            child: berkasInBundle.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📄',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'Bundel ini kosong\nTambahkan berkas ke dalam bundel',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', 
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: berkasInBundle.length,
                    onReorder: (oldIndex, newIndex) async {
                      final ids =
                          List<String>.from(currentBundle.berkasIds);
                      if (newIndex > oldIndex) newIndex--;
                      final item = ids.removeAt(oldIndex);
                      ids.insert(newIndex, item);
                      await ref
                          .read(bundelProvider.notifier)
                          .update(currentBundle.copyWith(berkasIds: ids));
                    },
                    itemBuilder: (context, index) {
                      final berkas = berkasInBundle[index];
                      return _BerkasInBundelItem(
                        key: ValueKey(berkas.id),
                        berkas: berkas,
                        index: index + 1,
                        onRemove: () => ref
                            .read(bundelProvider.notifier)
                            .removeBerkasFromBundle(
                                currentBundle.id, berkas.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: berkasInBundle.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _exportBundle(context, currentBundle, berkasInBundle),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Export Bundel ke Word'),
                ),
              ),
            )
          : null,
    );
  }

  void _showAddBerkasDialog(
    BuildContext context,
    WidgetRef ref,
    BundelModel bundle,
    List<BerkasModel> allBerkas,
  ) {
    final notInBundle =
        allBerkas.where((b) => !bundle.berkasIds.contains(b.id)).toList();
    if (notInBundle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua berkas sudah ada dalam bundel')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Tambah Berkas ke Bundel',
              style: TextStyle(fontFamily: 'Poppins', 
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notInBundle.length,
              itemBuilder: (ctx, index) {
                final berkas = notInBundle[index];
                return ListTile(
                  leading: Text(berkas.iconName,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(berkas.title),
                  subtitle: Text('${berkas.sections.length} bagian'),
                  onTap: () {
                    ref
                        .read(bundelProvider.notifier)
                        .addBerkasToBundle(bundle.id, berkas.id);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBundle(
    BuildContext context,
    BundelModel bundle,
    List<BerkasModel> berkasInBundle,
  ) async {
    if (berkasInBundle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bundel kosong, tidak ada yang diekspor')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Mengekspor bundel...')),
      );
      await ExportService.exportBundelToDocx(bundle, berkasInBundle);
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('Bundel berhasil diekspor!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger
            .showSnackBar(SnackBar(content: Text('Gagal ekspor: $e')));
      }
    }
  }
}

class _BerkasInBundelItem extends StatelessWidget {
  final BerkasModel berkas;
  final int index;
  final VoidCallback onRemove;

  const _BerkasInBundelItem({
    super.key,
    required this.berkas,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$index',
              style: TextStyle(fontFamily: 'Poppins', 
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(berkas.iconName,
                style: const TextStyle(fontSize: 22)),
          ],
        ),
        title: Text(berkas.title,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        subtitle: Text('${berkas.sections.length} bagian'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_handle,
                color: colorScheme.onSurfaceVariant),
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                  color: colorScheme.error),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
