import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/section_model.dart';
import '../../../shared/models/template_model.dart';
import '../providers/template_provider.dart';

/// A standalone bottom sheet for browsing and selecting a template.
/// Returns the selected [TemplateModel] via [Navigator.pop].
class TemplatePickerSheet extends ConsumerStatefulWidget {
  const TemplatePickerSheet({super.key});

  static Future<TemplateModel?> show(BuildContext context) {
    return showModalBottomSheet<TemplateModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TemplatePickerSheet(),
    );
  }

  @override
  ConsumerState<TemplatePickerSheet> createState() => _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends ConsumerState<TemplatePickerSheet> {
  TemplateModel? _selectedTemplate;

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Template',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Pilih template sebagai titik awal berkas Anda',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedTemplate != null)
                    FilledButton(
                      onPressed: () => Navigator.pop(context, _selectedTemplate),
                      child: const Text('Gunakan'),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Template list + preview
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template list
                  SizedBox(
                    width: 180,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: templates.length,
                      itemBuilder: (_, index) {
                        final tmpl = templates[index];
                        final selected = _selectedTemplate?.id == tmpl.id;
                        return _TemplateListTile(
                          template: tmpl,
                          selected: selected,
                          onTap: () => setState(() => _selectedTemplate = tmpl),
                          onUse: () => Navigator.pop(context, tmpl),
                        );
                      },
                    ),
                  ),

                  const VerticalDivider(width: 1),

                  // Preview
                  Expanded(
                    child: _selectedTemplate == null ? _EmptyPreview() : _TemplatePreview(template: _selectedTemplate!),
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

// ── Template List Tile ────────────────────────────────────────────────────────

class _TemplateListTile extends StatelessWidget {
  final TemplateModel template;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onUse;

  const _TemplateListTile({
    required this.template,
    required this.selected,
    required this.onTap,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      onDoubleTap: onUse,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer.withOpacity(0.4) : null,
          border: selected ? Border(left: BorderSide(color: colorScheme.primary, width: 3)) : null,
        ),
        child: Row(
          children: [
            Text(
              template.iconEmoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? colorScheme.primary : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (template.isBuiltIn)
                    Text(
                      'Bawaan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
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

// ── Template Preview ──────────────────────────────────────────────────────────

class _TemplatePreview extends StatelessWidget {
  final TemplateModel template;

  const _TemplatePreview({required this.template});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                template.iconEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (template.description.isNotEmpty)
                      Text(
                        template.description,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${template.sectionsData.length} bagian',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (template.sectionsData.isEmpty)
            Text(
              'Template kosong — mulai dari awal',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            Text(
              'Bagian dalam template:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...template.sectionsData.asMap().entries.map((entry) {
              final idx = entry.key;
              final sData = entry.value;
              final typeStr = sData['type'] as String? ?? 'teksBebas';
              final sectionType = SectionType.values.firstWhere(
                (e) => e.name == typeStr,
                orElse: () => SectionType.teksBebas,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(sectionType.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      sectionType.label,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Gunakan Template Ini'),
              onPressed: () => Navigator.pop(context, template),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👈', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'Pilih template\nuntuk melihat pratinjau',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
