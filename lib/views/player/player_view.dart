import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/quality_bridge.dart';
import 'player_controller.dart';
import 'widgets/osd_overlay.dart';

class PlayerView extends GetView<PlayerController> {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto-resume playback if paused during route switch or expanding from miniplayer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isPlayerInitialized.value &&
          controller.videoPlayerController != null) {
        controller.videoPlayerController?.play();
        if (kIsWeb) {
          webResumeVideo();
        }
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (controller.showQualityMenu.value) {
          controller.closeQualityMenu();
          return;
        }
        if (controller.showBottomChannelTray.value) {
          controller.closeBottomChannelTray();
          return;
        }
        if (controller.isFullscreen.value) {
          controller.toggleFullscreen();
          return;
        }
        controller.goBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: controller.handleKeyEvent,
          child: Listener(
            onPointerHover: (_) => controller.onUserInteraction(),
            child: Obx(
              () => MouseRegion(
                cursor: controller.showOsd.value ? SystemMouseCursors.basic : SystemMouseCursors.none,
                onHover: (_) => controller.onUserInteraction(),
                child: GestureDetector(
                  onTap: () => controller.handleSurfaceTap(),
                  onVerticalDragStart: (details) => controller.handleVerticalDragStart(details, context),
                  onVerticalDragUpdate: (details) => controller.handleVerticalDragUpdate(details, context),
                  onVerticalDragEnd: controller.handleVerticalDragEnd,
                  onVerticalDragCancel: controller.handleVerticalDragCancel,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video Player Surface
                      Center(
                        child: Obx(() {
                          if (!controller.isMinimized.value &&
                              controller.isPlayerInitialized.value &&
                              controller.videoPlayerController != null) {
                            final ratio = controller.videoPlayerController!.value.aspectRatio;
                            final effectiveRatio = ratio > 0.0 ? ratio : (16 / 9);
                            return AspectRatio(
                              aspectRatio: effectiveRatio,
                              child: VideoPlayer(
                                controller.videoPlayerController!,
                                key: const ValueKey('player_video'),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ),

                    // Buffering / Loading Indicator
                    Center(
                      child: Obx(() {
                        if (controller.isBuffering.value ||
                            !controller.isPlayerInitialized.value) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            constraints: const BoxConstraints(maxWidth: 380),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.unfocusedBorder),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x60000000),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Flexible(
                                  child: Text(
                                    controller.currentChannel.channelName.isNotEmpty
                                        ? 'Connecting to ${controller.currentChannel.channelName}...'
                                        : 'Connecting to channel...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ),

                    // Stream Error Overlay (Centered Card with Back / Browse Button)
                    Center(
                      child: Obx(() {
                        if (controller.streamError.value.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                            constraints: const BoxConstraints(maxWidth: 420),
                            decoration: BoxDecoration(
                              color: const Color(0xF0181524),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24, width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x60000000),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 38),
                                const SizedBox(height: 12),
                                Text(
                                  controller.currentChannel.channelName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  controller.streamError.value,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: controller.goBack,
                                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                      label: const Text('Back'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: controller.retryCurrentChannel,
                                      icon: const Icon(Icons.refresh_rounded, size: 16),
                                      label: const Text('Retry'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white30),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ),

                    // Quality / Action Toast Notification
                    Positioned(
                      top: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Obx(() {
                          if (controller.toastMessage.value.isNotEmpty) {
                            return AnimatedOpacity(
                              opacity: controller.toastMessage.value.isNotEmpty ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primaryLight, width: 1.2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.primaryGlow,
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryLight),
                                    const SizedBox(width: 8),
                                    Text(
                                      controller.toastMessage.value,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ),
                    ),

                    // OSD Overlay
                    Obx(() {
                      if (controller.showOsd.value) {
                        return OsdOverlay(controller: controller);
                      }
                      return const SizedBox.shrink();
                    }),

                    // Gesture HUD Indicators: Brightness (Left) and Volume (Right)
                    // Direct children of Stack: strictly anchored to left: 24 and right: 24
                    Positioned(
                      left: 24,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: Obx(() => _GestureHudIndicator(
                                isVisible: controller.showBrightnessHud.value,
                                isLeft: true,
                                value: controller.hudBrightness.value,
                              )),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 24,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: Obx(() => _GestureHudIndicator(
                                isVisible: controller.showVolumeHud.value,
                                isLeft: false,
                                value: controller.hudVolume.value,
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

/// Floating glassmorphic HUD pill displaying live Brightness or Volume percentage.
/// Matches PrismTV uniform 40px island pills: zero dropshadows, pure optical warm obsidian glass.
class _GestureHudIndicator extends StatelessWidget {
  final bool isVisible;
  final bool isLeft; // true = Brightness (left), false = Volume (right)
  final double value; // 0.0 to 1.0

  const _GestureHudIndicator({
    required this.isVisible,
    required this.isLeft,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    final IconData icon = isLeft
        ? (value < 0.35
            ? Icons.brightness_low_rounded
            : (value < 0.70 ? Icons.brightness_medium_rounded : Icons.brightness_high_rounded))
        : (value <= 0.01
            ? Icons.volume_off_rounded
            : (value < 0.50 ? Icons.volume_down_rounded : Icons.volume_up_rounded));

    final accentColor = isLeft ? AppColors.secondary : AppColors.primaryLight;
    final fillColor = isLeft ? AppColors.secondary : AppColors.primary;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: Container(
        width: 40,
        height: 148,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xE61C1613),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              size: 16,
              color: accentColor,
            ),
            // Flat progress capsule track matching uniform player slider aesthetics (zero drop shadows)
            Container(
              width: 4,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 4,
                height: (76 * value.clamp(0.0, 1.0)),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
