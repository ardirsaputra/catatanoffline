import '../../data/local/hive_service.dart';
import '../../shared/models/category_model.dart';

class CategoryRepository {
  List<CategoryModel> getAll() => HiveService.getAllCategories();
  Future<void> save(CategoryModel category) =>
      HiveService.saveCategory(category);
  Future<void> delete(String id) => HiveService.deleteCategory(id);
}
