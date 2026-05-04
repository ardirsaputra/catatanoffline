class AppConstants {
  static const String appName = 'BerkasKu';
  static const String appVersion = '1.0.0';

  // Hive box names
  static const String boxBerkas = 'berkas';
  static const String boxCategories = 'categories';
  static const String boxBundles = 'bundles';
  static const String boxSettings = 'settings';
  static const String boxTemplates = 'templates';

  static const String settingsKey = 'app_settings';

  // Default categories
  static const List<Map<String, String>> defaultCategories = [
    {'name': 'Umum', 'icon': '📄', 'color': '#A8D8EA'},
    {'name': 'Interview Klien', 'icon': '💬', 'color': '#FFDFD3'},
    {'name': 'Audit', 'icon': '🔍', 'color': '#B5EAD7'},
    {'name': 'Kuesioner Kesehatan', 'icon': '🏥', 'color': '#FFB5C8'},
    {'name': 'Survei', 'icon': '📊', 'color': '#C9B8E8'},
  ];

  // Card icon options
  static const List<String> cardIcons = [
    '📄', '📋', '📝', '🗒️', '📊', '📈', '📉',
    '💼', '🗂️', '📁', '📂', '🔍', '✅', '☑️',
    '💬', '🏥', '🔬', '⚙️', '🎯', '📌', '🔖',
  ];

  // Color tag options
  static const List<String> colorTags = [
    '#A8D8EA', '#FFDFD3', '#B5EAD7', '#FFB5C8',
    '#C9B8E8', '#FFE5A0', '#B8D4E8', '#F5E6CC',
    '#D4F5E9', '#FFD4E0', '#E8D5F5', '#CCE8FF',
  ];
}
