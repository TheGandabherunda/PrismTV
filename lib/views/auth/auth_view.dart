import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.tvMarginHorizontal,
            vertical: AppDimens.tvMarginVertical,
          ),
          child: Row(
            children: [
              // Left Panel: Brand & Info
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: AppColors.prismGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.live_tv_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'PRISM TV',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Smart TV Broadcast Platform',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Log in once with your registered mobile number to stream all live TV channels directly to your big screen.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Demo Mode Quick Button
                    Focus(
                      child: Builder(
                        builder: (ctx) {
                          final hasFocus = Focus.of(ctx).hasFocus;
                          return InkWell(
                            onTap: () => controller.continueAsDemo(),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: hasFocus ? AppColors.focusedBackground : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasFocus ? AppColors.primary : AppColors.unfocusedBorder,
                                  width: hasFocus ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_circle_outline_rounded,
                                    color: hasFocus ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Skip Login (Demo Mode)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: hasFocus ? AppColors.primary : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 48),

              // Right Panel: Input & Remote Keypad
              Expanded(
                flex: 6,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                      border: Border.all(color: AppColors.unfocusedBorder),
                    ),
                    child: Obx(
                      () => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            controller.isOtpSent.value ? 'Enter 6-Digit OTP' : 'Enter Jio Mobile Number',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Display Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryGlow, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                if (!controller.isOtpSent.value)
                                  const Text(
                                    '+91  ',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    controller.isOtpSent.value
                                        ? (controller.otpInput.text.isEmpty
                                            ? '------'
                                            : controller.otpInput.text.padRight(6, '-'))
                                        : (controller.phoneInput.text.isEmpty
                                            ? 'XXXXXXXXXX'
                                            : controller.phoneInput.text),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // TV Keypad (0-9, Del)
                          _buildTvKeypad(),

                          const SizedBox(height: 16),

                          // Action Button
                          Focus(
                            child: Builder(
                              builder: (ctx) {
                                final hasFocus = Focus.of(ctx).hasFocus;
                                return InkWell(
                                  onTap: controller.isLoading.value
                                      ? null
                                      : (controller.isOtpSent.value
                                          ? controller.verifyOtp
                                          : controller.sendOtp),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: hasFocus ? AppColors.prismGradient : null,
                                      color: hasFocus ? null : AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: hasFocus
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.5),
                                                blurRadius: 16,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: controller.isLoading.value
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              controller.isOtpSent.value
                                                  ? 'VERIFY & START STREAMING'
                                                  : 'REQUEST OTP',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          if (controller.statusMessage.value.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              controller.statusMessage.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: controller.isError.value ? AppColors.accent : AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
            _keypadActionBtn('Clear', () {
              if (!controller.isOtpSent.value) {
                controller.phoneInput.clear();
              } else {
                controller.otpInput.clear();
              }
            }),
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
            return InkWell(
              onTap: () => controller.appendNumber(label),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 48,
                decoration: BoxDecoration(
                  color: hasFocus ? AppColors.focusedBackground : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasFocus ? AppColors.primary : AppColors.unfocusedBorder,
                    width: hasFocus ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: hasFocus ? AppColors.primary : Colors.white,
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
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 48,
                decoration: BoxDecoration(
                  color: hasFocus ? AppColors.focusedBackground : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasFocus ? AppColors.accent : AppColors.unfocusedBorder,
                    width: hasFocus ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: hasFocus ? AppColors.accent : AppColors.textSecondary,
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

