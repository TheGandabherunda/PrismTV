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

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        widget.onFocusChange?.call(focused);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? AppDimens.focusScale : 1.0,
          duration: AppDimens.focusAnimationDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: AppDimens.focusAnimationDuration,
            width: AppDimens.channelCardWidth,
            height: AppDimens.channelCardHeight,
            decoration: BoxDecoration(
              color: _isFocused ? AppColors.focusedBackground : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(
                color: _isFocused ? AppColors.focusedBorder : AppColors.unfocusedBorder,
                width: _isFocused ? 2.5 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.focusedGlow,
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Channel Logo Centerpiece
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: widget.channel.logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.channel.fullLogoUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => _buildPlaceholder(),
                            errorWidget: (_, _, _) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),

                // Top Bar Badges (HD / Favorite)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.channel.isHd)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppColors.prismGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      if (widget.channel.isFavorite)
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.gold,
                        ),
                    ],
                  ),
                ),

                // Bottom Gradient & Name
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: AppColors.cardOverlay,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(AppDimens.radiusMedium),
                      ),
                    ),
                    child: Text(
                      widget.channel.channelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isFocused ? FontWeight.bold : FontWeight.w500,
                        color: _isFocused ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.tv_rounded,
          size: 32,
          color: _isFocused ? AppColors.primary : AppColors.textMuted,
        ),
        const SizedBox(height: 6),
        Text(
          widget.channel.languageName,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

