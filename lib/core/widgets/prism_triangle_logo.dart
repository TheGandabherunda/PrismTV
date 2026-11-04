import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable PrismTV Triangle App Logo
/// Faithfully matching our signature brand identity:
/// 1. Crisp Pure White squircle tile (#FFFFFF)
/// 2. Top-Right sharp Pitch Black facet (#0D0B0D)
/// 3. Left-to-Bottom radiant Sunset Coral -> Rose Orchid -> Electric Violet gradient wing
/// 4. High-contrast pure white separation channel
class PrismTriangleLogo extends StatelessWidget {
  final double size;
  final bool hasGlow;
  final bool showBackgroundTile;

  const PrismTriangleLogo({
    super.key,
    this.size = 40,
    this.hasGlow = true,
    this.showBackgroundTile = true,
  });

  @override
  Widget build(BuildContext context) {
    if (showBackgroundTile) {
      return Container(
        width: size * 1.25,
        height: size * 1.25,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            if (hasGlow) ...[
              // Soft warm ambient glow matching coral brand accent
              BoxShadow(
                color: const Color(0x40F28B6E),
                blurRadius: size * 0.4,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              // Subtle dark shadow for crisp depth on dark surfaces
              BoxShadow(
                color: const Color(0x30000000),
                blurRadius: size * 0.15,
                offset: const Offset(0, 2),
              ),
            ],
          ],
        ),
        child: Center(
          child: CustomPaint(
            size: Size(size * 0.72, size * 0.72),
            painter: const _PrismFacetedPainter(isTileWhite: true),
          ),
        ),
      );
    }

    Widget logo = CustomPaint(
      size: Size(size, size),
      painter: const _PrismFacetedPainter(isTileWhite: false),
    );

    if (hasGlow) {
      logo = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGlow,
              blurRadius: size * 0.4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: logo,
      );
    }

    return logo;
  }
}

class _PrismFacetedPainter extends CustomPainter {
  final bool isTileWhite;

  const _PrismFacetedPainter({required this.isTileWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. TOP-RIGHT FACET (Pitch Black on pure white tile, Crisp White on dark canvas)
    final topFacetColor = isTileWhite ? const Color(0xFF0D0B0D) : const Color(0xFFFFFFFF);
    final paintTopFacet = Paint()
      ..color = topFacetColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final topPath = Path();
    final p1 = Offset(w * 0.44, h * 0.16);
    final p2 = Offset(w * 0.90, h * 0.16);
    final p3 = Offset(w * 0.46, h * 0.52);

    topPath.moveTo(p1.dx, p1.dy);
    topPath.lineTo(p2.dx, p2.dy);
    topPath.lineTo(p3.dx, p3.dy);
    topPath.close();
    canvas.drawPath(topPath, paintTopFacet);

    // 2. LEFT & BOTTOM GRADIENT WING (Sunset Coral -> Rose Orchid -> Electric Violet)
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

    final paintWing = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final wingPath = Path();
    // Sweeping origami chevron / delta wing
    wingPath.moveTo(w * 0.14, h * 0.16);
    wingPath.lineTo(w * 0.32, h * 0.16);
    wingPath.lineTo(w * 0.35, h * 0.48);
    wingPath.lineTo(w * 0.88, h * 0.56);
    wingPath.lineTo(w * 0.46, h * 0.84);
    wingPath.lineTo(w * 0.18, h * 0.84);
    wingPath.lineTo(w * 0.12, h * 0.50);
    wingPath.close();

    canvas.drawPath(wingPath, paintWing);
  }

  @override
  bool shouldRepaint(covariant _PrismFacetedPainter oldDelegate) =>
      oldDelegate.isTileWhite != isTileWhite;
}
