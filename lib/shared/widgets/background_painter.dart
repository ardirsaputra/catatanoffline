import 'package:flutter/material.dart';
import '../../shared/models/berkas_model.dart';

class BackgroundPainter extends CustomPainter {
  final BerkasBackground type;
  final String colorValue;
  final bool isDark;

  BackgroundPainter({
    required this.type,
    required this.colorValue,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Color bgColor;
    try {
      final hex = colorValue.replaceFirst('#', '');
      bgColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );

    switch (type) {
      case BerkasBackground.dots:
        _paintDots(canvas, size, bgColor);
      case BerkasBackground.lines:
        _paintLines(canvas, size, bgColor);
      case BerkasBackground.watercolor:
        _paintWatercolor(canvas, size, bgColor);
      default:
        break;
    }
  }

  void _paintDots(Canvas canvas, Size size, Color bg) {
    final dotColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.8, paint);
      }
    }
  }

  void _paintLines(Canvas canvas, Size size, Color bg) {
    final lineColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05);
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;
    const spacing = 32.0;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintWatercolor(Canvas canvas, Size size, Color bg) {
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [
      const Color(0xFFA8D8EA).withOpacity(0.08),
      const Color(0xFFB5EAD7).withOpacity(0.06),
      const Color(0xFFFFDFD3).withOpacity(0.07),
    ];
    final offsets = [
      Offset(size.width * 0.2, size.height * 0.15),
      Offset(size.width * 0.75, size.height * 0.35),
      Offset(size.width * 0.4, size.height * 0.75),
    ];
    for (var i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      canvas.drawCircle(offsets[i], size.width * 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.colorValue != colorValue ||
      oldDelegate.isDark != isDark;
}
