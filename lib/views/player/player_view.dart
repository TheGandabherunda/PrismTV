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

    return Scaffold(
      backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: controller.handleKeyEvent,
          child: Listener(
            onPointerHover: (_) => controller.onUserInteraction(),
            onPointerMove: (_) => controller.onUserInteraction(),
            onPointerDown: (_) => controller.onUserInteraction(),
            child: Obx(
              () => MouseRegion(
                cursor: controller.showOsd.value ? SystemMouseCursors.basic : SystemMouseCursors.none,
                onHover: (_) => controller.onUserInteraction(),
                child: GestureDetector(
                  onTap: () => controller.handleSurfaceTap(),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.unfocusedBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Connecting to ${controller.currentChannel.channelName}...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ),

                    // Stream Error Toast
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Obx(() {
                          if (controller.streamError.value.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                controller.streamError.value,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
