import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import 'player_controller.dart';
import 'widgets/osd_overlay.dart';
import 'widgets/quick_channel_guide.dart';

class PlayerView extends GetView<PlayerController> {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: controller.handleKeyEvent,
        child: GestureDetector(
          onTap: () => controller.toggleOsd(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Player Surface
              Center(
                child: Obx(() {
                  if (controller.isPlayerInitialized.value &&
                      controller.videoPlayerController != null) {
                    return AspectRatio(
                      aspectRatio: controller.videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(controller.videoPlayerController!),
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
                          color: AppColors.accent.withValues(alpha: 0.9),
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

              // OSD Overlay
              Obx(() {
                if (controller.showOsd.value) {
                  return OsdOverlay(controller: controller);
                }
                return const SizedBox.shrink();
              }),

              // Quick Channel Drawer (Left Slide-in)
              Obx(() {
                if (controller.showQuickGuide.value) {
                  return Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    child: QuickChannelGuide(
                      channels: controller.channelList,
                      activeChannel: controller.currentChannel,
                      onSelect: controller.switchChannel,
                      onClose: controller.toggleQuickGuide,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}

