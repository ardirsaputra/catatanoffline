import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/settings_model.dart';
import '../../../data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (_) => SettingsRepository(),
);

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.read(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(SettingsModel.defaults()) {
    state = _repository.get();
  }

  Future<void> update(SettingsModel settings) async {
    state = settings;
    await _repository.save(settings);
  }

  Future<void> setTheme(String preset) => update(state.copyWith(themePreset: preset));

  Future<void> setDarkMode(bool value) => update(state.copyWith(darkMode: value));

  Future<void> setDefaultView(String view) => update(state.copyWith(defaultView: view));

  Future<void> setCardSize(String size) => update(state.copyWith(cardSize: size));

  Future<void> setFontSize(String size) => update(state.copyWith(fontSize: size));

  Future<void> setShowMetadata(bool value) => update(state.copyWith(showMetadata: value));

  Future<void> setDefaultBackground(String bg) => update(state.copyWith(defaultBackground: bg));

  Future<void> setAutoSaveInterval(int seconds) => update(state.copyWith(autoSaveInterval: seconds));

  Future<void> setCustomPrimaryColor(String? colorHex) => update(state.copyWith(customPrimaryColor: colorHex));

  // Kept for backward compatibility
  Future<void> setBiometricEnabled(bool value) => setLockMode(value ? 'biometric' : 'none');

  Future<void> setLockMode(String mode) => update(state.copyWith(lockMode: mode));

  Future<void> setPin({
    required String pinHash,
    required String pinSalt,
    required String lockMode,
  }) =>
      update(state.copyWith(lockMode: lockMode, pinHash: pinHash, pinSalt: pinSalt));

  Future<void> clearPin() => update(SettingsModel(
        themePreset: state.themePreset,
        darkMode: state.darkMode,
        defaultView: state.defaultView,
        cardSize: state.cardSize,
        fontSize: state.fontSize,
        showMetadata: state.showMetadata,
        defaultBackground: state.defaultBackground,
        autoSaveInterval: state.autoSaveInterval,
        customPrimaryColor: state.customPrimaryColor,
        lockMode: 'none',
      ));
}
