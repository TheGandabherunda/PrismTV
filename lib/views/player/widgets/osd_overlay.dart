import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/quality_option.dart';
import '../player_controller.dart';
import 'channel_carousel_tray.dart';

/// Pixel-Accurate YouTube Player OSD Overlay
/// Features 40px Uniform Island Pills, Fill Rounded Icons, Zero Dropshadows,
/// Settings Popover Opened Cleanly ABOVE the Progress Line.
class OsdOverlay extends StatelessWidget {
  final PlayerController controller;

  const OsdOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final channel = controller.currentChannel;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full OSD UI: Top Bar + Floating Scrubber + Uniform Island Pill Controls
        // (No full-screen masking: center of video remains 100% crystal clear and unmasked)
        SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ==========================================
              // TOP BAR: Back Arrow + Channel Name & Program Title
              // ==========================================
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x99000000),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Back Button (Uniform 40x40 Frosted Circle Pill, Fill Rounded Icon, No Dropshadow)
                        _PillButton(
                          onTap: controller.goBack,
                          tooltip: 'Back to Home',
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),

                        // Channel Title & Program (YouTube Style at Top-Left)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                channel.channelName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                                  ],
                                ),
                              ),
                              Obx(() {
                                final prog = controller.currentProgram.value;
                                final sub = prog != null
                                    ? prog.showName
                                    : '${channel.categoryName}${channel.languageName.isNotEmpty ? ' • ${channel.languageName}' : ''}';
                                if (sub.isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    sub,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.72),
                                      shadows: const [
                                        Shadow(color: Colors.black87, blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==========================================
              // BOTTOM SECTION: Scrubber + Uniform 40px Island Pills
              // ==========================================
              Obx(() {
                // If Channel Shelf Tray is open, hide the bottom pills so shelf occupies bottom
                if (controller.showBottomChannelTray.value) {
                  return const SizedBox.shrink();
                }

                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xB3000000),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Signature Brand Scrubber Line (Right above the pills)
                          Obx(() {
                            if (controller.isLiveStream.value) {
                              // Live Broadcast Stream Indicator
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // Background Track
                                    Container(
                                      height: 3.0,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(1.5),
                                      ),
                                    ),
                                    // Live Active Signature Gradient Track (Sunset Coral -> Electric Violet)
                                    FractionallySizedBox(
                                      widthFactor: 1.0,
                                      child: Container(
                                        height: 3.0,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFCB907D),
                                              Color(0xFFA839C7),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    ),
                                    // Live Thumb Dot at End (Primary Electric Violet)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFA839C7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // VOD Content Scrubber
                            final pos = controller.currentPosition.value.inMilliseconds.toDouble();
                            final dur = controller.totalDuration.value.inMilliseconds.toDouble();
                            final max = dur > 0 ? dur : 1.0;
                            final progress = (pos / max).clamp(0.0, 1.0);

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onHorizontalDragUpdate: (details) {
                                    final boxWidth = constraints.maxWidth;
                                    if (boxWidth > 0) {
                                      final frac = (details.localPosition.dx / boxWidth).clamp(0.0, 1.0);
                                      controller.seekToPosition(Duration(milliseconds: (frac * max).round()));
                                    }
                                  },
                                  onTapDown: (details) {
                                    final boxWidth = constraints.maxWidth;
                                    if (boxWidth > 0) {
                                      final frac = (details.localPosition.dx / boxWidth).clamp(0.0, 1.0);
                                      controller.seekToPosition(Duration(milliseconds: (frac * max).round()));
                                    }
                                  },
                                  child: Container(
                                    height: 14,
                                    alignment: Alignment.center,
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        // Inactive background track
                                        Container(
                                          height: 3.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.22),
                                            borderRadius: BorderRadius.circular(1.5),
                                          ),
                                        ),
                                        // Active signature gradient track (Coral -> Violet)
                                        FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            height: 3.0,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFCB907D),
                                                  Color(0xFFA839C7),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius: BorderRadius.circular(1.5),
                                            ),
                                          ),
                                        ),
                                        // Thumb circle
                                        Align(
                                          alignment: Alignment(progress * 2.0 - 1.0, 0.0),
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFA839C7),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }),

                          const SizedBox(height: 6),

                          // 2. Uniform 40px Island Pills Row (Zero Dropshadows, Fill Rounded Icons)
                          SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              alignment: Alignment.center,
                              children: [
                                // CENTER: Chevron Up (Pinned in exact dead center at 50%)
                                Align(
                                  alignment: Alignment.center,
                                  child: _PillButton(
                                    onTap: controller.toggleBottomChannelTray,
                                    tooltip: 'Channels',
                                    child: const Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                ),

                                // LEFT: Play/Pause, Volume, LIVE (Anchored Left)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Pill 1: Play/Pause (40x40 Circle, Fill Rounded)
                                      Obx(() => _PillButton(
                                            onTap: controller.togglePlayPause,
                                            tooltip: controller.isPlaying.value ? 'Pause (k)' : 'Play (k)',
                                            child: Icon(
                                              controller.isPlaying.value
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          )),
                                      const SizedBox(width: 8),

                                      // Pill 2: Volume (40px Height, 40px Width Collapsed, Center Slider)
                                      _VolumePill(controller: controller),
                                      const SizedBox(width: 8),

                                      // Pill 3: Time / LIVE Capsule Pill (Uniform 40px Height)
                                      _LiveTimePill(controller: controller),
                                    ],
                                  ),
                                ),

                                // RIGHT: Settings, PiP, Fullscreen (Anchored Right)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _RightCapsule(controller: controller),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // 2. Outside Tap Detector when Settings/Quality Menu is open (Dismisses menu on outside click)
        Obx(() {
          if (!controller.showQualityMenu.value) return const SizedBox.shrink();
          return Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.closeQualityMenu,
              child: const ColoredBox(color: Colors.transparent),
            ),
          );
        }),

        // 3. YouTube Floating Settings Menu Popover (Anchored Cleanly ABOVE the Progress Line)
        Obx(() {
          if (!controller.showQualityMenu.value) return const SizedBox.shrink();
          return Positioned(
            bottom: 84, // Floats cleanly ABOVE the progress scrubber line
            right: 18,
            child: _YouTubeSettingsMenu(controller: controller),
          );
        }),

        // 4. Outside Tap Detector when Bottom Channel Tray is open (Dismisses tray on outside click)
        Obx(() {
          if (!controller.showBottomChannelTray.value) return const SizedBox.shrink();
          return Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.closeBottomChannelTray,
              child: const ColoredBox(color: Colors.transparent),
            ),
          );
        }),

        // 5. YouTube Channels Shelf Tray (Slides up when center arrow is clicked)
        Obx(() {
          if (!controller.showBottomChannelTray.value) return const SizedBox.shrink();
          return Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ChannelCarouselTray(
              channels: controller.channelList,
              categorizedSections: controller.categorizedSections,
              activeChannel: controller.currentChannel,
              onSelect: controller.switchChannel,
              onClose: controller.closeBottomChannelTray,
            ),
          );
        }),
      ],
    );
  }
}

