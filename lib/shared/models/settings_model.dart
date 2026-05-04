const Object _sentinel = Object();

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

  // Security – lockMode: 'none' | 'biometric' | 'pin' | 'both'
  final String lockMode;
  final String? pinHash; // SHA-256(salt:pin)
  final String? pinSalt; // random UUID per device

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
    this.lockMode = 'none',
    this.pinHash,
    this.pinSalt,
  });

  /// True when biometric auth is required on app open.
  bool get biometricEnabled => lockMode == 'biometric' || lockMode == 'both';

  /// True when PIN auth is required on app open.
  bool get pinEnabled => lockMode == 'pin' || lockMode == 'both';

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
        'lockMode': lockMode,
        'pinHash': pinHash,
        'pinSalt': pinSalt,
      };

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    // Backward compat: old biometricEnabled:true => lockMode:'biometric'
    final oldBio = map['biometricEnabled'] as bool? ?? false;
    final lockMode = map['lockMode'] as String? ?? (oldBio ? 'biometric' : 'none');
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
      lockMode: lockMode,
      pinHash: map['pinHash'] as String?,
      pinSalt: map['pinSalt'] as String?,
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
    String? lockMode,
    Object? pinHash = _sentinel,
    Object? pinSalt = _sentinel,
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
      customPrimaryColor: customPrimaryColor == _sentinel ? this.customPrimaryColor : customPrimaryColor as String?,
      lockMode: lockMode ?? this.lockMode,
      pinHash: pinHash == _sentinel ? this.pinHash : pinHash as String?,
      pinSalt: pinSalt == _sentinel ? this.pinSalt : pinSalt as String?,
    );
  }
}
