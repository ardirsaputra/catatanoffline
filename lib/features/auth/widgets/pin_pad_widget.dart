import 'package:flutter/material.dart';

/// Reusable PIN entry pad widget.
/// [pinLength]  – number of digits required (default 6).
/// [onComplete] – called once [pinLength] digits are entered.
/// [errorText]  – optional error message shown below the dots.
/// Use a [ValueKey] that changes on each failed attempt to reset state.
class PinPadWidget extends StatefulWidget {
  final int pinLength;
  final void Function(String pin) onComplete;
  final String? errorText;
  final bool enabled;

  const PinPadWidget({
    super.key,
    this.pinLength = 6,
    required this.onComplete,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<PinPadWidget> createState() => _PinPadWidgetState();
}

class _PinPadWidgetState extends State<PinPadWidget> with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void didUpdateWidget(PinPadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If errorText appeared, run shake
    if (widget.errorText != null && oldWidget.errorText == null) {
      _shakeController.forward(from: 0);
      setState(() => _pin = '');
      _completed = false;
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _addDigit(String d) {
    if (!widget.enabled || _completed) return;
    if (_pin.length >= widget.pinLength) return;
    setState(() => _pin += d);
    if (_pin.length == widget.pinLength) {
      _completed = true;
      Future.microtask(() => widget.onComplete(_pin));
    }
  }

  void _backspace() {
    if (!widget.enabled || _pin.isEmpty || _completed) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dots
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (_, child) => Transform.translate(offset: Offset(_shakeAnimation.value, 0), child: child),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pinLength, (i) {
              final filled = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? Colors.white : Colors.white.withOpacity(0.30),
                  border: Border.all(
                    color: Colors.white.withOpacity(filled ? 0.0 : 0.60),
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
        ),

        // Error text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.errorText != null
              ? Padding(
                  key: ValueKey(widget.errorText),
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFFFFB4B4),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox(key: ValueKey('none'), height: 12),
        ),

        const SizedBox(height: 28),

        // Number pad
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                if (key.isEmpty) return const SizedBox(width: 80, height: 64);
                return _PadKey(
                  label: key,
                  enabled: widget.enabled && !_completed,
                  onTap: () {
                    if (key == '⌫') {
                      _backspace();
                    } else {
                      _addDigit(key);
                    }
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PadKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _PadKey({required this.label, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 80,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(enabled ? 0.15 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(enabled ? 0.30 : 0.10),
          ),
        ),
        child: Center(
          child: label == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  color: Colors.white.withOpacity(enabled ? 0.9 : 0.4),
                  size: 22,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(enabled ? 1.0 : 0.4),
                  ),
                ),
        ),
      ),
    );
  }
}
