import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/widgets/prism_triangle_logo.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Root Ambient Atmosphere Mesh (Matching Homescreen palette)
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Upper-Left Ambient Glow Pool
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.60, -0.45),
                          radius: 1.15,
                          colors: [
                            AppColors.primaryGlow.withValues(alpha: 0.28),
                            AppColors.primaryGlow.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.40, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Lower-Right Ambient Glow Pool
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.55, 0.50),
                          radius: 1.20,
                          colors: [
                            AppColors.secondaryGlow.withValues(alpha: 0.25),
                            AppColors.secondaryGlow.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Edge Vignette for deep contrast
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.45,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF09080C).withValues(alpha: 0.70),
                          ],
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Auth Content Layout
          Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              controller.handleKeyEvent(event);
              return KeyEventResult.ignored;
            },
            child: SafeArea(
              child: Center(
                child: Builder(
                  builder: (context) {
                    final isMobile = MediaQuery.of(context).size.width < 768;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 40,
                        vertical: isMobile ? 20 : 24,
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: isMobile
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildMobileBrandHeader(),
                                  const SizedBox(height: 24),
                                  _buildRightFormCard(),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left Panel: Brand & Info
                                  Expanded(
                                    flex: 5,
                                    child: _buildLeftBrandPanel(),
                                  ),

                                  const SizedBox(width: 44),

                                  // Right Panel: Form Card with Compact Symmetric Number Pad
                                  Center(
                                    child: _buildRightFormCard(),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBrandHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const PrismTriangleLogo(size: 44, hasGlow: true),
        const SizedBox(height: 12),
        const Text(
          'PrismTV',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Smart Live Broadcast Platform',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftBrandPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PrismTriangleLogo(size: 60, hasGlow: true),
        const SizedBox(height: 20),
        const Text(
          'PrismTV',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Smart TV Live Broadcast Platform',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Sign in with your Jio mobile number to access all live TV channels, regional broadcasts, and real-time electronic program guides.',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.60),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: const [
            Icon(Icons.keyboard_rounded, size: 16, color: AppColors.primaryLight),
            SizedBox(width: 8),
            Text(
              'Use TV remote keypad or physical keyboard',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 348),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
            border: Border.all(color: AppColors.unfocusedBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Title with Change button when in OTP step)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.isOtpSent.value ? 'Enter 6-Digit OTP' : 'Enter Jio Mobile Number',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (controller.isOtpSent.value)
                      InkWell(
                        onTap: controller.changeNumber,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Display Box (Reactively updates with controller.phoneNumber / otpCode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryLight, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      if (!controller.isOtpSent.value)
                        const Text(
                          '+91  ',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          controller.isOtpSent.value
                              ? (controller.otpCode.value.isEmpty
                                  ? '------'
                                  : controller.otpCode.value.padRight(6, '-'))
                              : (controller.phoneNumber.value.isEmpty
                                  ? 'XXXXXXXXXX'
                                  : controller.phoneNumber.value),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            color: (controller.isOtpSent.value
                                    ? controller.otpCode.value.isNotEmpty
                                    : controller.phoneNumber.value.isNotEmpty)
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (!controller.isOtpSent.value && controller.phoneNumber.value.isNotEmpty)
                        InkWell(
                          onTap: controller.clearInput,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Compact Symmetric TV Keypad with Material Tap Effect (0-9, Clear, Delete)
                _buildTvKeypad(),

                const SizedBox(height: 14),

                // Action Button (Inactive until 10 digits entered, "Request OTP")
                Focus(
                  child: Builder(
                    builder: (ctx) {
                      final hasFocus = Focus.of(ctx).hasFocus;
                      final isOtp = controller.isOtpSent.value;
                      final canSubmit = isOtp
                          ? controller.otpCode.value.length == 6
                          : controller.phoneNumber.value.length == 10;

                      return InkWell(
                        onTap: (controller.isLoading.value || !canSubmit)
                            ? null
                            : (isOtp
                                ? controller.verifyOtp
                                : controller.sendOtp),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: canSubmit ? AppColors.activeTabGradient : null,
                            color: canSubmit ? null : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasFocus
                                  ? Colors.white
                                  : (canSubmit ? Colors.transparent : Colors.white.withValues(alpha: 0.08)),
                              width: hasFocus ? 2 : 1,
                            ),
                            boxShadow: canSubmit
                                ? [
                                    BoxShadow(
                                      color: hasFocus ? AppColors.primaryGlow : AppColors.secondaryGlow,
                                      blurRadius: hasFocus ? 18 : 12,
                                      spreadRadius: hasFocus ? 2 : 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isOtp
                                        ? 'Verify OTP'
                                        : 'Request OTP',
                                    style: TextStyle(
                                      color: canSubmit ? Colors.white : Colors.white38,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Resend Countdown Row (when in OTP step)
                if (controller.isOtpSent.value) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.resendCountdown.value > 0
                            ? 'Resend OTP in ${controller.resendCountdown.value}s'
                            : "Didn't receive code? ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.50),
                        ),
                      ),
                      if (controller.resendCountdown.value == 0)
                        InkWell(
                          onTap: controller.isLoading.value ? null : controller.sendOtp,
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'Resend Code',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                // Feedback status message
                if (controller.statusMessage.value.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    controller.statusMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: controller.isError.value ? AppColors.secondary : AppColors.primaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTvKeypad() {
    return Column(
      children: [
        Row(
          children: [
            _keypadBtn('1'),
            const SizedBox(width: 8),
            _keypadBtn('2'),
            const SizedBox(width: 8),
            _keypadBtn('3'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _keypadBtn('4'),
            const SizedBox(width: 8),
            _keypadBtn('5'),
            const SizedBox(width: 8),
            _keypadBtn('6'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _keypadBtn('7'),
            const SizedBox(width: 8),
            _keypadBtn('8'),
            const SizedBox(width: 8),
            _keypadBtn('9'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _keypadActionBtn('Clear', () => controller.clearInput()),
            const SizedBox(width: 8),
            _keypadBtn('0'),
            const SizedBox(width: 8),
            _keypadActionBtn('⌫', () => controller.deleteNumber()),
          ],
        ),
      ],
    );
  }

  Widget _keypadBtn(String label) {
    return Expanded(
      child: Focus(
        child: Builder(
          builder: (ctx) {
            final hasFocus = Focus.of(ctx).hasFocus;
            return Material(
              color: hasFocus ? AppColors.focusedBackground : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => controller.appendNumber(label),
                borderRadius: BorderRadius.circular(10),
                splashColor: AppColors.primaryLight.withValues(alpha: 0.30),
                highlightColor: Colors.white.withValues(alpha: 0.10),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasFocus ? AppColors.primary : AppColors.unfocusedBorder,
                      width: hasFocus ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: hasFocus ? AppColors.primaryLight : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _keypadActionBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: Focus(
        child: Builder(
          builder: (ctx) {
            final hasFocus = Focus.of(ctx).hasFocus;
            return Material(
              color: hasFocus ? AppColors.focusedBackground : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                splashColor: AppColors.secondary.withValues(alpha: 0.30),
                highlightColor: Colors.white.withValues(alpha: 0.10),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasFocus ? AppColors.secondary : AppColors.unfocusedBorder,
                      width: hasFocus ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasFocus ? AppColors.secondary : AppColors.textSecondary,
                    ),
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
