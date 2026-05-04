import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/berkas_model.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../berkas/providers/berkas_provider.dart';
import '../../berkas/providers/category_provider.dart';
import '../../editor/screens/editor_screen.dart';
import '../../berkas/screens/berkas_list_screen.dart';
import '../../editor/providers/editor_provider.dart';

class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBerkas = ref.watch(berkasProvider);
    final categories = ref.watch(categoryProvider);
    final recentBerkas = allBerkas.take(5).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'BerkasKu',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: const Color(0xFF3D3D3D),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${allBerkas.length} berkas tersimpan',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF3D3D3D).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Aksi Cepat',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickActionCard(
                    emoji: '➕',
                    label: 'Buat Baru',
                    color: colorScheme.primary,
                    onTap: () => _createNew(context, ref),
                  ),
                  _QuickActionCard(
                    emoji: '📋',
                    label: 'Interview',
                    color: colorScheme.secondary,
                    onTap: () => _createFromTemplate(context, ref, 'builtin_interview'),
                  ),
                  _QuickActionCard(
                    emoji: '✅',
                    label: 'Audit',
                    color: colorScheme.tertiary,
                    onTap: () => _createFromTemplate(context, ref, 'builtin_audit'),
                  ),
                  _QuickActionCard(
                    emoji: '📊',
                    label: 'Survei',
                    color: colorScheme.primaryContainer,
                    onTap: () => _createFromTemplate(context, ref, 'builtin_survey'),
                  ),
                  _QuickActionCard(
                    emoji: '🏥',
                    label: 'Kesehatan',
                    color: colorScheme.secondaryContainer,
                    onTap: () => _createFromTemplate(context, ref, 'builtin_health'),
                  ),
                ],
              ),
            ),
          ),

          // Recent berkas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terbaru',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (allBerkas.isNotEmpty)
                    TextButton(
                      onPressed: () {},
                      child: const Text('Lihat Semua'),
                    ),
                ],
              ),
            ),
          ),

          if (recentBerkas.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text('📂', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada berkas\nBuat berkas pertama Anda!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final berkas = recentBerkas[index];
                  final category = categories
                      .where((c) => c.id == berkas.categoryId)
                      .firstOrNull;
                  return _RecentBerkasItem(
                    berkas: berkas,
                    categoryName: category?.name ?? 'Umum',
                    onTap: () => _openEditor(context, ref, berkas),
                  );
                },
                childCount: recentBerkas.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _createNew(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BerkasListScreen(openCreateDialog: true)),
    );
  }

  void _createFromTemplate(BuildContext context, WidgetRef ref, String templateId) {
    // Navigate to berkas list and trigger template creation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BerkasListScreen(initialTemplateId: templateId),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, BerkasModel berkas) {
    ref.read(editorProvider.notifier).loadBerkas(berkas);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D3D),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentBerkasItem extends StatelessWidget {
  final BerkasModel berkas;
  final String categoryName;
  final VoidCallback onTap;

  const _RecentBerkasItem({
    required this.berkas,
    required this.categoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color tagColor;
    try {
      final hex = berkas.colorTag.replaceFirst('#', '');
      tagColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      tagColor = colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                              color: const Color(0xFF3D3D3D),
                              fontWeight: FontWeight.w500,
                            ),
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
                ),
              ),
              Icon(Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
