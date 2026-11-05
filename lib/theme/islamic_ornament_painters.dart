import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// An authentic Islamic ornamental banner frame for Surah headers.
class SurahOrnamentFrame extends StatelessWidget {
  const SurahOrnamentFrame({
    super.key,
    required this.child,
    this.primaryGold = const Color(0xFFD4AF37),
    this.deepEmerald = const Color(0xFF0D3B2E),
    this.backgroundColor,
  });

  final Widget child;
  final Color primaryGold;
  final Color deepEmerald;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SurahFramePainter(
        goldColor: primaryGold,
        emeraldColor: deepEmerald,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: child,
      ),
    );
  }
}

class _SurahFramePainter extends CustomPainter {
  _SurahFramePainter({required this.goldColor, required this.emeraldColor});

  final Color goldColor;
  final Color emeraldColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(20),
    );

    // 1. Background fill
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          emeraldColor,
          Color.lerp(emeraldColor, Colors.black, 0.25)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    // 2. Outer gold border
    final Paint outerBorder = Paint()
      ..color = goldColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(rrect, outerBorder);

    // 3. Inner inset decorative border
    final RRect innerRRect = rrect.deflate(5.0);
    final Paint innerBorder = Paint()
      ..color = goldColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(innerRRect, innerBorder);

    // 4. Draw Islamic 8-point geometric stars in corners
    _drawCornerStar(canvas, Offset(14, 14), 7, goldColor);
    _drawCornerStar(canvas, Offset(size.width - 14, 14), 7, goldColor);
    _drawCornerStar(canvas, Offset(14, size.height - 14), 7, goldColor);
    _drawCornerStar(
      canvas,
      Offset(size.width - 14, size.height - 14),
      7,
      goldColor,
    );

    // 5. Central ornate floral crest on top & bottom
    _drawCrest(canvas, Offset(size.width / 2, 4), goldColor, isTop: true);
    _drawCrest(
      canvas,
      Offset(size.width / 2, size.height - 4),
      goldColor,
      isTop: false,
    );
  }

  void _drawCornerStar(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw two overlapping rotated squares (classic 8-point star / Rub el Hizb)
    final Path path1 = Path();
    final Path path2 = Path();

    for (var i = 0; i < 4; i++) {
      final double angle1 = i * math.pi / 2;
      final double angle2 = angle1 + math.pi / 4;
      final double x1 = center.dx + radius * math.cos(angle1);
      final double y1 = center.dy + radius * math.sin(angle1);
      final double x2 = center.dx + radius * math.cos(angle2);
      final double y2 = center.dy + radius * math.sin(angle2);

      if (i == 0) {
        path1.moveTo(x1, y1);
        path2.moveTo(x2, y2);
      } else {
        path1.lineTo(x1, y1);
        path2.lineTo(x2, y2);
      }
    }
    path1.close();
    path2.close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);

    // Center dot
    final Paint dotPaint = Paint()..color = color;
    canvas.drawCircle(center, 1.5, dotPaint);
  }

  void _drawCrest(
    Canvas canvas,
    Offset center,
    Color color, {
    required bool isTop,
  }) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Path path = Path();
    final double dir = isTop ? 1 : -1;

    path.moveTo(center.dx - 24, center.dy);
    path.quadraticBezierTo(
      center.dx - 12,
      center.dy + 4 * dir,
      center.dx,
      center.dy + 7 * dir,
    );
    path.quadraticBezierTo(
      center.dx + 12,
      center.dy + 4 * dir,
      center.dx + 24,
      center.dy,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SurahFramePainter oldDelegate) {
    return oldDelegate.goldColor != goldColor ||
        oldDelegate.emeraldColor != emeraldColor;
  }
}

/// Ornate Medina Mushaf page frame wrapper with double gold border and corner ornaments.
class MushafPageBorder extends StatelessWidget {
  const MushafPageBorder({
    super.key,
    required this.child,
    required this.goldColor,
    required this.backgroundColor,
  });

  final Widget child;
  final Color goldColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _MushafPageFramePainter(goldColor: goldColor),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: child,
        ),
      ),
    );
  }
}

class _MushafPageFramePainter extends CustomPainter {
  _MushafPageFramePainter({required this.goldColor});

  final Color goldColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect outer = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(16),
    );
    final RRect inner = outer.deflate(6.0);
    final RRect thinLine = inner.deflate(3.5);

    // 1. Thick primary border
    final Paint borderPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(inner, borderPaint);

    // 2. Delicate inner parallel line
    final Paint thinPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    canvas.drawRRect(thinLine, thinPaint);

    // 3. Corner rosettes
    const double offset = 14.0;
    _drawCornerRosette(canvas, Offset(offset, offset), goldColor);
    _drawCornerRosette(canvas, Offset(size.width - offset, offset), goldColor);
    _drawCornerRosette(canvas, Offset(offset, size.height - offset), goldColor);
    _drawCornerRosette(
      canvas,
      Offset(size.width - offset, size.height - offset),
      goldColor,
    );
  }

  void _drawCornerRosette(Canvas canvas, Offset center, Color color) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawCircle(center, 4.0, paint);
    canvas.drawCircle(
      center,
      1.5,
      Paint()..color = color.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _MushafPageFramePainter oldDelegate) {
    return oldDelegate.goldColor != goldColor;
  }
}

/// Ornate Ayah ending marker with Arabic numeral inside.
class AyahEndOrnament extends StatelessWidget {
  const AyahEndOrnament({
    super.key,
    required this.number,
    this.color = const Color(0xFFD4AF37),
    this.fontSize = 14,
  });

  final int number;
  final Color color;
  final double fontSize;

  static String toArabicDigits(int n) {
    return n
        .toString()
        .split('')
        .map((String d) => String.fromCharCode(0x0660 + int.parse(d)))
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.2),
        color: color.withValues(alpha: 0.08),
      ),
      child: Text(
        toArabicDigits(number),
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: context.quranType.arabicFamily,
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
