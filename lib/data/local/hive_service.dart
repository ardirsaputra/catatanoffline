import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/utils/constants.dart';
import '../../shared/models/berkas_model.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/bundel_model.dart';
import '../../shared/models/settings_model.dart';
import '../../shared/models/template_model.dart';
import 'package:uuid/uuid.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(AppConstants.boxBerkas);
    await Hive.openBox<String>(AppConstants.boxCategories);
    await Hive.openBox<String>(AppConstants.boxBundles);
    await Hive.openBox<String>(AppConstants.boxSettings);
    await Hive.openBox<String>(AppConstants.boxTemplates);
    await _seedDefaultCategories();
  }

  static Future<void> _seedDefaultCategories() async {
    final box = Hive.box<String>(AppConstants.boxCategories);
    if (box.isNotEmpty) return;
    const uuid = Uuid();
    for (final cat in AppConstants.defaultCategories) {
      final category = CategoryModel(
        id: uuid.v4(),
        name: cat['name']!,
        colorHex: cat['color']!,
        iconName: cat['icon']!,
        createdAt: DateTime.now(),
      );
      await box.put(category.id, jsonEncode(category.toMap()));
    }
  }

  // ── Berkas ────────────────────────────────────────────────────────────────
  static Box<String> get berkasBox => Hive.box<String>(AppConstants.boxBerkas);
  static Box<String> get categoriesBox =>
      Hive.box<String>(AppConstants.boxCategories);
  static Box<String> get bundlesBox =>
      Hive.box<String>(AppConstants.boxBundles);
  static Box<String> get settingsBox =>
      Hive.box<String>(AppConstants.boxSettings);
  static Box<String> get templatesBox =>
      Hive.box<String>(AppConstants.boxTemplates);

  // Berkas CRUD
  static List<BerkasModel> getAllBerkas() {
    return berkasBox.values
        .map((json) =>
            BerkasModel.fromMap(Map<String, dynamic>.from(jsonDecode(json))))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static BerkasModel? getBerkasById(String id) {
    final json = berkasBox.get(id);
    if (json == null) return null;
    return BerkasModel.fromMap(
        Map<String, dynamic>.from(jsonDecode(json)));
  }

  static Future<void> saveBerkas(BerkasModel berkas) async {
    await berkasBox.put(berkas.id, jsonEncode(berkas.toMap()));
  }

  static Future<void> deleteBerkas(String id) async {
    await berkasBox.delete(id);
  }

  // Category CRUD
  static List<CategoryModel> getAllCategories() {
    return categoriesBox.values
        .map((json) =>
            CategoryModel.fromMap(Map<String, dynamic>.from(jsonDecode(json))))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static Future<void> saveCategory(CategoryModel category) async {
    await categoriesBox.put(category.id, jsonEncode(category.toMap()));
  }

  static Future<void> deleteCategory(String id) async {
    await categoriesBox.delete(id);
  }

  // Bundle CRUD
  static List<BundelModel> getAllBundles() {
    return bundlesBox.values
        .map((json) =>
            BundelModel.fromMap(Map<String, dynamic>.from(jsonDecode(json))))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> saveBundle(BundelModel bundle) async {
    await bundlesBox.put(bundle.id, jsonEncode(bundle.toMap()));
  }

  static Future<void> deleteBundle(String id) async {
    await bundlesBox.delete(id);
  }

  // Settings
  static SettingsModel getSettings() {
    final json = settingsBox.get(AppConstants.settingsKey);
    if (json == null) return SettingsModel.defaults();
    return SettingsModel.fromMap(
        Map<String, dynamic>.from(jsonDecode(json)));
  }

  static Future<void> saveSettings(SettingsModel settings) async {
    await settingsBox.put(
        AppConstants.settingsKey, jsonEncode(settings.toMap()));
  }

  // Template CRUD
  static List<TemplateModel> getAllTemplates() {
    return templatesBox.values
        .map((json) =>
            TemplateModel.fromMap(Map<String, dynamic>.from(jsonDecode(json))))
        .toList()
      ..sort((a, b) => a.isBuiltIn
          ? -1
          : b.isBuiltIn
              ? 1
              : a.name.compareTo(b.name));
  }

  static Future<void> saveTemplate(TemplateModel template) async {
    await templatesBox.put(template.id, jsonEncode(template.toMap()));
  }

  static Future<void> deleteTemplate(String id) async {
    await templatesBox.delete(id);
  }
}
