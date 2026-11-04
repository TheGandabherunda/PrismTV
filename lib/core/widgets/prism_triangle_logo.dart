import 'package:flutter/material.dart';

/// PrismTV Brand Triangle Logo
/// Pure, modern, geometric TRIANGLE (Δ prism pointing UP, NOT a play button)
/// Direct on OLED black with signature Sunset Coral -> Rose Orchid -> Electric Violet facets
/// and crisp white internal light reflection.
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
    Widget logo = CustomPaint(
      size: Size(size, size),
      painter: const _GeometricTrianglePainter(),
    );

    if (hasGlow) {
      logo = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0x50A51EE5),
              blurRadius: size * 0.55,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: const Color(0x35F28B6E),
              blurRadius: size * 0.35,
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

/// Upward-pointing Geometric Prism Triangle Painter (Δ)
class _GeometricTrianglePainter extends CustomPainter {
  const _GeometricTrianglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Upward-pointing Triangle Vertices (Δ):
    // Top apex: (w * 0.50, h * 0.08)
    // Bottom-left: (w * 0.10, h * 0.90)
    // Bottom-right: (w * 0.90, h * 0.90)
    // Center facet point: (w * 0.50, h * 0.62)

    final apex = Offset(w * 0.50, h * 0.08);
    final bottomLeft = Offset(w * 0.10, h * 0.90);
    final bottomRight = Offset(w * 0.90, h * 0.90);
    final centerPoint = Offset(w * 0.50, h * 0.62);

    // 1. LEFT FACET: Sunset Coral (#F28B6E) -> Rose Orchid (#C76F97)
    final leftGradient = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFFF28B6E), // Warm Sunset Coral / Peach
        Color(0xFFC76F97), // Rose Orchid
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

    // 2. RIGHT FACET: Rose Orchid (#C76F97) -> Electric Violet (#A51EE5)
    final rightGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFC76F97), // Rose Orchid
        Color(0xFFA51EE5), // Electric Violet / Magenta
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

    // 3. BOTTOM BASE FACET: Deep Dimensional Prism Shadow / Glow
    final bottomGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x9950156E), // Deep Violet
        Color(0x33000000), // Shadow
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final paintBottom = Paint()
      ..shader = bottomGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bottomPath = Path();
    bottomPath.moveTo(bottomLeft.dx, bottomLeft.dy);
    bottomPath.lineTo(bottomRight.dx, bottomRight.dy);
    bottomPath.lineTo(centerPoint.dx, centerPoint.dy);
    bottomPath.close();
    canvas.drawPath(bottomPath, paintBottom);

    // 4. CRISP WHITE CENTER REFRACTION LINE (Prism Ridge)
    final paintWhiteSpine = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(apex.dx, apex.dy + h * 0.02),
      centerPoint,
      paintWhiteSpine,
    );

    // Subtle edge glow on outer triangle
    final paintEdge = Paint()
      ..color = const Color(0x40FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;

    final outerPath = Path();
    outerPath.moveTo(apex.dx, apex.dy);
    outerPath.lineTo(bottomLeft.dx, bottomLeft.dy);
    outerPath.lineTo(bottomRight.dx, bottomRight.dy);
    outerPath.close();
    canvas.drawPath(outerPath, paintEdge);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
