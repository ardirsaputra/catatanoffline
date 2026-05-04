import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/hive_service.dart';
import '../services/biometric_service.dart';

/// Hash a PIN using SHA-256 with a per-device salt.
String hashAppPin(String pin, String salt) {
  final bytes = utf8.encode('$salt:$pin');
  return sha256.convert(bytes).toString();
}

const int _maxAttempts = 10;
const Duration _lockoutDuration = Duration(minutes: 10);

class AuthState {
  final bool isAuthenticated;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final bool biometricAvailable;
  final bool isAuthenticating;
  final bool showPinPad;
  final String? pinError;

  const AuthState({
    this.isAuthenticated = false,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.biometricAvailable = false,
    this.isAuthenticating = false,
    this.showPinPad = false,
    this.pinError,
  });

  bool get isLockedOut {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  Duration get remainingLockout {
    if (lockedUntil == null) return Duration.zero;
    final diff = lockedUntil!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  AuthState copyWith({
    bool? isAuthenticated,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLock = false,
    bool? biometricAvailable,
    bool? isAuthenticating,
    bool? showPinPad,
    Object? pinError = _authSentinel,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      showPinPad: showPinPad ?? this.showPinPad,
      pinError: pinError == _authSentinel ? this.pinError : pinError as String?,
    );
  }
}

const Object _authSentinel = Object();

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final available = await BiometricService.isAvailable();
    final saved = HiveService.getAuthState();
    final failedAttempts = (saved['failedAttempts'] as num?)?.toInt() ?? 0;
    DateTime? lockedUntil;
    if (saved['lockedUntil'] != null) {
      lockedUntil = DateTime.tryParse(saved['lockedUntil'] as String);
    }

    // Clear expired lockout
    if (lockedUntil != null && DateTime.now().isAfter(lockedUntil)) {
      lockedUntil = null;
      await HiveService.resetAuthState();
    }

    state = AuthState(
      isAuthenticated: false,
      failedAttempts: failedAttempts,
      lockedUntil: lockedUntil,
      biometricAvailable: available,
      isAuthenticating: false,
    );
  }

  Future<void> authenticate() async {
    if (state.isLockedOut || state.isAuthenticating) return;

    state = state.copyWith(isAuthenticating: true);

    final success = await BiometricService.authenticate();

    if (success) {
      await HiveService.resetAuthState();
      state = state.copyWith(
        isAuthenticated: true,
        failedAttempts: 0,
        clearLock: true,
        isAuthenticating: false,
      );
    } else {
      final newFailed = state.failedAttempts + 1;
      DateTime? lockUntil;
      if (newFailed >= _maxAttempts) {
        lockUntil = DateTime.now().add(_lockoutDuration);
        await HiveService.saveAuthState({
          'failedAttempts': newFailed,
          'lockedUntil': lockUntil.toIso8601String(),
        });
      } else {
        await HiveService.saveAuthState({
          'failedAttempts': newFailed,
          'lockedUntil': null,
        });
      }
      state = state.copyWith(
        failedAttempts: newFailed,
        lockedUntil: lockUntil,
        isAuthenticating: false,
      );
    }
  }

  /// Bypass auth (used when no lock mode is set in settings)
  void bypassAuth() {
    state = state.copyWith(isAuthenticated: true);
  }

  /// Switch to PIN pad (used when lockMode == 'both' and user wants PIN)
  void switchToPinPad() {
    state = state.copyWith(showPinPad: true, pinError: null);
  }

  /// Authenticate with a PIN; pinHash and pinSalt come from settings.
  Future<void> authenticateWithPin(String pin, String storedHash, String salt) async {
    if (state.isLockedOut) return;
    final hash = hashAppPin(pin, salt);
    if (hash == storedHash) {
      await HiveService.resetAuthState();
      state = state.copyWith(
        isAuthenticated: true,
        failedAttempts: 0,
        clearLock: true,
        pinError: null,
      );
    } else {
      final newFailed = state.failedAttempts + 1;
      DateTime? lockUntil;
      if (newFailed >= _maxAttempts) {
        lockUntil = DateTime.now().add(_lockoutDuration);
        await HiveService.saveAuthState({
          'failedAttempts': newFailed,
          'lockedUntil': lockUntil.toIso8601String(),
        });
      } else {
        await HiveService.saveAuthState({'failedAttempts': newFailed, 'lockedUntil': null});
      }
      state = state.copyWith(
        failedAttempts: newFailed,
        lockedUntil: lockUntil,
        pinError: 'PIN salah. ${_maxAttempts - newFailed} percobaan tersisa.',
      );
    }
  }

  void clearPinError() {
    state = state.copyWith(pinError: null);
  }

  /// Tick countdown — call every second while locked
  void tick() {
    if (state.isLockedOut) {
      state = state.copyWith(); // force rebuild for timer
    } else if (state.lockedUntil != null) {
      // Lockout expired
      HiveService.resetAuthState();
      state = AuthState(
        isAuthenticated: false,
        failedAttempts: 0,
        lockedUntil: null,
        biometricAvailable: state.biometricAvailable,
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