/// Standalone Circular Pill Button (Uniform 40x40, Flat Frosted Glass, No Dropshadow)
class _PillButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;

  const _PillButton({
    required this.child,
    required this.onTap,
    this.tooltip = '',
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.18)
                : const Color(0x99242424),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.14),
              width: 1.0,
            ),
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.tooltip.isEmpty) return btn;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: btn,
    );
  }
}

/// LIVE / Time Pill — self-contained, hugs content horizontally, uniform 40px height
class _LiveTimePill extends StatefulWidget {
  final PlayerController controller;
  const _LiveTimePill({required this.controller});

  @override
  State<_LiveTimePill> createState() => _LiveTimePillState();
}

class _LiveTimePillState extends State<_LiveTimePill> {
  bool _isHovered = false;

  String _fmt(Duration d) {
    final s = d.inSeconds;
    if (s < 0) return '0:00';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}'
        : '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLive = widget.controller.isLiveStream.value;
      final atEdge = widget.controller.isLiveEdge.value;
      final delay = widget.controller.liveDelayText.value;

      final Widget content;
      if (!isLive) {
        content = Text(
          '${_fmt(widget.controller.currentPosition.value)} / ${_fmt(widget.controller.totalDuration.value)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
            letterSpacing: 0.3,
          ),
        );
      } else {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: atEdge ? const Color(0xFFA839C7) : const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              atEdge ? 'LIVE' : (delay.isNotEmpty ? delay : '-0:10'),
              style: TextStyle(
                color: atEdge ? Colors.white : const Color(0xFFD4D4D4),
                fontSize: 12.5,
                fontWeight: atEdge ? FontWeight.w700 : FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: atEdge ? 0.6 : 0.2,
              ),
            ),
          ],
        );
      }

      final pill = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: isLive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: isLive ? widget.controller.goToLive : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _isHovered && isLive
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0x99242424),
              border: Border.all(
                color: _isHovered && isLive
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.14),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [content],
            ),
          ),
        ),
      );

      if (!isLive) return pill;
      return Tooltip(
        message: atEdge ? 'Playing Live' : 'Jump to Live ($delay)',
        waitDuration: const Duration(milliseconds: 300),
        child: pill,
      );
    });
  }
}

