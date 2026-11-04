import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/prism_triangle_logo.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Obx(
          () => AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            opacity: controller.logoOpacity.value,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              scale: controller.logoScale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prism TV Triangle Logo Emblem
                  const PrismTriangleLogo(
                    size: 78,
                    showBackgroundTile: true,
                    hasGlow: true,
                  ),
                  const SizedBox(height: 28),
                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.prismGradient.createShader(bounds),
                    child: const Text(
                      'PRISM TV',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'by TheGandabherunda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

