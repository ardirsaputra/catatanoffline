import '../../data/local/hive_service.dart';
import '../../shared/models/berkas_model.dart';

class BerkasRepository {
  List<BerkasModel> getAll() => HiveService.getAllBerkas();
  BerkasModel? getById(String id) => HiveService.getBerkasById(id);
  Future<void> save(BerkasModel berkas) => HiveService.saveBerkas(berkas);
  Future<void> delete(String id) => HiveService.deleteBerkas(id);
}
