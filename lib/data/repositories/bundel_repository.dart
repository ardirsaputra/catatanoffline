import '../../data/local/hive_service.dart';
import '../../shared/models/bundel_model.dart';

class BundelRepository {
  List<BundelModel> getAll() => HiveService.getAllBundles();
  Future<void> save(BundelModel bundle) => HiveService.saveBundle(bundle);
  Future<void> delete(String id) => HiveService.deleteBundle(id);
}
