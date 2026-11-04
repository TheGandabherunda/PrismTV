import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../data/models/channel_model.dart';

class ChannelCard extends StatefulWidget {
  final ChannelModel channel;
  final VoidCallback onTap;
  final ValueChanged<bool>? onFocusChange;
  final VoidCallback? onFavoriteToggle;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    this.onFocusChange,
    this.onFavoriteToggle,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        widget.onFocusChange?.call(focused);
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          widget.onFocusChange?.call(true);
        },
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: highlighted ? 1.05 : 1.0,
            duration: AppDimens.focusAnimationDuration,
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: AppDimens.focusAnimationDuration,
              decoration: BoxDecoration(
                color: highlighted ? AppColors.focusedBackground : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: highlighted ? AppColors.focusedBorder : AppColors.unfocusedCardBorder,
                  width: highlighted ? 2.0 : 1.0,
                ),
                boxShadow: highlighted
                    ? [
                        BoxShadow(
                          color: AppColors.focusedGlow,
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  children: [
                    // Subtle background highlight for logo contrast
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              highlighted ? const Color(0x26A855F7) : const Color(0x08FFFFFF),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Channel Logo Centerpiece
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                        child: widget.channel.logoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.channel.fullLogoUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, _) => _buildPlaceholder(highlighted),
                                errorWidget: (_, _, _) => _buildPlaceholder(highlighted),
                              )
                            : _buildPlaceholder(highlighted),
                      ),
                    ),

                    // Top Bar Badges (HD / Favorite)
                    Positioned(
                      top: 8,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.channel.isHd)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppColors.hdBadgeGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'HD',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          // Favorite Star Button
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onFavoriteToggle,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: widget.channel.isFavorite
                                    ? const Color(0x33FFB800)
                                    : (highlighted ? const Color(0x26FFFFFF) : Colors.transparent),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.channel.isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 16,
                                color: widget.channel.isFavorite
                                    ? AppColors.gold
                                    : (highlighted ? AppColors.textSecondary : Colors.transparent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Gradient & Name Bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: const BoxDecoration(
                          gradient: AppColors.cardOverlay,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.channel.channelName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
                                  color: highlighted ? Colors.white : const Color(0xFFF4F4F5),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.channel.languageName.length > 3
                                  ? widget.channel.languageName.substring(0, 3).toUpperCase()
                                  : widget.channel.languageName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: highlighted ? AppColors.primaryLight : AppColors.textMuted,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildPlaceholder(bool highlighted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.tv_rounded,
          size: 32,
          color: highlighted ? AppColors.primary : AppColors.textMuted,
        ),
        const SizedBox(height: 6),
        Text(
          widget.channel.channelName.isNotEmpty
              ? widget.channel.channelName
              : widget.channel.languageName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: highlighted ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
