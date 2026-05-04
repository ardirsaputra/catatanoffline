import '../../data/local/hive_service.dart';
import '../../shared/models/template_model.dart';

class TemplateRepository {
  List<TemplateModel> getAll() => HiveService.getAllTemplates();
  Future<void> save(TemplateModel template) =>
      HiveService.saveTemplate(template);
  Future<void> delete(String id) => HiveService.deleteTemplate(id);
}
