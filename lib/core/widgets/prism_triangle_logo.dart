import 'package:flutter/material.dart';

/// PrismTV Brand Triangle Logo
/// Uses the official brand icon asset ('assets/icons/app_icon.png')
/// featuring the signature diagonal gradient and #1C1613 prism triangle,
/// with smooth rounded squircle corners, ambient glow, and vector fallback.
class PrismTriangleLogo extends StatelessWidget {
  final double size;
  final bool hasGlow;

  const PrismTriangleLogo({
    super.key,
    this.size = 32,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => CustomPaint(
          size: Size(size, size),
          painter: const _GeometricTrianglePainter(),
        ),
      ),
    );

    if (hasGlow) {
      logo = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.24),
          boxShadow: [
            BoxShadow(
              color: const Color(0x55A839C7),
              blurRadius: size * 0.50,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: const Color(0x35CB907D),
              blurRadius: size * 0.30,
              spreadRadius: 0,
            ),
          ],
        ),
        child: logo,
      );
    }

    return logo;
  }
}

/// Upward-pointing Geometric Prism Triangle Painter Fallback (Δ)
class _GeometricTrianglePainter extends CustomPainter {
  const _GeometricTrianglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Upward-pointing Triangle Vertices (Δ):
    final apex = Offset(w * 0.50, h * 0.08);
    final bottomLeft = Offset(w * 0.10, h * 0.90);
    final bottomRight = Offset(w * 0.90, h * 0.90);
    final centerPoint = Offset(w * 0.50, h * 0.62);

    // 1. LEFT FACET: Sunset Terracotta (#CB907D) -> Electric Violet (#A839C7)
    final leftGradient = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFFCB907D), // Terracotta
        Color(0xFFA839C7), // Electric Violet
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final paintLeft = Paint()
      ..shader = leftGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leftPath = Path();
    leftPath.moveTo(apex.dx, apex.dy);
    leftPath.lineTo(bottomLeft.dx, bottomLeft.dy);
    leftPath.lineTo(centerPoint.dx, centerPoint.dy);
    leftPath.close();
    canvas.drawPath(leftPath, paintLeft);

    // 2. RIGHT FACET: Electric Violet (#A839C7) -> Deep Violet
    final rightGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFA839C7), // Electric Violet
        Color(0xFF1C1613), // Brand Obsidian
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final paintRight = Paint()
      ..shader = rightGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rightPath = Path();
    rightPath.moveTo(apex.dx, apex.dy);
    rightPath.lineTo(bottomRight.dx, bottomRight.dy);
    rightPath.lineTo(centerPoint.dx, centerPoint.dy);
    rightPath.close();
    canvas.drawPath(rightPath, paintRight);

    // 3. BASE FACET:
    final baseGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1C1613), // Brand Obsidian
        Color(0x991C1613),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final paintBase = Paint()
      ..shader = baseGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final basePath = Path();
    basePath.moveTo(bottomLeft.dx, bottomLeft.dy);
    basePath.lineTo(bottomRight.dx, bottomRight.dy);
    basePath.lineTo(centerPoint.dx, centerPoint.dy);
    basePath.close();
    canvas.drawPath(basePath, paintBase);

    // 4. Subtle Specular Apex Reflection
    final apexGlowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFF4F4F4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: apex, radius: w * 0.15))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(apex, w * 0.15, apexGlowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
