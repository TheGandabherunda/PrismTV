import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/quality_bridge.dart';
import '../../../core/widgets/prism_triangle_logo.dart';
import '../player_controller.dart';

/// Floating Miniplayer (YouTube Style)
/// Floats in the bottom-right corner of the Home screen when minimized
class FloatingMiniplayer extends StatelessWidget {
  const FloatingMiniplayer({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PlayerController>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Obx(() {
      if (!pc.isMinimized.value ||
          !pc.isPlayerInitialized.value ||
          pc.videoPlayerController == null) {
        return const SizedBox.shrink();
      }

      // Using Align + Padding ensures proper layout without ParentDataWidget errors
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: isMobile ? 16 : 24,
            right: isMobile ? 16 : 24,
          ),
          child: _MiniplayerCard(controller: pc),
        ),
      );
    });
  }
}

class _MiniplayerCard extends StatefulWidget {
  final PlayerController controller;

  const _MiniplayerCard({required this.controller});

  @override
  State<_MiniplayerCard> createState() => _MiniplayerCardState();
}

class _MiniplayerCardState extends State<_MiniplayerCard> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _ensurePlaying();
  }

  @override
  void didUpdateWidget(covariant _MiniplayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensurePlaying();
  }

  void _ensurePlaying() {
    void attemptPlay() {
      if (!mounted) return;
      final vpc = widget.controller.videoPlayerController;
      if (vpc != null) {
        vpc.play();
      }
      if (kIsWeb) {
        webResumeVideo();
      }
    }

    attemptPlay();
    WidgetsBinding.instance.addPostFrameCallback((_) => attemptPlay());
    Future.delayed(const Duration(milliseconds: 100), attemptPlay);
    Future.delayed(const Duration(milliseconds: 300), attemptPlay);
    Future.delayed(const Duration(milliseconds: 600), attemptPlay);
    Future.delayed(const Duration(milliseconds: 1000), attemptPlay);
  }

  @override
  Widget build(BuildContext context) {
    final pc = widget.controller;
    final ch = pc.currentChannel;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final playerWidth = isMobile ? (screenWidth * 0.58).clamp(180.0, 240.0) : 320.0;
    final playerHeight = isMobile ? (playerWidth * 9 / 16) : 180.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: pc.expandPlayer,
        child: Container(
          width: playerWidth,
          height: playerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF161210),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xCC000000),
                blurRadius: 24,
                spreadRadius: 2,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Live Video Surface
                Positioned.fill(
                  child: Obx(() {
                    final vpc = pc.videoPlayerController;
                    if (vpc == null || !pc.isPlayerInitialized.value) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      );
                    }

                    final ratio = vpc.value.aspectRatio;
                    final effectiveRatio = ratio > 0.0 ? ratio : (16 / 9);

                    return Center(
                      child: AspectRatio(
                        aspectRatio: effectiveRatio,
                        child: VideoPlayer(
                          vpc,
                          key: const ValueKey('miniplayer_video'),
                        ),
                      ),
                    );
                  }),
                ),

                // 2. Buffering Spinner
                Center(
                  child: Obx(() {
                    if (pc.isBuffering.value) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ),

                // 3. Top Header Scrim with Channel Info & Window Action Buttons
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.85,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xCC000000),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Channel Logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              ch.fullLogoUrl,
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const PrismTriangleLogo(size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Channel Name
                          Expanded(
                            child: Text(
                              ch.channelName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),

                          // Expand Button (Returns to full player)
                          _MiniActionBtn(
                            icon: Icons.open_in_full_rounded,
                            tooltip: 'Expand to Full Player',
                            onTap: pc.expandPlayer,
                          ),
                          const SizedBox(width: 4),

                          // Close Button (Stops playback)
                          _MiniActionBtn(
                            icon: Icons.close_rounded,
                            tooltip: 'Close Miniplayer',
                            onTap: pc.closeMiniplayer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Center Hover Play / Pause Overlay
                if (_isHovered)
                  Center(
                    child: InkWell(
                      onTap: pc.togglePlayPause,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.65),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Obx(
                          () => Icon(
                            pc.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 5. Bottom Scrubber Bar (YouTube Red)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    color: const Color(0xFFFF0000),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