/// Right Capsule with Settings, PiP, Fullscreen — uniform 40px height
class _RightCapsule extends StatelessWidget {
  final PlayerController controller;
  const _RightCapsule({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x99242424),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Obx(() => _CapsuleIconBtn(
            icon: Icons.settings_rounded,
            size: 19,
            onTap: controller.toggleQualityMenu,
            tooltip: 'Settings / Quality',
            isActive: controller.showQualityMenu.value,
          )),
          const SizedBox(width: 4),
          _CapsuleIconBtn(
            icon: Icons.picture_in_picture_alt_rounded,
            size: 19,
            onTap: controller.minimizePlayer,
            tooltip: 'Miniplayer (Minimize)',
          ),
          const SizedBox(width: 4),
          Obx(() => _CapsuleIconBtn(
            icon: controller.isFullscreen.value
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            size: 22,
            onTap: controller.toggleFullscreen,
            tooltip: controller.isFullscreen.value
                ? 'Exit full screen (f)'
                : 'Full screen (f)',
          )),
        ],
      ),
    );
  }
}

/// Expandable Volume Pill (Uniform 40px Height, 40px Circle collapsed, expands on hover)
class _VolumePill extends StatefulWidget {
  final PlayerController controller;
  const _VolumePill({required this.controller});

  @override
  State<_VolumePill> createState() => _VolumePillState();
}

