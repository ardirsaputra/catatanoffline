class SettingsModel {
  final String themePreset; // biru, lavender, mint, peach, rose
  final bool darkMode;
  final String defaultView; // grid, list
  final String cardSize; // compact, normal, large
  final String fontSize; // small, medium, large
  final bool showMetadata;
  final String defaultBackground; // solid, dots, lines, watercolor
  final int autoSaveInterval; // seconds: 5, 10, 30
  final String? customPrimaryColor; // hex string

  const SettingsModel({
    this.themePreset = 'biru',
    this.darkMode = false,
    this.defaultView = 'grid',
    this.cardSize = 'normal',
    this.fontSize = 'medium',
    this.showMetadata = true,
    this.defaultBackground = 'solid',
    this.autoSaveInterval = 10,
    this.customPrimaryColor,
  });

  static SettingsModel defaults() => const SettingsModel();

  Map<String, dynamic> toMap() => {
        'themePreset': themePreset,
        'darkMode': darkMode,
        'defaultView': defaultView,
        'cardSize': cardSize,
        'fontSize': fontSize,
        'showMetadata': showMetadata,
        'defaultBackground': defaultBackground,
        'autoSaveInterval': autoSaveInterval,
        'customPrimaryColor': customPrimaryColor,
      };

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      themePreset: map['themePreset'] as String? ?? 'biru',
      darkMode: map['darkMode'] as bool? ?? false,
      defaultView: map['defaultView'] as String? ?? 'grid',
      cardSize: map['cardSize'] as String? ?? 'normal',
      fontSize: map['fontSize'] as String? ?? 'medium',
      showMetadata: map['showMetadata'] as bool? ?? true,
      defaultBackground: map['defaultBackground'] as String? ?? 'solid',
      autoSaveInterval: (map['autoSaveInterval'] as num?)?.toInt() ?? 10,
      customPrimaryColor: map['customPrimaryColor'] as String?,
    );
  }

  SettingsModel copyWith({
    String? themePreset,
    bool? darkMode,
    String? defaultView,
    String? cardSize,
    String? fontSize,
    bool? showMetadata,
    String? defaultBackground,
    int? autoSaveInterval,
    Object? customPrimaryColor = _sentinel,
  }) {
    return SettingsModel(
      themePreset: themePreset ?? this.themePreset,
      darkMode: darkMode ?? this.darkMode,
      defaultView: defaultView ?? this.defaultView,
      cardSize: cardSize ?? this.cardSize,
      fontSize: fontSize ?? this.fontSize,
      showMetadata: showMetadata ?? this.showMetadata,
      defaultBackground: defaultBackground ?? this.defaultBackground,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      customPrimaryColor: customPrimaryColor == _sentinel
          ? this.customPrimaryColor
          : customPrimaryColor as String?,
    );
  }
}

const Object _sentinel = Object();
