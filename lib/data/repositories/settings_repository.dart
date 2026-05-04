import '../../data/local/hive_service.dart';
import '../../shared/models/settings_model.dart';

class SettingsRepository {
  SettingsModel get() => HiveService.getSettings();
  Future<void> save(SettingsModel settings) =>
      HiveService.saveSettings(settings);
}
