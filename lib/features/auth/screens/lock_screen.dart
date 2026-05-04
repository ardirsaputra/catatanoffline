import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_pad_widget.dart';
import '../../settings/providers/settings_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(authProvider.notifier).tick();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  void _tryBiometric() {
    final auth = ref.read(authProvider);
    final settings = ref.read(settingsProvider);
    final showBio = settings.lockMode == 'biometric' || (settings.lockMode == 'both' && !auth.showPinPad && auth.biometricAvailable);
    if (!auth.isLockedOut && showBio) {
      ref.read(authProvider.notifier).authenticate();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final lockMode = settings.lockMode;

    final showPin = (lockMode == 'pin') || (lockMode == 'both' && (auth.showPinPad || !auth.biometricAvailable));
    final canSwitchToPin = lockMode == 'both' && !auth.showPinPad && auth.biometricAvailable;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFF957FEF), Color(0xFF4A90D9)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(top: -60, right: -40, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
              Positioned(bottom: -80, left: -50, child: Container(width: 280, height: 280, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                        ),
                        child: const Icon(Icons.folder_special_rounded, size: 42, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text('BerkasKu', style: TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        showPin ? 'Masukkan PIN' : 'Autentikasi diperlukan',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withOpacity(0.75)),
                      ),
                      const SizedBox(height: 36),

                      // Locked state
                      if (auth.isLockedOut)
                        _LockedCard(remaining: auth.remainingLockout, fmt: _fmt)
                      else if (showPin)
                        _PinSection(
                          auth: auth,
                          settings: settings,
                          onBioSwitch: lockMode == 'both' && auth.biometricAvailable
                              ? () {
                                  ref.read(authProvider.notifier).clearPinError();
                                  setState(() {});
                                  // reset showPinPad via auth notifier - force biometric
                                  ref.read(authProvider.notifier).authenticate();
                                }
                              : null,
                        )
                      else ...[
                        // Biometric section
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: GestureDetector(
                            onTap: auth.isAuthenticating ? null : () => ref.read(authProvider.notifier).authenticate(),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.50), width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, spreadRadius: 2)],
                              ),
                              child: auth.isAuthenticating
                                  ? const Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Icon(Icons.fingerprint, size: 54, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          auth.isAuthenticating ? 'Memverifikasi...' : 'Sentuh untuk membuka',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.90)),
                        ),

                        if (auth.failedAttempts > 0) ...[
                          const SizedBox(height: 20),
                          _AttemptsIndicator(failed: auth.failedAttempts, max: 10),
                        ],

                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: auth.isAuthenticating ? null : () => ref.read(authProvider.notifier).authenticate(),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                          label: const Text('Coba lagi', style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 13)),
                        ),

                        // Switch to PIN option
                        if (canSwitchToPin) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref.read(authProvider.notifier).switchToPinPad(),
                            child: Text('Gunakan PIN',
                                style: TextStyle(
                                    fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withOpacity(0.80), decoration: TextDecoration.underline, decorationColor: Colors.white.withOpacity(0.80))),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── PIN Section ───────────────────────────────────────────────────────────────

class _PinSection extends ConsumerWidget {
  final dynamic auth;
  final dynamic settings;
  final VoidCallback? onBioSwitch;

  const _PinSection({required this.auth, required this.settings, this.onBioSwitch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        PinPadWidget(
          key: ValueKey(auth.failedAttempts),
          pinLength: 6,
          enabled: !auth.isLockedOut,
          errorText: auth.pinError,
          onComplete: (pin) async {
            if (settings.pinHash != null && settings.pinSalt != null) {
              await ref.read(authProvider.notifier).authenticateWithPin(
                    pin,
                    settings.pinHash!,
                    settings.pinSalt!,
                  );
            }
          },
        ),
        if (auth.failedAttempts > 0 && auth.pinError == null) ...[
          const SizedBox(height: 16),
          _AttemptsIndicator(failed: auth.failedAttempts, max: 10),
        ],
        if (onBioSwitch != null) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onBioSwitch,
            icon: const Icon(Icons.fingerprint, color: Colors.white70, size: 18),
            label: const Text('Gunakan Biometrik', style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 13)),
          ),
        ],
      ],
    );
  }
}

// ── Locked Card ───────────────────────────────────────────────────────────────

class _LockedCard extends StatelessWidget {
  final Duration remaining;
  final String Function(Duration) fmt;

  const _LockedCard({required this.remaining, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.25), shape: BoxShape.circle),
            child: const Icon(Icons.lock_outlined, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Aplikasi Dikunci', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Terlalu banyak percobaan gagal.\nCoba lagi dalam:', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withOpacity(0.75))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
            child: Text(fmt(remaining), style: const TextStyle(fontFamily: 'Poppins', fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 4)),
          ),
          const SizedBox(height: 14),
          Text('Dikunci setelah 10 percobaan gagal selama 10 menit.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withOpacity(0.55))),
        ],
      ),
    );
  }
}

// ── Attempts indicator ────────────────────────────────────────────────────────

class _AttemptsIndicator extends StatelessWidget {
  final int failed;
  final int max;

  const _AttemptsIndicator({required this.failed, required this.max});

  @override
  Widget build(BuildContext context) {
    final remaining = max - failed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (failed >= 7 ? Colors.red : Colors.white).withOpacity(0.30)),
      ),
      child: Column(
        children: [
          Text('$remaining percobaan tersisa', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: failed >= 7 ? const Color(0xFFFFB4B4) : Colors.white)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                max,
                (i) => Container(
                      width: 16,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: i < failed ? Colors.red.withOpacity(0.80) : Colors.white.withOpacity(0.35)),
                    )),
          ),
        ],
      ),
    );
  }
}