class _VolumePillState extends State<_VolumePill> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isExpanded = _isHovered || _isDragging;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 40,
        width: isExpanded ? 136 : 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isExpanded
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0x99242424),
          border: Border.all(
            color: isExpanded
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.14),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Volume / Mute Button (Exact 38x38 clickable area)
            SizedBox(
              width: 38,
              height: 38,
              child: Obx(() {
                final vol = widget.controller.volume.value;
                final muted = widget.controller.isMuted.value || vol == 0.0;
                final icon = muted
                    ? Icons.volume_off_rounded
                    : (vol < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded);

                return Tooltip(
                  message: muted ? 'Unmute (m)' : 'Mute (m)',
                  waitDuration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.controller.toggleMute,
                    child: Center(
                      child: Icon(icon, color: Colors.white, size: 21),
                    ),
                  ),
                );
              }),
            ),

            // Custom Smooth Volume Slider Bar (revealed on hover/drag)
            if (isExpanded)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 12),
                  child: Obx(() {
                    final vol = widget.controller.volume.value;
                    final muted = widget.controller.isMuted.value || vol == 0.0;
                    final currentVol = muted ? 0.0 : vol.clamp(0.0, 1.0);

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        const thumbSize = 12.0;

                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              final v = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
                              widget.controller.setVolume(v);
                            },
                            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
                            onHorizontalDragUpdate: (details) {
                              final v = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
                              widget.controller.setVolume(v);
                            },
                            onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
                            onHorizontalDragCancel: () => setState(() => _isDragging = false),
                            child: SizedBox(
                              height: 24,
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  // Inactive background track
                                  Container(
                                    width: barWidth,
                                    height: 4.5,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.32),
                                      borderRadius: BorderRadius.circular(2.5),
                                    ),
                                  ),

                                  // Active gradient track (Coral -> Electric Violet)
                                  Container(
                                    width: (barWidth * currentVol).clamp(0.0, barWidth),
                                    height: 4.5,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF7B60), Color(0xFFA839C7)],
                                      ),
                                      borderRadius: BorderRadius.circular(2.5),
                                    ),
                                  ),

                                  // Smooth Thumb Dot (Centered vertically on the track)
                                  Positioned(
                                    left: ((barWidth - thumbSize) * currentVol).clamp(0.0, barWidth - thumbSize),
                                    top: (24 - thumbSize) / 2,
                                    child: Container(
                                      width: thumbSize,
                                      height: thumbSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.50),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Action Button inside the Right Capsule Pill
/// Sized exactly 32x32 to maintain an even 4px padding on all sides inside the 40px capsule
class _CapsuleIconBtn extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final String tooltip;
  final bool isActive;

  const _CapsuleIconBtn({
    required this.icon,
    this.size = 19,
    required this.onTap,
    this.tooltip = '',
    this.isActive = false,
  });

  @override
  State<_CapsuleIconBtn> createState() => _CapsuleIconBtnState();
}

class _CapsuleIconBtnState extends State<_CapsuleIconBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isActive
                ? Colors.white.withValues(alpha: 0.28)
                : (_isHovered
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.transparent),
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.isActive || _isHovered
                ? Colors.white
                : Colors.white.withValues(alpha: 0.90),
          ),
        ),
      ),
    );

    if (widget.tooltip.isEmpty) return btn;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: btn,
    );
  }
}

/// YouTube Settings Popover Menu (Opened ABOVE the progress line, Clean & High Utility)
class _YouTubeSettingsMenu extends StatelessWidget {
  final PlayerController controller;

  const _YouTubeSettingsMenu({required this.controller});

