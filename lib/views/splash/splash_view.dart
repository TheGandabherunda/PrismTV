import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/prism_triangle_logo.dart';
import 'splash_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final SplashController _controller;

  late final AnimationController _introController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  late final AnimationController _shimmerController;
  late final AnimationController _shimmerFadeController;
  late final Animation<double> _shimmerOpacityAnimation;

  late final AnimationController _starController;
  late final Animation<double> _starScaleAnimation;
  late final Animation<double> _starOpacityAnimation;
  late final Animation<double> _starRotationAnimation;

  Worker? _readyWorker;
  bool _hasTriggeredEndSequence = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SplashController>();

    // 1. Intro Animation: gentle scale and fade-in
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOut),
    );

    // 2. Perimeter Shimmer Controller: loops continuously while loading
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Fade out controller for shimmer when loading finishes
    _shimmerFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _shimmerOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _shimmerFadeController, curve: Curves.easeOut),
    );

    // 3. Shine Star Controller: blooms, rotates, stops, then lands to home
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // Scale expands with playful overshoot from 0 to 55%, then holds steady
    _starScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45,
      ),
    ]).animate(_starController);

    // Opacity fades in quickly
    _starOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 65,
      ),
    ]).animate(_starController);

    // Rotation: rotates ~38 degrees during the first 55%, then STOPS completely
    _starRotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.15, end: 0.65).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.65), // ROTATION STOPS & HOLDS
        weight: 45,
      ),
    ]).animate(_starController);

    // When star finishes holding its shine, navigate to home screen
    _starController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.onStarShineCompleted();
      }
    });

    // Start intro
    _introController.forward();

    // Listen to controller.isReady
    _readyWorker = ever<bool>(_controller.isReady, (ready) {
      if (ready && !_hasTriggeredEndSequence && mounted) {
        _startEndSequence();
      }
    });

    // Fallback if already ready
    if (_controller.isReady.value && !_hasTriggeredEndSequence) {
      _startEndSequence();
    }
  }

  Future<void> _startEndSequence() async {
    _hasTriggeredEndSequence = true;

    // 1. Shimmer loop ends and cleanly fades away
    await _shimmerFadeController.forward();
    _shimmerController.stop();

    // Subtle pause between shimmer ending and star appearing
    await Future.delayed(const Duration(milliseconds: 90));

    // 2. Star appears, rotates, stops, and then lands to home screen
    if (mounted) {
      _starController.forward();
    }
  }

  @override
  void dispose() {
    _readyWorker?.dispose();
    _introController.dispose();
    _shimmerController.dispose();
    _shimmerFadeController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double logoSize = 104.0;
    const double containerSize = 140.0;
    const double shimmerSize = 120.0;
    const double borderRadius = 26.0;
    const double starSize = 76.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _introController,
            _shimmerController,
            _shimmerFadeController,
            _starController,
          ]),
          builder: (context, _) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SizedBox(
                  width: containerSize,
                  height: containerSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Ambient Background Glow Aura behind the logo
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.9,
                              colors: [
                                AppColors.primaryGlow.withValues(alpha: 0.35),
                                AppColors.secondaryGlow.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // 2. Perimeter Shimmer running around the logo (fades out when loading finishes)
                      if (_shimmerOpacityAnimation.value > 0.001)
                        Opacity(
                          opacity: _shimmerOpacityAnimation.value,
                          child: CustomPaint(
                            size: const Size(shimmerSize, shimmerSize),
                            painter: _LogoPerimeterShimmerPainter(
                              progress: _shimmerController.value,
                              borderRadius: borderRadius,
                            ),
                          ),
                        ),

                      // 3. Center PrismTV Logo Emblem
                      const PrismTriangleLogo(
                        size: logoSize,
                        hasGlow: true,
                      ),

                      // 4. Sparkling Noticeable Shine Star on Top-Right Corner of Logo
                      // Appears after shimmer ends, rotates, stops, and lands to home screen
                      Positioned(
                        top: -12,
                        right: -12,
                        child: CustomPaint(
                          size: const Size(starSize, starSize),
                          painter: _ShineStarPainter(
                            scale: _starScaleAnimation.value,
                            opacity: _starOpacityAnimation.value,
                            rotation: _starRotationAnimation.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Perimeter Shimmer Running Continuously Around Logo Boundary
class _LogoPerimeterShimmerPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double borderRadius;

  _LogoPerimeterShimmerPainter({
    required this.progress,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Subtle perimeter baseline track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, trackPaint);

    // 2. Rotating shimmer sweep gradient
    final angle = progress * 2 * math.pi;
    final sweepShader = SweepGradient(
      transform: GradientRotation(angle),
      colors: const [
        Colors.transparent,
        Color(0x00A839C7),
        Color(0x25CB907D),
        Color(0x88A839C7), // Electric Violet
        Color(0xFFCB907D), // Terracotta
        Color(0xFFFFFFFF), // Pure White Peak
        Color(0xFFCB907D), // Terracotta
        Color(0x88A839C7), // Electric Violet
        Color(0x25CB907D),
        Colors.transparent,
      ],
      stops: const [
        0.0,
        0.55,
        0.70,
        0.82,
        0.90,
        0.94,
        0.97,
        0.985,
        0.995,
        1.0,
      ],
    ).createShader(rect);

    // 3. Ambient blur halo
    final glowPaint = Paint()
      ..shader = sweepShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(rrect, glowPaint);

    // 4. Sharp traveling beam
    final beamPaint = Paint()
      ..shader = sweepShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(rrect, beamPaint);
  }

  @override
  bool shouldRepaint(_LogoPerimeterShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Luminous Sparkling Noticeable Shine Star Painter with Primary, Secondary & Micro Flares
class _ShineStarPainter extends CustomPainter {
  final double scale;
  final double opacity;
  final double rotation;

  _ShineStarPainter({
    required this.scale,
    required this.opacity,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scale <= 0.001 || opacity <= 0.001) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width * 0.48) * scale;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // 1. Large Luminous Radial Flare Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: (0.95 * opacity).clamp(0.0, 1.0)),
          const Color(0xFFFFF2D0).withValues(alpha: (0.80 * opacity).clamp(0.0, 1.0)),
          const Color(0xFFFFB070).withValues(alpha: (0.50 * opacity).clamp(0.0, 1.0)),
          const Color(0xFFA839C7).withValues(alpha: (0.28 * opacity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.20, 0.48, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius * 1.35))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset.zero, radius * 1.35, glowPaint);

    // 2. Primary 4-Point Diamond Flare (Needle Beams)
    _drawDiamondRay(
      canvas,
      length: radius,
      thickness: radius * 0.16,
      color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
    );

    // 3. Secondary 4-Point Diagonal Flare (45-degree rays, golden-coral)
    canvas.save();
    canvas.rotate(math.pi / 4);
    _drawDiamondRay(
      canvas,
      length: radius * 0.58,
      thickness: radius * 0.11,
      color: const Color(0xFFFFF0D0).withValues(alpha: opacity.clamp(0.0, 1.0)),
    );
    canvas.restore();

    // 4. Subtle Tertiary 8-Point Tiny Micro-Flares for extra sparkle
    canvas.save();
    canvas.rotate(math.pi / 8);
    _drawDiamondRay(
      canvas,
      length: radius * 0.32,
      thickness: radius * 0.08,
      color: const Color(0xFFFFD4A0).withValues(alpha: (opacity * 0.75).clamp(0.0, 1.0)),
    );
    canvas.restore();

    // 5. Brilliant Intense White Center Core Dot
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.20, corePaint);

    // Center pinpoint spark
    final pinPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.09, pinPaint);

    canvas.restore();
  }

  void _drawDiamondRay(
    Canvas canvas, {
    required double length,
    required double thickness,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    // Top
    path.moveTo(0, -length);
    path.quadraticBezierTo(0, 0, thickness, 0);
    // Right
    path.quadraticBezierTo(0, 0, length, 0);
    path.quadraticBezierTo(0, 0, 0, thickness);
    // Bottom
    path.quadraticBezierTo(0, 0, 0, length);
    path.quadraticBezierTo(0, 0, -thickness, 0);
    // Left
    path.quadraticBezierTo(0, 0, -length, 0);
    path.quadraticBezierTo(0, 0, 0, -thickness);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShineStarPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.opacity != opacity ||
        oldDelegate.rotation != rotation;
  }
}
