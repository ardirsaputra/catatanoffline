import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import 'package:uuid/uuid.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (_) => CategoryRepository(),
);

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<CategoryModel>>((ref) {
  return CategoryNotifier(ref.read(categoryRepositoryProvider));
});

class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  final CategoryRepository _repository;
  static const _uuid = Uuid();

  CategoryNotifier(this._repository) : super([]) {
    state = _repository.getAll();
  }

  Future<void> add({
    required String name,
    required String colorHex,
    required String iconName,
  }) async {
    final category = CategoryModel(
      id: _uuid.v4(),
      name: name,
      colorHex: colorHex,
      iconName: iconName,
      createdAt: DateTime.now(),
    );
    await _repository.save(category);
    state = _repository.getAll();
  }

  Future<void> update(CategoryModel category) async {
    await _repository.save(category);
    state = state.map((c) => c.id == category.id ? category : c).toList();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = state.where((c) => c.id != id).toList();
  }

  CategoryModel? getById(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
