import 'package:flutter/material.dart';
import '../../../../shared/models/section_model.dart';
import 'package:uuid/uuid.dart';

class ChecklistWidget extends StatefulWidget {
  final SectionModel section;
  final void Function(SectionModel) onChanged;

  const ChecklistWidget(
      {super.key, required this.section, required this.onChanged});

  @override
  State<ChecklistWidget> createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> {
  static const _uuid = Uuid();
  late final TextEditingController _titleCtrl;
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
        text: widget.section.data['title'] as String? ?? 'Daftar Periksa');
    _items = _loadItems();
  }

  List<Map<String, dynamic>> _loadItems() {
    final raw = widget.section.data['items'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged(widget.section.copyWith(data: {
      'title': _titleCtrl.text,
      'items': _items,
    }));
  }

  void _addItem() {
    setState(() {
      _items.add({
        'id': _uuid.v4(),
        'text': '',
        'checked': false,
      });
    });
    _update();
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    _update();
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index]['checked'] = !(_items[index]['checked'] as bool);
    });
    _update();
  }

  int get _checkedCount =>
      _items.where((i) => i['checked'] == true).length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _titleCtrl,
                onChanged: (_) => _update(),
                style: TextStyle(fontFamily: 'Poppins', 
                    fontWeight: FontWeight.w600, fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  filled: false,
                  hintText: 'Judul checklist',
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_checkedCount/${_items.length} selesai',
                style: TextStyle(fontFamily: 'Poppins', 
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final textCtrl =
              TextEditingController(text: item['text'] as String? ?? '');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: item['checked'] as bool? ?? false,
                  onChanged: (_) => _toggleItem(idx),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    onChanged: (v) {
                      _items[idx]['text'] = v;
                      _update();
                    },
                    style: TextStyle(fontFamily: 'Poppins', 
                      fontSize: 14,
                      decoration: item['checked'] == true
                          ? TextDecoration.lineThrough
                          : null,
                      color: item['checked'] == true
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Item checklist...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      filled: false,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      size: 18, color: colorScheme.error),
                  onPressed: () => _removeItem(idx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah Item'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }
}
