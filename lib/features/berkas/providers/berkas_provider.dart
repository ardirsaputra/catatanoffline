import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/berkas_model.dart';
import '../../../data/repositories/berkas_repository.dart';
import 'package:uuid/uuid.dart';

final berkasRepositoryProvider = Provider<BerkasRepository>(
  (_) => BerkasRepository(),
);

final berkasProvider = StateNotifierProvider<BerkasNotifier, List<BerkasModel>>((ref) {
  return BerkasNotifier(ref.read(berkasRepositoryProvider));
});

// Search query state
final berkasSearchQueryProvider = StateProvider<String>((_) => '');
final berkasSelectedCategoryProvider = StateProvider<String?>((_) => null);

// Date filter state (set when navigating from activity heatmap)
final berkasFilterDateProvider = StateProvider<DateTime?>((_) => null);

// Filtered berkas
final filteredBerkasProvider = Provider<List<BerkasModel>>((ref) {
  final all = ref.watch(berkasProvider);
  final query = ref.watch(berkasSearchQueryProvider).toLowerCase();
  final cat = ref.watch(berkasSelectedCategoryProvider);
  final filterDate = ref.watch(berkasFilterDateProvider);
  return all.where((b) {
    final matchesQuery = query.isEmpty || b.title.toLowerCase().contains(query);
    final matchesCat = cat == null || b.categoryId == cat;
    final matchesDate = filterDate == null || (b.updatedAt.year == filterDate.year && b.updatedAt.month == filterDate.month && b.updatedAt.day == filterDate.day);
    return matchesQuery && matchesCat && matchesDate;
  }).toList();
});

class BerkasNotifier extends StateNotifier<List<BerkasModel>> {
  final BerkasRepository _repository;
  static const _uuid = Uuid();

  BerkasNotifier(this._repository) : super([]) {
    state = _repository.getAll();
  }

  Future<BerkasModel> create({
    required String title,
    required String categoryId,
    required String iconName,
    required String colorTag,
    String backgroundType = 'solid',
    String backgroundValue = '#FFFFFF',
    List<dynamic>? sections,
  }) async {
    final berkas = BerkasModel(
      id: _uuid.v4(),
      title: title,
      categoryId: categoryId,
      iconName: iconName,
      colorTag: colorTag,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      backgroundType: BerkasBackground.values.firstWhere(
        (e) => e.name == backgroundType,
        orElse: () => BerkasBackground.solid,
      ),
      backgroundValue: backgroundValue,
      sections: [],
    );
    await _repository.save(berkas);
    state = [berkas, ...state];
    return berkas;
  }

  Future<void> update(BerkasModel berkas) async {
    final updated = berkas.copyWith(updatedAt: DateTime.now());
    await _repository.save(updated);
    state = state.map((b) => b.id == berkas.id ? updated : b).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = state.where((b) => b.id != id).toList();
  }

  BerkasModel? getById(String id) => _repository.getById(id);

  void refresh() {
    state = _repository.getAll();
  }
}
