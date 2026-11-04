import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../player_controller.dart';

class OsdOverlay extends StatelessWidget {
  final PlayerController controller;

  const OsdOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final channel = controller.currentChannel;
    final program = controller.currentProgram.value;
    final currentTime = DateFormat('hh:mm a').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xE6000000),
            Colors.transparent,
            Color(0xE6000000),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top OSD Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Focus(
                    child: Builder(
                      builder: (ctx) {
                        final hasFocus = Focus.of(ctx).hasFocus;
                        return InkWell(
                          onTap: () => Get.back(),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: hasFocus ? AppColors.focusedBackground : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasFocus ? AppColors.primary : AppColors.unfocusedBorder,
                              ),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    channel.channelName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  if (channel.isHd)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppColors.hdBadgeGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              // Live Status & Clock
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: AppColors.accent, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'LIVE STREAM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    currentTime,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Center Controls Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Focus(
                child: Builder(
                  builder: (ctx) {
                    final hasFocus = Focus.of(ctx).hasFocus;
                    return InkWell(
                      onTap: () => controller.previousChannel(),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasFocus ? AppColors.focusedBackground : AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasFocus ? AppColors.primary : AppColors.unfocusedBorder,
                          ),
                        ),
                        child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              Focus(
                child: Builder(
                  builder: (ctx) {
                    final hasFocus = Focus.of(ctx).hasFocus;
                    return InkWell(
                      onTap: () => controller.togglePlayPause(),
                      borderRadius: BorderRadius.circular(36),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.activeTabGradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasFocus ? Colors.white : Colors.transparent,
                            width: hasFocus ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: hasFocus ? AppColors.primaryGlow : AppColors.secondaryGlow,
                              blurRadius: hasFocus ? 20 : 12,
                            ),
                          ],
                        ),
                        child: Obx(
                          () => Icon(
                            controller.isPlaying.value
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              Focus(
                child: Builder(
                  builder: (ctx) {
                    final hasFocus = Focus.of(ctx).hasFocus;
                    return InkWell(
                      onTap: () => controller.nextChannel(),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasFocus ? AppColors.focusedBackground : AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasFocus ? AppColors.primary : AppColors.unfocusedBorder,
                          ),
                        ),
                        child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Bottom EPG Info & Remote Hints
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.unfocusedBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      program?.showName ?? 'Live Broadcast',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${channel.categoryName} • ${channel.languageName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: program?.progress ?? 0.4,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        program?.description ?? 'Now streaming on PrismTV live network.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    // TV Remote Hints
                    const Row(
                      children: [
                        Text(
                          '▲/▼ Channel  •  ◀ Quick Guide  •  [OK] Play/Pause',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

