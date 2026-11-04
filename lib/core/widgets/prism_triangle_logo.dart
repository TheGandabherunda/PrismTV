import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable PrismTV Triangle App Logo
/// Inspired by the dynamic faceted prism triangle / delta play symbol.
/// Features smooth rounded corners and the signature Sunset Coral -> Orchid -> Electric Violet gradient.
class PrismTriangleLogo extends StatelessWidget {
  final double size;
  final bool hasGlow;
  final bool showBackgroundTile;

  const PrismTriangleLogo({
    super.key,
    this.size = 40,
    this.hasGlow = true,
    this.showBackgroundTile = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = CustomPaint(
      size: Size(size, size),
      painter: _PrismTrianglePainter(),
    );

    if (hasGlow) {
      logo = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGlow,
              blurRadius: size * 0.45,
              spreadRadius: 1,
            ),
          ],
        ),
        child: logo,
      );
    }

    if (showBackgroundTile) {
      return Container(
        width: size * 1.35,
        height: size * 1.35,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(size * 0.35),
          border: Border.all(color: AppColors.unfocusedBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0x99000000),
              blurRadius: size * 0.3,
            ),
          ],
        ),
        child: Center(child: logo),
      );
    }

    return logo;
  }
}

class _PrismTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gradient Shader: Sunset Coral -> Orchid Rose -> Electric Violet
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF28B6E), // Warm Sunset Coral / Peach
        Color(0xFFC76F97), // Rose Orchid
        Color(0xFFA51EE5), // Electric Violet / Magenta
      ],
      stops: [0.0, 0.48, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Dark facet gradient for dimensional refraction depth
    final darkFacetGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x33000000),
        Color(0x77000000),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final paintMain = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Define rounded right-pointing triangle path
    // Point 1 (Top Left), Point 2 (Right tip), Point 3 (Bottom Left)
    final p1 = Offset(w * 0.22, h * 0.16);
    final p2 = Offset(w * 0.88, h * 0.50);
    final p3 = Offset(w * 0.22, h * 0.84);

    final path = Path();
    const cornerRadius = 0.12;

    // Start near top left
    path.moveTo(p1.dx, p1.dy + h * cornerRadius);
    path.quadraticBezierTo(p1.dx, p1.dy, p1.dx + w * cornerRadius, p1.dy + h * (cornerRadius * 0.5));
    // Line to right tip
    path.lineTo(p2.dx - w * cornerRadius * 1.2, p2.dy - h * cornerRadius * 0.7);
    path.quadraticBezierTo(p2.dx, p2.dy, p2.dx - w * cornerRadius * 1.2, p2.dy + h * cornerRadius * 0.7);
    // Line to bottom left
    path.lineTo(p3.dx + w * cornerRadius, p3.dy - h * (cornerRadius * 0.5));
    path.quadraticBezierTo(p3.dx, p3.dy, p3.dx, p3.dy - h * cornerRadius);
    // Line back to top left
    path.close();

    // Draw main radiant gradient triangle
    canvas.drawPath(path, paintMain);

    // Draw faceted lower refraction wing for modern 3D prism depth
    final facetPath = Path();
    facetPath.moveTo(p1.dx, p1.dy + (p3.dy - p1.dy) * 0.52);
    facetPath.lineTo(p2.dx - w * cornerRadius * 1.2, p2.dy);
    facetPath.lineTo(p3.dx + w * cornerRadius, p3.dy - h * (cornerRadius * 0.5));
    facetPath.quadraticBezierTo(p3.dx, p3.dy, p3.dx, p3.dy - h * cornerRadius);
    facetPath.close();

    final paintFacet = Paint()
      ..shader = darkFacetGradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(facetPath, paintFacet);

    // Subtle edge highlight gleam
    final paintGleam = Paint()
      ..color = const Color(0x40FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    final gleamPath = Path();
    gleamPath.moveTo(p1.dx + w * 0.08, p1.dy + h * 0.05);
    gleamPath.lineTo(p2.dx - w * 0.22, p2.dy - h * 0.10);

    canvas.drawPath(gleamPath, paintGleam);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

