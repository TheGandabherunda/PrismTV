import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/widgets/prism_triangle_logo.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final digitMap = {
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad9: '9',
    };

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

          // 2. Main Auth Content Layout with TV Remote & Keyboard Handling
          FocusScope(
            autofocus: true,
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  final key = event.logicalKey;
                  // Handle physical keyboard or remote hardware digits if typed directly
                  if (digitMap.containsKey(key)) {
                    controller.appendNumber(digitMap[key]!);
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
                    controller.deleteNumber();
                    return KeyEventResult.handled;
                  }
                }
                // Let directional arrows traverse focus nodes smoothly!
                return KeyEventResult.ignored;
              },
              child: SafeArea(
                child: Center(
                  child: Builder(
                    builder: (context) {
                      final size = MediaQuery.of(context).size;
                      // Only handheld mobile phones in vertical portrait get single-column layout.
                      // Fire TV Stick, Android TV, Google TV, Web, and Desktop get widescreen layout!
                      final isMobile = size.width < 768 && size.width < size.height;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 40,
                          vertical: isMobile ? 20 : 28,
                        ),
                        child: Container(
                          constraints: BoxConstraints(maxWidth: isMobile ? 420 : 920),
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

                                    const SizedBox(width: 48),

                                    // Right Panel: Form Card with TV Remote Keypad
                                    Expanded(
                                      flex: 5,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _buildRightFormCard(),
                                      ),
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
        const PrismTriangleLogo(size: 64, hasGlow: true),
        const SizedBox(height: 22),
        const Text(
          'PrismTV',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Smart TV Live Broadcast Platform',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Sign in with your Jio mobile number to access all live TV channels, regional broadcasts, and real-time electronic program guides.',
          style: TextStyle(
            fontSize: 14.5,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.60),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.gamepad_rounded, size: 18, color: AppColors.primaryLight),
              SizedBox(width: 10),
              Text(
                'Navigate with Remote Arrows & Select button',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
            border: Border.all(color: AppColors.unfocusedBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 12),
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
                      _FocusableTextButton(
                        label: 'Change',
                        onTap: controller.changeNumber,
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
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // D-Pad Remote Navigable Symmetric Keypad (1-9, Clear, 0, ⌫)
                _buildTvKeypad(),

                const SizedBox(height: 14),

                // Action Button (Inactive until digits entered, "Request OTP" / "Verify OTP")
                _TvActionButton(
                  label: controller.isOtpSent.value ? 'Verify OTP' : 'Request OTP',
                  isEnabled: controller.isOtpSent.value
                      ? controller.otpCode.value.length == 6
                      : controller.phoneNumber.value.length == 10,
                  isLoading: controller.isLoading.value,
                  onTap: controller.isOtpSent.value ? controller.verifyOtp : controller.sendOtp,
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
                        _FocusableTextButton(
                          label: 'Resend Code',
                          onTap: controller.isLoading.value ? null : controller.sendOtp,
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
                      fontWeight: FontWeight.w500,
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
              _TvKeypadButton(
                label: '1',
                autofocus: true,
                onTap: () => controller.appendNumber('1'),
              ),
              const SizedBox(width: 8),
              _TvKeypadButton(
                label: '2',
                onTap: () => controller.appendNumber('2'),
              ),
              const SizedBox(width: 8),
              _TvKeypadButton(
                label: '3',
                onTap: () => controller.appendNumber('3'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TvKeypadButton(
                label: '4',
                onTap: () => controller.appendNumber('4'),
              ),
              const SizedBox(width: 8),
              _TvKeypadButton(
                label: '5',
                onTap: () => controller.appendNumber('5'),
              ),
              const SizedBox(width: 8),
              _TvKeypadButton(
                label: '6',
                onTap: () => controller.appendNumber('6'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TvKeypadButton(
                label: '7',
                onTap: () => controller.appendNumber('7'),
              ),
              const SizedBox(width: 8),
              _TvKeypadButton(
                label: '8',
                onTap: () => controller.appendNumber('8'),
              ),
              const SizedBox(width: 8),
              _TvKeypadButton(
                label: '9',
                onTap: () => controller.appendNumber('9'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TvKeypadButton(
                label: 'Clear',
                isAction: true,
                onTap: controller.clearInput,
              ),
              const SizedBox(width: 8),
              _TvKeypadButton(
                label: '0',
                onTap: () => controller.appendNumber('0'),
              ),
              const SizedBox(width: 8),
              _TvKeypadButton(
                label: '⌫',
                isAction: true,
                onTap: controller.deleteNumber,
              ),
            ],
          ),
        ],
    );
  }
}

/// Robust, Remote D-Pad Focusable Keypad Button for Fire TV / Android TV
class _TvKeypadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool autofocus;
  final bool isAction;

  const _TvKeypadButton({
    required this.label,
    required this.onTap,
    this.autofocus = false,
    this.isAction = false,
  });

  @override
  State<_TvKeypadButton> createState() => _TvKeypadButtonState();
}

class _TvKeypadButtonState extends State<_TvKeypadButton> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (focused) {
          if (mounted) setState(() => _hasFocus = focused);
        },
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Handle Fire TV Remote Center / Select button, Enter, Gamepad A, and Accept
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                event.logicalKey == LogicalKeyboardKey.gameButtonSelect ||
                event.logicalKey == LogicalKeyboardKey.accept) {
              widget.onTap();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hasFocus ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 48,
              decoration: BoxDecoration(
                color: _hasFocus
                    ? (widget.isAction
                        ? AppColors.secondary.withValues(alpha: 0.35)
                        : AppColors.primaryLight.withValues(alpha: 0.30))
                    : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hasFocus
                      ? (widget.isAction ? AppColors.secondary : AppColors.primaryLight)
                      : Colors.white.withValues(alpha: 0.12),
                  width: _hasFocus ? 2.5 : 1.0,
                ),
                boxShadow: _hasFocus
                    ? [
                        BoxShadow(
                          color: (widget.isAction ? AppColors.secondaryGlow : AppColors.primaryGlow)
                              .withValues(alpha: 0.65),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.label.length > 2 ? 13 : 18,
                  fontWeight: FontWeight.bold,
                  color: _hasFocus
                      ? Colors.white
                      : (widget.isAction ? Colors.white70 : Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Remote D-Pad Focusable Action Button (Request OTP / Verify OTP)
class _TvActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isEnabled;

  const _TvActionButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.isEnabled = false,
  });

  @override
  State<_TvActionButton> createState() => _TvActionButtonState();
}

class _TvActionButtonState extends State<_TvActionButton> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        if (mounted) setState(() => _hasFocus = focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA ||
              event.logicalKey == LogicalKeyboardKey.gameButtonSelect ||
              event.logicalKey == LogicalKeyboardKey.accept) {
            if (widget.isEnabled && !widget.isLoading && widget.onTap != null) {
              widget.onTap!();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: (widget.isEnabled && !widget.isLoading) ? widget.onTap : null,
        child: AnimatedScale(
          scale: _hasFocus ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: widget.isEnabled ? AppColors.activeTabGradient : null,
              color: widget.isEnabled ? null : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasFocus
                    ? Colors.white
                    : (widget.isEnabled ? Colors.transparent : Colors.white.withValues(alpha: 0.08)),
                width: _hasFocus ? 2.5 : 1,
              ),
              boxShadow: _hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.primaryGlow.withValues(alpha: 0.65),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : (widget.isEnabled
                      ? [
                          BoxShadow(
                            color: AppColors.secondaryGlow.withValues(alpha: 0.40),
                            blurRadius: 14,
                          ),
                        ]
                      : null),
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isEnabled ? Colors.white : Colors.white38,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Remote D-Pad Focusable Text Button for Change / Resend Code
class _FocusableTextButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _FocusableTextButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_FocusableTextButton> createState() => _FocusableTextButtonState();
}

class _FocusableTextButtonState extends State<_FocusableTextButton> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) {
        if (mounted) setState(() => _hasFocus = f);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA ||
              event.logicalKey == LogicalKeyboardKey.gameButtonSelect ||
              event.logicalKey == LogicalKeyboardKey.accept) {
            if (widget.onTap != null) {
              widget.onTap!();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hasFocus ? AppColors.primaryLight.withValues(alpha: 0.20) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hasFocus ? AppColors.primaryLight : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _hasFocus ? Colors.white : AppColors.primaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
