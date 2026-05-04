import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final now = DateTime.now();
    final thisWeekBerkas = allBerkas.where((b) => b.updatedAt.isAfter(now.subtract(const Duration(days: 7)))).length;
    final todayBerkas = allBerkas.where((b) => b.createdAt.year == now.year && b.createdAt.month == now.month && b.createdAt.day == now.day).length;

    // Activity last 7 days: count berkas updated each day
    final activityData = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return allBerkas.where((b) => b.updatedAt.year == day.year && b.updatedAt.month == day.month && b.updatedAt.day == day.day).length;
    });

    final greeting = _greeting(now.hour);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, colorScheme, allBerkas.length, greeting, now),

          // ── Insight cards ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InsightCard(
                          icon: Icons.folder_rounded,
                          value: '${allBerkas.length}',
                          label: 'Total Berkas',
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InsightCard(
                          icon: Icons.today_rounded,
                          value: '$todayBerkas',
                          label: 'Dibuat Hari Ini',
                          color: const Color(0xFFFF6584),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InsightCard(
                          icon: Icons.date_range_rounded,
                          value: '$thisWeekBerkas',
                          label: 'Minggu Ini',
                          color: const Color(0xFF43C59E),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InsightCard(
                          icon: Icons.label_rounded,
                          value: '${categories.length}',
                          label: 'Kategori',
                          color: const Color(0xFFFF9A3C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Activity sparkline ─────────────────────────────────
          if (allBerkas.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _ActivitySparkline(
                  activityData: activityData,
                  colorScheme: colorScheme,
                ),
              ),
            ),

          // ── Quick actions ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Aksi Cepat',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickActionCard(
                    emoji: '➕',
                    label: 'Buat Baru',
                    gradient: const [Color(0xFF6C63FF), Color(0xFF957FEF)],
                    onTap: () => _createNew(context, ref),
                  ),
                  _QuickActionCard(
                    emoji: '📋',
                    label: 'Interview',
                    gradient: const [Color(0xFF43C59E), Color(0xFF2CB5A0)],
                    onTap: () => _createFromTemplate(context, ref, 'builtin_interview'),
                  ),
                  _QuickActionCard(
                    emoji: '✅',
                    label: 'Audit',
                    gradient: const [Color(0xFFFF9A3C), Color(0xFFFF6B35)],
                    onTap: () => _createFromTemplate(context, ref, 'builtin_audit'),
                  ),
                  _QuickActionCard(
                    emoji: '📊',
                    label: 'Survei',
                    gradient: const [Color(0xFFFF6584), Color(0xFFFF4F7B)],
                    onTap: () => _createFromTemplate(context, ref, 'builtin_survey'),
                  ),
                ],
              ),
            ),
          ),

          // ── Recent berkas ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terbaru',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (allBerkas.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Lihat Semua'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (recentBerkas.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(colorScheme: colorScheme),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final berkas = recentBerkas[index];
                  final catWhere = categories.where((c) => c.id == berkas.categoryId);
                  final category = catWhere.isEmpty ? null : catWhere.first;
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

  String _greeting(int hour) {
    if (hour < 11) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    ColorScheme colorScheme,
    int total,
    String greeting,
    DateTime now,
  ) {
    final weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dateStr = '${weekDays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return SliverAppBar(
      expandedHeight: 190,
      floating: false,
      pinned: true,
      title: const Text(
        'BerkasKu offline',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF957FEF),
                Color(0xFFB09FFF),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // decorative blobs
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                left: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$total berkas',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BerkasListScreen(initialTemplateId: templateId)),
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

// ── Insight Card ────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Sparkline ──────────────────────────────────────────────────────

class _ActivitySparkline extends StatelessWidget {
  final List<int> activityData;
  final ColorScheme colorScheme;

  const _ActivitySparkline({required this.activityData, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return names[d.weekday - 1];
    });
    final maxVal = activityData.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFF6C63FF)),
              const SizedBox(width: 6),
              Text(
                'Aktivitas 7 Hari Terakhir',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = activityData[i];
                final frac = maxVal == 0 ? 0.0 : val / maxVal;
                final isToday = i == 6;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (val > 0)
                        Text(
                          '$val',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isToday ? const Color(0xFF6C63FF) : const Color(0xFF9E9E9E),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: maxVal == 0 ? 4 : (40 * frac).clamp(4, 40),
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFF6C63FF), Color(0xFF957FEF)],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF9E9E9E).withOpacity(0.5),
                                      const Color(0xFF9E9E9E).withOpacity(0.3),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayLabels[i],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                          color: isToday ? const Color(0xFF6C63FF) : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Card ───────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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

// ── Recent Berkas Item ──────────────────────────────────────────────────────

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: tagColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.15),
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
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3D3D3D),
                            ),
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
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded, color: tagColor, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withOpacity(0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Text('📂', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada berkas',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D3D3D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Buat berkas pertama Anda\nmenggunakan tombol di atas!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
