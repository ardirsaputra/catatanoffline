import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/bundel_model.dart';
import '../../../data/repositories/bundel_repository.dart';
import 'package:uuid/uuid.dart';

final bundelRepositoryProvider = Provider<BundelRepository>(
  (_) => BundelRepository(),
);

final bundelProvider =
    StateNotifierProvider<BundelNotifier, List<BundelModel>>((ref) {
  return BundelNotifier(ref.read(bundelRepositoryProvider));
});

class BundelNotifier extends StateNotifier<List<BundelModel>> {
  final BundelRepository _repository;
  static const _uuid = Uuid();

  BundelNotifier(this._repository) : super([]) {
    state = _repository.getAll();
  }

  Future<BundelModel> create({
    required String title,
    required String categoryId,
    required String description,
    required List<String> berkasIds,
  }) async {
    final bundle = BundelModel(
      id: _uuid.v4(),
      title: title,
      categoryId: categoryId,
      description: description,
      berkasIds: berkasIds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.save(bundle);
    state = [bundle, ...state];
    return bundle;
  }

  Future<void> update(BundelModel bundle) async {
    final updated = bundle.copyWith(updatedAt: DateTime.now());
    await _repository.save(updated);
    state = state
        .map((b) => b.id == bundle.id ? updated : b)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = state.where((b) => b.id != id).toList();
  }

  Future<void> addBerkasToBundle(String bundleId, String berkasId) async {
    final bundle = state.firstWhere((b) => b.id == bundleId);
    if (bundle.berkasIds.contains(berkasId)) return;
    final updated =
        bundle.copyWith(berkasIds: [...bundle.berkasIds, berkasId]);
    await update(updated);
  }

  Future<void> removeBerkasFromBundle(
      String bundleId, String berkasId) async {
    final bundle = state.firstWhere((b) => b.id == bundleId);
    final updated = bundle.copyWith(
        berkasIds: bundle.berkasIds.where((id) => id != berkasId).toList());
    await update(updated);
  }
}