  String _cleanLabel(QualityOption opt) {
    if (opt.id == 'auto' || opt.targetHeight == 0) return 'Auto';
    if (opt.targetHeight >= 2160) return '4K';
    if (opt.targetHeight > 0) return '${opt.targetHeight}p';
    if (opt.label.contains('1080')) return '1080p';
    if (opt.label.contains('720')) return '720p';
    if (opt.label.contains('540')) return '540p';
    if (opt.label.contains('480')) return '480p';
    if (opt.label.contains('360')) return '360p';
    if (opt.label == 'Auto (Recommended)') return 'Auto';
    return opt.label;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final subMenu = controller.settingsSubMenu.value;

      return Container(
        width: 270,
        decoration: BoxDecoration(
          color: const Color(0xF210121C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: subMenu == 'quality'
                    ? _buildQualitySubMenu()
                    : (subMenu == 'speed' ? _buildSpeedSubMenu() : _buildMainMenu()),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Main Settings Menu (Quality & Speed)
  Widget _buildMainMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Quality Row (Opens Submenu)
        Obx(() {
          var qVal = controller.selectedQuality.value;
          if (qVal == 'Auto (Recommended)') qVal = 'Auto';
          return _SettingsNavRow(
            icon: Icons.tune_rounded,
            title: 'Quality',
            valueText: qVal,
            onTap: () {
              controller.refreshQualityOptions();
              controller.settingsSubMenu.value = 'quality';
            },
          );
        }),

        const SizedBox(height: 2),

        // 2. Playback Speed Row
        Obx(() {
          final spd = controller.playbackSpeed.value;
          final label = spd == 1.0 ? 'Normal' : '${spd}x';
          return _SettingsNavRow(
            icon: Icons.speed_rounded,
            title: 'Playback speed',
            valueText: label,
            onTap: () => controller.settingsSubMenu.value = 'speed',
          );
        }),
      ],
    );
  }

  /// Quality Submenu
  Widget _buildQualitySubMenu() {
    final available = controller.availableQualityOptions;
    final options = available.isNotEmpty
        ? available.toList()
        : const [
            QualityOption(id: 'auto', label: 'Auto', badge: '', targetHeight: 0),
            QualityOption(id: '1080p', label: '1080p', badge: '', targetHeight: 1080),
            QualityOption(id: '720p', label: '720p', badge: '', targetHeight: 720),
            QualityOption(id: '540p', label: '540p', badge: '', targetHeight: 540),
            QualityOption(id: '360p', label: '360p', badge: '', targetHeight: 360),
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back Header
        _buildSubMenuHeader('Quality'),

        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
        const SizedBox(height: 4),

        // Resolutions List
        ...options.map((opt) {
          final isSelected = (opt.id == 'auto' && controller.selectedQualityOption.value.id == 'auto') ||
              (opt.targetHeight > 0 && opt.targetHeight == controller.selectedQualityOption.value.targetHeight) ||
              (opt.id == controller.selectedQualityOption.value.id) ||
              opt.isActive;

          return _SettingsOptionTile(
            title: _cleanLabel(opt),
            badge: opt.badge.isNotEmpty ? opt.badge : (opt.targetHeight >= 720 ? 'HD' : null),
            isSelected: isSelected,
            onTap: () => controller.changeQuality(opt),
          );
        }),
      ],
    );
  }

  /// Playback Speed Submenu
  Widget _buildSpeedSubMenu() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back Header
        _buildSubMenuHeader('Playback speed'),

        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
        const SizedBox(height: 4),

        ...speeds.map((spd) {
          final isSelected = controller.playbackSpeed.value == spd;
          final label = spd == 1.0 ? 'Normal' : '${spd}x';

          return _SettingsOptionTile(
            title: label,
            isSelected: isSelected,
            onTap: () {
              controller.setPlaybackSpeed(spd);
              controller.settingsSubMenu.value = '';
            },
          );
        }),
      ],
    );
  }

  Widget _buildSubMenuHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => controller.settingsSubMenu.value = '',
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
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

class _SettingsNavRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String valueText;
  final VoidCallback onTap;

  const _SettingsNavRow({
    required this.icon,
    required this.title,
    required this.valueText,
    required this.onTap,
  });

  @override
  State<_SettingsNavRow> createState() => _SettingsNavRowState();
}

class _SettingsNavRowState extends State<_SettingsNavRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: _isHovered ? Colors.white : Colors.white.withValues(alpha: 0.88),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isHovered ? Colors.white : Colors.white.withValues(alpha: 0.90),
                    fontSize: 13,
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.valueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isHovered ? Colors.white : Colors.white.withValues(alpha: 0.50),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _isHovered ? Colors.white : Colors.white.withValues(alpha: 0.40),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsOptionTile extends StatefulWidget {
  final String title;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _SettingsOptionTile({
    required this.title,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SettingsOptionTile> createState() => _SettingsOptionTileState();
}

class _SettingsOptionTileState extends State<_SettingsOptionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.22)
                : (_isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primaryLight.withValues(alpha: 0.40)
                  : (_isHovered ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Custom check indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.primaryLight
                        : (_isHovered
                            ? Colors.white.withValues(alpha: 0.50)
                            : Colors.white.withValues(alpha: 0.25)),
                    width: 1.5,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: highlighted ? Colors.white : Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),

              // Optional badge
              if (widget.badge != null && widget.badge!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.40),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
